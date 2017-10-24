# W.I.P 360-degree live streaming on AWS

## Overview

360-degree video allows content creators to capture and deliver unique experiences. Social Media sites have implemented 360-degree videos into their sites, making the technology simple to access, but what of those who attempt to build our own unique experiences? Where do they begin? Additionally, live streaming, a commodotized consumer product spanning far outside the realm of Social Media, still poses unique implementation challenges. Afterall, what happens in real-time will never again occur, therefore, any issue could bring heartache to viewers.

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


## Lab 0 - Setup

1\. First, you'll need to select a [region](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html). For this lab, you will need to choose either **Ohio** or **Oregon**. At the top right hand corner of the AWS Console, you'll see a **Support** dropdown. To the left of that is the region selection dropdown.

2\. Then you'll need to create an SSH key pair which will be used to login to the instances once provisioned.  Go to the EC2 Dashboard and click on **Key Pairs** in the left menu under Network & Security.  Click **Create Key Pair**, provide a name (can be anything, make it something memorable) when prompted, and click **Create**.  Once created, the private key in the form of .pem file will be automatically downloaded.  

If you're using linux or mac, change the permissions of the .pem file to be less open.  

<pre>$ chmod 400 <b><i>PRIVATE_KEY.PEM</i></b></pre>

If you're on windows you'll need to convert the .pem file to .ppk to work with putty.  Here is a link to instructions for the file conversion - [Connecting to Your Linux Instance from Windows Using PuTTY](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/putty.html)

3\. For your convenience, we provide a CloudFormation template to stand up the core infrastructure.  

*Prior to launching a stack, be aware that a few of the resources launched need to be manually deleted when the workshop is over. When finished working, please review the "Workshop Cleanup" section to learn what manual teardown is required by you.*

Click on one of these CloudFormation templates that matches the region you created your keypair in to launch your stack:  

