#!/bin/bash

# AWS LiveVR - Record Postprocess
# - Post-Process Recordings and move to S3
# - called by NGINX recorder on_complete event
# - receives path basename as arguments
# - e.g. /var/lib/nginx/rec/stream.flv stream

# Shut down gracefully
on_die ()
{
  pkill -KILL -P $$
}
trap 'on_die' TERM

# Redirect all output for CW Logs
exec 1> >(logger -s -t $(basename $0)) 2>&1

# Variables
INPUTFILE="$1"
S3BUCKET="%INGRESSBUCKET%/input"
S3FOLDER="/var/lib/nginx/s3"
TIMESTAMP="`date +%s`"
DESTFILE="$2-$TIMESTAMP.mp4"

# Transcode
mkdir -p $S3FOLDER
/usr/local/bin/ffmpeg -i $INPUTFILE -codec copy $S3FOLDER/$DESTFILE

# Upload to S3 - and make sure owner has access to the file!
aws s3 cp $S3FOLDER/$DESTFILE s3://$S3BUCKET/$DESTFILE --acl bucket-owner-full-control

# clean up
rm -rf $S3FOLDER/$DESTFILE
