#!/bin/bash

INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

yum -y --security update

yum -y update aws-cli

yum -y install \
  java-1.8.0

yum -y remove \
  java-1.7.0-openjdk

cd /tmp && \
  curl -O http://apache.mirrors.lucidnetworks.net//jmeter/binaries/apache-jmeter-3.3.tgz && \
  tar xzf apache-jmeter-3.3.tgz && \
  cp -r apache-jmeter-3.3/ /usr/local/bin/ && \
  echo PATH=$PATH:/usr/local/bin/apache-jmeter-3.3/bin/ >> /home/ec2-user/.bashrc
  echo JVM_ARGS="-Xms3072m -Xmx3072m" >> /home/ec2-user/.bashrc

yum install -y \
  httpd24

chkconfig httpd on && service httpd restart

cp /root/immersive-media-refarch/workshop/lab.jmx /home/ec2-user/

groupadd www
usermod -a -G www ec2-user
mkdir -p /var/www/html/results/
chown -R root:www /var/www
chmod 2775 /var/www
find /var/www -type d -exec chmod 2775 {} +
find /var/www -type f -exec chmod 0664 {} +

aws configure set default.region $REGION


cp -av /root/immersive-media-refarch/workshop/start/transcoding/init/spot-instance-termination-notice-handler.conf /etc/init/spot-instance-termination-notice-handler.conf
cp -av /root/immersive-media-refarch/workshop/start/transcoding/bin/spot-instance-termination-notice-handler.sh /usr/local/bin/

chmod +x /usr/local/bin/spot-instance-termination-notice-handler.sh

start spot-instance-termination-notice-handler

/opt/aws/bin/cfn-signal -s true -i $INSTANCE_ID "$WAITCONDITIONHANDLE"
