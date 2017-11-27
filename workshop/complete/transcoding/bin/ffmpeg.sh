#!/bin/bash

ENCODINGQUEUE=%ENCODINGQUEUE%
ENCODINGINGRESSBUCKET=%ENCODINGINGRESSBUCKET%
ENCODINGEGRESSBUCKET=%ENCODINGEGRESSBUCKET%
NUMPROCS=$(nproc)

JSON=$(aws sqs --output=json get-queue-attributes \
  --queue-url $ENCODINGQUEUE \
  --attribute-names ApproximateNumberOfMessages)
MESSAGES=$(echo "$JSON" | jq -r '.Attributes.ApproximateNumberOfMessages')
if [ $MESSAGES -eq 0 ]; then
  exit
else
  echo "Messages: $MESSAGES"
fi

JSON=$(aws sqs --region=$REGION --output=json receive-message --queue-url $QUEUE)
RECEIPT=$(echo "$JSON" | jq -r '.Messages[] | .ReceiptHandle')
BODY=$(echo "$JSON" | jq -r '.Messages[] | .Body')
INPUT=$(echo "$BODY" | jq -r '.Records[0] | .s3.object.key')

FNAME=$(echo $INPUT | rev | cut -f2 -d"." | rev | tr '[:upper:]' '[:lower:]')
FEXT=$(echo $INPUT | rev | cut -f1 -d"." | rev | tr '[:upper:]' '[:lower:]')

