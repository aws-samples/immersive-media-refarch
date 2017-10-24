#!/bin/bash

INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)

yum -y --security update

yum -y update aws-cli

yum -y install \
  awslogs jq htop pcre-devel zlib-devel \
  openssl-devel gcc gcc-c++ make libaio \
  libaio-devel openssl libxslt-devel rpm-build \
  gperftools-devel GeoIP-devel gd-devel perl-devel perl-ExtUtils-Embed

yum -y --enablerepo=epel install mediainfo

aws configure set default.region $REGION

aws ec2 attach-network-interface --network-interface-id $ENI_ID --instance-id $INSTANCE_ID --device-index 1

cd /tmp && \
  curl -kO https://www.johnvansickle.com/ffmpeg/builds/ffmpeg-git-64bit-static.tar.xz && \
  tar Jxf ffmpeg-git-64bit-static.tar.xz && \
  cp -av ffmpeg*/{ff*,qt*} /usr/local/bin

cd /tmp && \
  git clone https://github.com/arut/nginx-rtmp-module

yum -y install \
  nginx && \
  yes | get_reference_source -p nginx && \
  yum -y remove nginx && \
  rpm -Uvh /usr/src/srpm/debug/nginx*.rpm

sed -i "s|configure|configure --add-module=/tmp/nginx-rtmp-module|" /rpmbuild/SPECS/nginx.spec

rpmbuild -ba /rpmbuild/SPECS/nginx.spec

rpm -Uvh /rpmbuild/RPMS/x86_64/nginx*.rpm

cp -av /tmp/nginx-rtmp-module/stat.xsl /usr/share/nginx/html

mkdir /etc/nginx/rtmp.d

mkdir -p /var/lib/nginx/{rec,hls,s3}

chown -R nginx. /var/lib/nginx/

echo '$SystemLogRateLimitInterval 2' >> /etc/rsyslog.conf
echo '$SystemLogRateLimitBurst 500' >> /etc/rsyslog.conf

echo "include /etc/nginx/rtmp.d/*.conf;" >> /etc/nginx/nginx.conf

sed -i "s|worker_processes auto|worker_processes 1|g" /etc/nginx/nginx.conf

cp -av /root/immersive-media-refarch/workshop/complete/origin/nginx/default.d/rtmp.conf /etc/nginx/default.d/
cp -av /root/immersive-media-refarch/workshop/complete/origin/nginx/rtmp.d/rtmp.conf /etc/nginx/rtmp.d/
cp -av /root/immersive-media-refarch/workshop/complete/origin/awslogs/awslogs.conf /etc/awslogs/
cp -av /root/immersive-media-refarch/workshop/complete/origin/bin/record-postprocess.sh /usr/local/bin/
cp -av /root/immersive-media-refarch/workshop/complete/origin/init/spot-instance-termination-notice-handler.conf /etc/init/spot-instance-termination-notice-handler.conf
cp -av /root/immersive-media-refarch/workshop/complete/origin/bin/spot-instance-termination-notice-handler.sh /usr/local/bin/

chmod +x /usr/local/bin/spot-instance-termination-notice-handler.sh

sed -i "s|%INGRESSBUCKET%|$INGRESSBUCKET|g" /usr/local/bin/record-postprocess.sh
chmod +x /usr/local/bin/record-postprocess.sh

sed -i "s|us-east-1|$REGION|g" /etc/awslogs/awscli.conf
sed -i "s|%CLOUDWATCHLOGSGROUP%|$CLOUDWATCHLOGSGROUP|g" /etc/awslogs/awslogs.conf

chkconfig rsyslog on && service rsyslog restart
chkconfig awslogs on && service awslogs restart
chkconfig nginx on && service nginx restart

start spot-instance-termination-notice-handler

aws ec2 associate-address --allow-reassociation \
  --allocation-id $ALLOCATION_ID --network-interface-id $ENI_ID

/opt/aws/bin/cfn-signal -s true -i $INSTANCE_ID "$WAITCONDITIONHANDLE"
