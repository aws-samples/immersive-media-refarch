# immersive-media-refarch
From encoder to spherical projection client, an end to end workflow for Live and on-demand immersive experiences.

# Quickstart

1. Download /templates/template.yaml 
2. Open CloudFormation Console, click _Create Stack_
3. Fill in parameters, keyName is required, click Next
4. Continue with CloudFormation prompts, launch the stack
5. In CloudFormation Outputs tab click the clientTestPatternURL link - you should see colorbars in 360-degrees

![Immersive reference architecture](immersive-detailed.png)

## Legal

During the launch of this reference architecture, you will install software (and dependencies) on the Amazon EC2 instances launched in your account via stack creation. The software packages and/or sources you will install will be from the Amazon Linux distribution, as well as from third party sites. Here is the list of third party software, the source link, and the license link for each software. Please review and decide your comfort with installing these before continuing.

### [MediaInfo](https://mediaarea.net/en/MediaInfo) via Extra Packages for Enterprise Linux [EPEL](https://fedoraproject.org/wiki/EPEL) 

Source: https://download.fedoraproject.org/ 

License: https://mediaarea.net/en/MediaInfo/License 

### [NGINX-RTMP-module](http://nginx-rtmp.blogspot.com) 

Source: https://github.com/arut/nginx-rtmp-module 

License: https://github.com/arut/nginx-rtmp-module/blob/master/LICENSE 

### [FFmpeg](https://ffmpeg.org/) 

Source: https://ffmpeg.org/download.html 

License: https://github.com/FFmpeg/FFmpeg/blob/master/LICENSE.md 

### [FFmpeg Static Builds](https://www.johnvansickle.com/ffmpeg/ ) 

Source: http://johnvansickle.com/ffmpeg/ 

License: http://www.gnu.org/licenses/gpl-3.0.en.html