if [ "$FEXT" == "mp4" ]; then
  mkdir /tmp/${FNAME}
  cd /tmp/${FNAME}
  aws s3 cp s3://ENCODINGINGRESSBUCKET/$INPUT .
  
  /usr/local/bin/ffmpeg -y -async 1 -vsync -1 -analyzeduration 999999999 -i ${INPUT} -threads $NUMPROCS \
  -movflags faststart -keyint_min 30 -x264opts "keyint=30:min-keyint=30:no-scenecut" -g 30 -filter:v "scale=iw*min(320/iw\,180/ih):ih*min(320/iw\,180/ih), pad=320:180:(320-iw*min(320/iw\,180/ih))/2:(180-ih*min(320/iw\,180/ih))/2" -r:v 30 -s 320x180 -b:v 110k -c:v libx264 -pix_fmt yuv420p -profile:v baseline -level 3.0 -c:a aac -ac 2 -ar 48000 -b:a 64k ${FNAME}-180.MP4 \
  -movflags faststart -keyint_min 30 -x264opts "keyint=30:min-keyint=30:no-scenecut" -g 30 -filter:v "scale=iw*min(426/iw\,240/ih):ih*min(426/iw\,240/ih), pad=426:240:(426-iw*min(426/iw\,240/ih))/2:(240-ih*min(426/iw\,240/ih))/2" -r:v 30 -s 426x240 -b:v 250k -c:v libx264 -pix_fmt yuv420p -profile:v baseline -level 3.0 -c:a aac -ac 2 -ar 48000 -b:a 64k ${FNAME}-240.MP4 \
  -movflags faststart -keyint_min 30 -x264opts "keyint=30:min-keyint=30:no-scenecut" -g 30 -filter:v "scale=iw*min(640/iw\,360/ih):ih*min(640/iw\,360/ih), pad=640:360:(640-iw*min(640/iw\,360/ih))/2:(360-ih*min(640/iw\,360/ih))/2" -r:v 30 -s 640x360 -b:v 500k -c:v libx264 -pix_fmt yuv420p -profile:v baseline -level 3.0 -c:a aac -ac 2 -ar 48000 -b:a 96k ${FNAME}-360.MP4 \
  -movflags faststart -keyint_min 30 -x264opts "keyint=30:min-keyint=30:no-scenecut" -g 30 -filter:v "scale=iw*min(854/iw\,480/ih):ih*min(854/iw\,480/ih), pad=854:480:(854-iw*min(854/iw\,480/ih))/2:(480-ih*min(854/iw\,854/ih))/2" -r:v 30 -s 854x480 -b:v 1080k -c:v libx264 -pix_fmt yuv420p -profile:v baseline -level 3.0 -c:a aac -ac 2 -ar 48000 -b:a 96k ${FNAME}-480.MP4 \
  -movflags faststart -keyint_min 30 -x264opts "keyint=30:min-keyint=30:no-scenecut" -g 30 -filter:v "scale=iw*min(1280/iw\,720/ih):ih*min(1280/iw\,720/ih), pad=1280:720:(1280-iw*min(1280/iw\,720/ih))/2:(720-ih*min(1280/iw\,720/ih))/2" -r:v 30 -s 1280x720 -b:v 2136k -c:v libx264 -pix_fmt yuv420p -profile:v baseline -level 3.1 -c:a aac -ac 2 -ar 48000 -b:a 128k ${FNAME}-720.MP4 \
  -c:a aac -ac 2 -ar 48000 -b:a 64k ${FNAME}-AAC.AAC

  /usr/local/bin/ffmpeg -y -async 1 -vsync -1 -analyzeduration 999999999 -i ${FNAME}-180.MP4 -codec copy -map 0 -f segment -segment_list ${FNAME}-180.M3U8 -segment_time 10 -segment_list_type m3u8 -bsf:v h264_mp4toannexb ${FNAME}-180-%05d.TS
  /usr/local/bin/ffmpeg -y -async 1 -vsync -1 -analyzeduration 999999999 -i ${FNAME}-240.MP4 -codec copy -map 0 -f segment -segment_list ${FNAME}-240.M3U8 -segment_time 10 -segment_list_type m3u8 -bsf:v h264_mp4toannexb ${FNAME}-240-%05d.TS
  /usr/local/bin/ffmpeg -y -async 1 -vsync -1 -analyzeduration 999999999 -i ${FNAME}-360.MP4 -codec copy -map 0 -f segment -segment_list ${FNAME}-360.M3U8 -segment_time 10 -segment_list_type m3u8 -bsf:v h264_mp4toannexb ${FNAME}-360-%05d.TS
  /usr/local/bin/ffmpeg -y -async 1 -vsync -1 -analyzeduration 999999999 -i ${FNAME}-480.MP4 -codec copy -map 0 -f segment -segment_list ${FNAME}-480.M3U8 -segment_time 10 -segment_list_type m3u8 -bsf:v h264_mp4toannexb ${FNAME}-480-%05d.TS
  /usr/local/bin/ffmpeg -y -async 1 -vsync -1 -analyzeduration 999999999 -i ${FNAME}-720.MP4 -codec copy -map 0 -f segment -segment_list ${FNAME}-720.M3U8 -segment_time 10 -segment_list_type m3u8 -bsf:v h264_mp4toannexb ${FNAME}-720-%05d.TS
  /usr/local/bin/ffmpeg -y -async 1 -vsync -1 -analyzeduration 999999999 -i ${FNAME}-AAC.AAC -codec copy -map 0 -f segment -segment_list ${FNAME}-AAC.M3U8 -segment_time 10 -segment_list_type m3u8 -bsf:v h264_mp4toannexb ${FNAME}-AAC-%05d.TS

  cat <<EOT >> MANIFEST.M3U8
#EXTM3U
#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=192000,RESOLUTION=320x180
$FNAME-180.M3U8
#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=320000,RESOLUTION=426x240
$FNAME-240.M3U8
#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=600000,RESOLUTION=640x360
$FNAME-360.M3U8
#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=1200000,RESOLUTION=854x480
$FNAME-480.M3U8
#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=2200000,RESOLUTION=1280x720
$FNAME-720.M3U8
#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=6400
$FNAME-AAC.M3U8 
EOT

  OUTPUT=$(echo $INPUT | rev | cut -f 2- -d '.' | rev)
  aws s3 cp --recursive /tmp/$FNAME s3://$ENCODINGEGRESSBUCKET/$FNAME
fi

if [ ! "$RECEIPT" == "" ]; then
  JSON=$(aws sqs --output=json delete-message --queue-url $ENCODINGQUEUE \
  --receipt-handle $RECEIPT)
fi
