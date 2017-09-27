#!/bin/bash

while sleep 5; do
  if [ -z $(curl -Isf http://169.254.169.254/latest/meta-data/spot/termination-time) ];
  then
    /bin/false
  else
    logger "[spot-instance-termination-notice-handler.sh]: spot instance termination notice detected"
    logger "[spot-instance-termination-notice-handler.sh]: putting myself to sleep..."
    sleep 120
  fi
done
