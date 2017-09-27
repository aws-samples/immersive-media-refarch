#!/bin/bash

ENCODINGQUEUE=https://sqs.us-west-2.amazonaws.com/753949184587/heckyeah
#ENCODINGINGRESSBUCKET=%ENCODINGINGRESSBUCKET%
#ENCODINGEGRESSBUCKET=%ENCODINGEGRESSBUCKET%
#NUMPROCS=$(nproc)

JSON=$(aws --region us-west-2 sqs --output=json get-queue-attributes \
  --queue-url $ENCODINGQUEUE \
  --attribute-names ApproximateNumberOfMessages)
MESSAGES=$(echo "$JSON" | jq -r '.Attributes.ApproximateNumberOfMessages')
if [ $MESSAGES -eq 0 ]; then
  echo empty
else
  echo "Messages: $MESSAGES"
fi