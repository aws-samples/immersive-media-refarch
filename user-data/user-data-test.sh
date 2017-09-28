#!/bin/bash

INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)

yum -y --security update

yum -y update aws-cli

yum -y install aws-cfn-bootstrap

aws configure set default.region $REGION

echo ECS_CLUSTER=$ECS_CLUSTER >> /etc/ecs/ecs.config

cp -av /root/immersive-media-refarch/user-data/test/init/spot-instance-termination-notice-handler.conf /etc/init/spot-instance-termination-notice-handler.conf
cp -av /root/immersive-media-refarch/user-data/test/bin/spot-instance-termination-notice-handler.sh /usr/local/bin/

chmod +x /usr/local/bin/spot-instance-termination-notice-handler.sh

sed -i "s|us-east-1|$REGION|g" /etc/awslogs/awscli.conf

start spot-instance-termination-notice-handler

/opt/aws/bin/cfn-signal -s true -i $INSTANCE_ID "$WAITCONDITIONHANDLE"
