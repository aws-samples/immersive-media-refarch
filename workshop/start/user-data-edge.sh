#!/bin/bash

INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

yum -y --security update

yum -y update aws-cli

yum -y install \
  awslogs jq htop nginx

aws configure set default.region $REGION

echo '$SystemLogRateLimitInterval 2' >> /etc/rsyslog.conf
echo '$SystemLogRateLimitBurst 500' >> /etc/rsyslog.conf

cp -av /root/immersive-media-refarch/workshop/start/edge/nginx/nginx.conf /etc/nginx/
cp -av /root/immersive-media-refarch/workshop/start/edge/awslogs/awslogs.conf /etc/awslogs/
cp -av /root/immersive-media-refarch/workshop/start/edge/init/spot-instance-termination-notice-handler.conf /etc/init/spot-instance-termination-notice-handler.conf
cp -av /root/immersive-media-refarch/workshop/start/edge/bin/spot-instance-termination-notice-handler.sh /usr/local/bin/

chmod +x /usr/local/bin/spot-instance-termination-notice-handler.sh

sed -i "s|%APPLICATIONLOADBALANCERTARGETGROUP%|$APPLICATIONLOADBALANCERTARGETGROUP|g" /usr/local/bin/spot-instance-termination-notice-handler.sh

sed -i "s|us-east-1|$REGION|g" /etc/awslogs/awscli.conf
sed -i "s|%CLOUDWATCHLOGSGROUP%|$CLOUDWATCHLOGSGROUP|g" /etc/awslogs/awslogs.conf

sed -i "s|%EGRESSBUCKETWEBSITEURL%|$EGRESSBUCKETWEBSITEURL|g" /etc/nginx/nginx.conf
sed -i "s|%PRIMARYORIGINPRIVATEIP%|$PRIMARYORIGINPRIVATEIP|g" /etc/nginx/nginx.conf

chkconfig rsyslog on && service rsyslog restart
chkconfig awslogs on && service awslogs restart
chkconfig nginx on && service nginx restart

start spot-instance-termination-notice-handler

aws elbv2 register-targets \
	--target-group-arn $APPLICATIONLOADBALANCERTARGETGROUP \
    --targets Id=$INSTANCE_ID

/opt/aws/bin/cfn-signal -s true -i $INSTANCE_ID "$WAITCONDITIONHANDLE"