Region | Launch Template
------------ | -------------  
**Ohio** (us-east-2) | [![Launch ECS Deep Learning Stack into Ohio with CloudFormation](/images/deploy-to-aws.png)](https://console.aws.amazon.com/cloudformation/home?region=us-east-2#/stacks/new?stackName=ecs-deep-learning-stack&templateURL=https://s3.amazonaws.com/ecs-dl-workshop-us-east-2/ecs-deep-learning-workshop.yaml)  
**Oregon** (us-west-2) | [![Launch ECS Deep Learning Stack into Oregon with CloudFormation](/images/deploy-to-aws.png)](https://console.aws.amazon.com/cloudformation/home?region=us-west-2#/stacks/new?stackName=ecs-deep-learning-stack&templateURL=https://s3.amazonaws.com/ecs-dl-workshop-us-west-2/ecs-deep-learning-workshop.yaml)  

The template will automatically bring you to the CloudFormation Dashboard and start the stack creation process in the specified region. Click "Next" on the page it brings you to. Do not change anything on the first screen.
![CloudFormation PARAMETERS](/images/cf-initial.png)

The template sets up a VPC, IAM roles, S3 bucket, ECR container registry and an ECS cluster which is comprised of one EC2 Instance with the Docker daemon running.  The idea is to provide a contained environment, so as not to interfere with any other provisioned resources in your account.  In order to demonstrate cost optimization strategies, the EC2 Instance is an [EC2 Spot Instance](https://aws.amazon.com/ec2/spot/) deployed by [Spot Fleet](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-fleet.html).  If you are new to [CloudFormation](https://aws.amazon.com/cloudformation/), take the opportunity to review the [template](https://github.com/awslabs/ecs-deep-learning-workshop/blob/master/lab-1-setup/cfn-templates/ecs-deep-learning-workshop.yaml) during stack creation.

**IMPORTANT**  
*On the parameter selection page of launching your CloudFormation stack, make sure to choose the key pair that you created in step 1. If you don't see a key pair to select, check your region and try again.*
![CloudFormation PARAMETERS](/images/cf-params.png)

**Create the stack**  
After you've selected your ssh key pair, click **Next**. On the **Options** page, accept all defaults- you don't need to make any changes. Click **Next**. On the **Review** page, under **Capabilities** check the box next to **"I acknowledge that AWS CloudFormation might create IAM resources."** and click **Create**. Your CloudFormation stack is now being created.

**Checkpoint**  
Periodically check on the stack creation process in the CloudFormation Dashboard.  Your stack should show status **CREATE\_COMPLETE** in roughly 5-10 minutes.  In the Outputs tab, take note of the **ecrRepository** and **spotFleetName** values; you will need these in the next lab.     

![CloudFormation CREATION\_COMPLETE](/images/cf-complete.png)

Note that when your stack moves to a **CREATE\_COMPLETE** status, you won't necessarily see EC2 instances yet. If you don't, go to the EC2 console and click on **Spot Requests**. There you will see the pending or fulfilled spot requests. Once they are fulfilled, you will see your EC2 instances within the EC2 console.

If there was an error during the stack creation process, CloudFormation will rollback and terminate.  You can investigate and troubleshoot by looking in the Events tab.  Any errors encountered during stack creation will appear in the event log. 

## Lab 1 - Simple Streaming Service

In this lab, you will actually stream content to the origin and confirm that it plays back with a test client, but first, a word on live source contribution.

In the real-world, content is captured in real-time via a local camera (webcam, mobile, security, omnidirectional), compressed, and sent to the cloud for further processing and distribution. Streaming from a remote production location to distribution infrastructure is called *Contribution* and it requires careful consideration of the data rate and network charactaristics.

- Will the venue have dedicated bandwidth or only public internet connectivity?
- What data rate produces a quality experience?
- Do you need redundant contribution streams over multiple paths, doubling bandwidth requirements?
- Do users have latency expectations?
- Which protocol is most appropriate? HLS/RTMP/RTP?

To ensure that these factors don't hinder our ability to proceed with the workshop, we'll use a test source played out in real-time. This will allow us to test our infrastructure with a live source local to the region/AZ in which it is deployed, bypassing any first-mile connectivity challenges. We will use this for the majority of the lab, but don't forget to connect your own devices if bandwidth is available. Many mobile cameras can stream live over wifi or cellular, but be cautioned, we _ARE NOT_ liable for your cell phone data charges.

Encoder -> Origin <-> Client

1\. From the Cloudformation console, select the stack you created, and then Outputs. Find the 'primaryOriginElasticIp' key and note the value of x.x.x.x. This is the IP address of our media origin. SSH into this instance with the following command:

<pre>$ ssh -i <b><i>PRIVATE_KEY.PEM</i><b> ec2-user@<b><i>primaryOriginElasticIp</b></i></pre>

2\. Next, you'll start ffmpeg to simulate a real-time source. Run the following command, which uses the lavfi virtual device input for ffmpeg in conjuntion with libavfilter to generate a test pattern.

```bash
ffmpeg -stats -re -f lavfi -i aevalsrc="sin(400*2*PI*t)" -f lavfi -i testsrc=size=1280x720:rate=30 -vcodec libx264 -b:v 500k -c:a aac -b:a 160k -vf "format=yuv420p" -f flv 'rtmp://localhost/live/test'
```

3\. Once the test stream is initiated, change to the root user and inspect the /var/lib/nginx/live directory. New segments will be generated and old segments will be deleted by the nginx-rtmp module. Confirm that this is the case by listing the directory contents periodically or watching the manifest file.


4\. Now for the exciting part, playing the stream on a client. Within the CloudFormation console, find the Output listed as clientWebsiteUrl. Copy or open in a new tab, but don't browse there quite yet, you'll need to provide a query parameter to the relevant stream source. To request the stream directly from the origin you're URL will need to include the primaryOriginElasticIp.

<pre>http://YOUR_TRANSCODINGEGRESS_BUCKET.s3-website-REGION.amazonaws.com/?url=primaryOriginElasticIp/hls/test.m3u8</pre>

You should now see and hear colorbars and tone from the system. Success!


## Lab 2 - Video on Demand

What about participants who aren't able to attend during the scheduled workshop hours? How can you provide them with a Video-on-Demand rendition of the content that allows anyone to attend? Additionally, if we want to create multiple renditions or apply post-processing, we'll need instances to handle the VOD processing for our service.

Thankfully, the nginx-rtmp record directive that works much like a home VCR. Use this to capture the source and transcode it with a fleet specifically tuned for ABR VOD. As a best practice, use Simple Queue Service (SQS) to decouple the Transcode requests from the Transcode worker fleet. Then, use cloudwatch metrics and autoscaling to dynamically scale the transcode workers if we have many simultanious recordings transcoding.


Encoder -> Origin <-> CDN <-> Client
              |                 
              |                     
              V                      
              S3 -> SQS -> Transcode -> S3


1\. Update or create a new stack with the following template. This will create the S3 Bucket, SQS Queue, and Transcode fleet. 

2\. Next, we need to modify the nginx-rtmp application to include the record directive. With this configuration the application will record all audio/video streams to /var/lib/nginx/rec, roll over the file when the filesize reaches 128M, and, when new recordings are complete, execute a helper script which we'll configure next.

```
      record all;
      record_path /var/lib/nginx/rec;
      record_max_size 128000K;
      exec_record_done /usr/local/bin/record-postprocess.sh $path $basename;
```


1. deploy lab2 cfn template creating the S3 buckets, SQS Queue, and transcoding fleet
2. add record directive to nginx and enable script to copy files to the newly created s3 bucket. Restart nginx
3. open sqs console, poll for messages
3. Stop our test source
4. see message from exec script in queue
5. Confirm transcode progress (CPU in CW metrics?)
6. Test VOD playback with test client

## Lab - CDN and Caching

With our live stream functional, we now focus on scalability. Our origin can handle a few simultanious users, but what about hundreds, thousands, or millions? Introducing a Content Delivery Network (CDN) can help us improve performance for end users while lowering the overall load on your backend origin, but you can also implement a cache using an additional tier of nginx. 

Serving every HTTP request from millions of users would require a significant am

 Encoder -> Origin <-> CDN <-> Client

1. deploy lab3 cfn template creating a cache tier and application load balancer in front of it
2. Create a new Cloudfront distribution
3. Configure our origin (ALB)
4. Use test client to play back the stream, now with Cloudfront URL


## Extra Credit

* Use your own camera and RTMP capable encoder to contribute a source to the origin (beware bandwidth requirements)
* Decrease overall live latency by tuning the segment sizes
* Implement cubemap filter in VOD processing fleet to compare against live spherical projection
* Use spot fleet for VOD processing fleet
* Implement OAI so that only cloudfront can access the origin/cache fleet

## Additional Resources and References

Bandwidth optimization and Quality
Adaptive Focus
HEVClive production, multi-camera, switching/editing (vremiere

https://code.facebook.com/posts/1126354007399553/next-generation-video-encoding-techniques-for-360-video-and-vr/
http://web.cecs.pdx.edu/~fliu/project/vremiere/

https://github.com/facebook/transform360 – ffmpeg cubemap
https://github.com/arut/nginx-rtmp-module – nginx rtmp


