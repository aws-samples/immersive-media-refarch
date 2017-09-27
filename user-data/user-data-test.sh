#!/bin/bash

INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)

yum -y --security update

yum -y update aws-cli

yum -y install aws-cfn-bootstrap

aws configure set default.region $REGION
sed -i "s/us-east-1/$REGION/" "/etc/awslogs/awscli.conf"

echo ECS_CLUSTER=$ECS_CLUSTER >> /etc/ecs/ecs.config

/opt/aws/bin/cfn-signal -s true -i $INSTANCE_ID "$WAITCONDITIONHANDLE"
