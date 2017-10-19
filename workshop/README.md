# W.I.P 360-degree live streaming on AWS

## Overview

360-degree video allows content creators to capture and deliver a unique experience to end-users. Social Media sites have implemented 360-degree videos into their sites, making the technology simple to access, but what of those who attempt to build our own unique experiences? Where do they begin?

Live streaming, a commodotized consumer product spanning far outside the realm of Social Media, still poses unique implementation challenges for those who hope to adopt it. What happens in real-time will never happen again, therefore, any issue could bring heartache to viewers.

The goal, with this workshop, is to combine these two technologies into a single solution. Demystifying live streaming, while combining the unique experience of immersive video.

## Requirements

* AWS account - if you don't have one, it's easy and free to create one
* AWS IAM account with elevated privileges allowing you to interact with CloudFormation, IAM, EC2, ECS, S3, Cloudwatch, and Cloudfront
* A workstation or laptop with an ssh client installed, such as putty on Windows or terminal or iterm on Mac
* Familiarity with Bash, ffmpeg, nginx, and video processing

## Labs

The labs in this directory are designed to be completed in sequential order. If you're attending an AWS event, your host will give you an overview of the technology and expectations for each lab. If you're following along at home, we've provided the presentation materials as a pdf. Feel free to open issue tickets on the repo if you have questions or issues.

_Lab 1_

## Conventions

## Cleanup and Disclaimer


## Challenge

Imagine that you couldn't attend this re:invent workshop in-person, but you'd like to virtually attend in real-time. While we, the organizers, could stream this session in regular old fixed view with a narrow field-of-vision, a more immersive experience would be an ideal way to engage our remote participants. Your challenge, should you choose to accept it, is to build such a system by following these labs.


## Live Streaming Basics

## 360 Video Basics

## Contribution Source & Test Source

In the real-world, live content will be captured via a local camera (webcam, mobile, security, omnidirectional), compressed, and sent to the cloud for further processing and distribution. Effective contribution of these source feeds requires consideration of the data rate and network charactaristics.  For example, a user streaming live *from* their cellphone could experience first-mile challenges that would impact all further systems. If our end-user understands that device connectivity is at fault, it's no big deal. On the other hand, if we've been contracted out to stream live the Olympics in 360-degres and we expect millions of viewers for a big event, it would be wise to consider how data flows from the venue to our cloud infrastructure. Here are some basic considerations for your source contribution, wherever that may be...

- Will the venue have dedicated bandwidth or public internet?
- What's the data rate that we expect to be necessary to produce a good experience?
- Do we have the ability to provide multiple streams from the event to our infrastructure for redundancy? (doubling bandwidth requirements)
- Are there any latency considerations/expectations?
- Which protocol works best?

To ensure that these factors don't hinder our ability to proceed with the workshop, we'll use a test source generator to produce a test pattern. This will allow us to test our infrastructure with a live source local to the region/AZ in which it is deployed, bypassing any first-mile connectivity issues for testing purposes. We will use this for the majority of the lab, but don't forget to connect your own devices if bandwidth is available. Many mobile cameras can stream live over wifi or cellular, but be cautioned, we _ARE NOT_ liable for your cell phone data charges.

{Details on how to setup test source..}
{break down ffmpeg command}

## Lab 1 - Simple Streaming Service

In this lab we will build a simple live streaming system using open source software. From this base system we will be able to view a 360-degree live stream coming from a camera, but more importantly, it will serve as a basis to build in best-practices and introduce new features later on  during this workshop.

Encoder -> Origin <-> Client


1. Deploy Lab 1 cfn template
2. ssh into origin and start ffmpeg test source - Because on-site internet bandwidth can be a challenge, the first thing we want to do is set up a reliable test source
3. check /stats page on origin
4. Use test client to play back the stream


## Lab 2 - CDN and Caching

With our live stream functional, we now focus on scalability. Our origin can easily handle a few simultanious users, but what about hundreds, thousands, or millions? Introducing a Content Delivery Network (CDN) can help us improve performance for end users while lowering the overall load on our origins.

Serving every HTTP request from millions of users would require a significant am

 Encoder -> Origin <-> CDN <-> Client

1. Create a new Cloudfront distribution
2. Configure our origin
3. Use test client to play back the stream, now with Cloudfront URL


## Lab 3 - Video on Demand

What about participants who aren't able to attend during the scheduled workshop hours? How can we provide them with a Video-on-Demand rendition of the content that allows anyone to attend?

Thankfully, nginx-rtmp supports a directive that will allow us to record, just like a VCR. We'll use this to capture the source and then transcode with a fleet of transcoders specifically tuned for VOD. To drive an autoscaling group for our transcode fleet, we'll employ the help of Simple Queue Service to implement a job.


Encoder -> Origin <-> CDN <-> Client
              |                 
              |                     
              V                      
              S3 -> SQS -> Transcode -> S3


1. deploy lab3 cfn template that creates S3 buckets, SQS Queue, and transcoding fleet
2. add record directive to nginx and enable script to copy files to the newly created s3 bucket. Restart nginx
3. Stop our test source
4. Confirm transcode progress
5. Test VOD playback


## Extra Credit

* Use your own camera and RTMP capable encoder to contribute a source to the origin (beware bandwidth requirements)
* Decrease overall live latency by tuning the segment sizes
* Implement cubemap filter in VOD processing fleet to compare against live spherical projection
* Use spot fleet for VOD processing fleet
