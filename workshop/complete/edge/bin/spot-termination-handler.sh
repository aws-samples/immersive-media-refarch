#!/bin/bash

while sleep 3; do
  if [ -z $(curl -Isf http://169.254.169.254/latest/meta-data/spot/termination-time) ]; then
  	logger "[spot-termination-handler.sh]: spot instance termination notice not detected"
    /bin/false
  else
  	logger "[spot-termination-handler.sh]: spot instance termination notice activated"
  	INSTANCEID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
  	logger "[spot-termination-handler.sh]: detaching from elbv2"
  	aws elbv2 deregister-targets \
		--target-group-arn %APPLICATIONLOADBALANCERTARGETGROUP% \
    	--targets Id=$INSTANCEID
    logger "[spot-termination-handler.sh]: stopping nginx"
    service nginx stop
    logger "[spot-termination-handler.sh]: putting myself to sleep..."
    sleep 120
  fi
done