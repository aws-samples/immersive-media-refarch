# Immersive Live Streaming on AWS

## Overview

Immersive video, often referred to as VR or 360-video, allows content creators to capture and deliver unique experiences. Social Media sites have implemented immersive video into their platforms, making it widely accessible to consumers, but what of builders who seek to design our own unique experiences, where do we begin? 

Additionally, live streaming, a commodotized consumer product spanning far outside the realm of Social Media, still poses unique implementation challenges. One mistake can cost rightsholders revenue and, arguably worse, customer loyalty.

In this workshop, we bring these two technologies together. Demystifying live streaming, while examining the unique experience of immersive video.

### Requirements

* AWS account - if you don't have one, it's easy and free to create one.
* AWS IAM account with elevated privileges allowing you to interact with CloudFormation, IAM, EC2, ECS, S3, Cloudwatch, and Cloudfront.
* A workstation or laptop with an SSH client installed, such as putty on Windows or Terminal on MacOS.
* Familiarity with bash, web servers, video processing, and streaming media is strongly encouraged, but not absolutely required.

### Labs

The labs in this directory are designed to be completed in sequential order. If you're attending an AWS event, your host will give you an overview of the technology and expectations for each lab. If you're following along at home, we've provided the presentation materials as a pdf. Feel free to open issue tickets on the repo if you have questions or issues. 

Please use a modern verion of the Google Chrome browser as this is what we've used to design the workshop. We also recommend having a scratch pad or somewhere to keep important information throughout the lab.

**Lab 1:** Live Streaming Service

**Lab 2:** Video-on-Demand Recording

**Lab 3:** Reliability

### Conventions

Throughout this README, we provide commands for you to run in the terminal.  These commands will look like this: 

<pre>
$ ssh -i <b><i>PRIVATE_KEY.PEM</i></b> ec2-user@<b><i>primaryOriginIP</i></b>
</pre>

The command starts after $.  Words that are ***UPPER_ITALIC_BOLD*** indicate a value that is unique to your environment.  For example, the ***PRIVATE\_KEY.PEM*** refers to the private key of an SSH key pair that you've created, and the camelCase ***primaryOriginIP*** is a value provided found in the console, either as a Cloudformation Output or as indicated.


### Cleanup and Disclaimer

This section will appear again below as a reminder because you will be deploying infrastructure on AWS which will have an associated cost. Fortunately, this workshop should take no more than 2.5 hours to complete, and uses primarily EC2 Spot instances, so costs will be minimal. See the appendix for an estimate of what this workshop should cost to run. When you're done with the workshop, follow these steps to make sure everything is cleaned up.

* Delete any manually created resources throughout the labs.
* Delete any files stored on S3.
* Delete both CloudFormation stacks launched throughout the workshop.


## Challenge

Imagine that you're part of the re:Invent 2017 team. There's limited session availablity and not everyone can attend in person - what can you do? As the organizer, you could stream the sessions with regular old video with a fixed field-of-vision **_or_** you could raise the bar for conference streaming everywhere by streaming a truly immersive experience. Your challenge, should you choose to accept it, is to build this system by following the labs in this workshop.

 ![Launch 360 Live Streaming Stack into Ireland with CloudFormation](images/arch.png)

## Lab 0 - Setup

1\. First, you'll select a [region](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html). At the top right hand corner of the AWS Console, you'll see a **Support** dropdown. To the left of that is the region selection dropdown. For this lab, please use **Ireland**. 

2\. Next, you need to create an SSH key pair which is used to login to the instances once provisioned.  Go to the EC2 Dashboard and click on **Key Pairs** in the left menu under Network & Security.  Click **Create Key Pair**, provide a name (can be anything, make it something memorable) when prompted, and click **Create**.  Once created, the private key in the form of .pem file will be automatically downloaded.  

If you're using linux or mac, change the permissions of the .pem file to be less open.  

<pre>$ chmod 400 <b><i>PRIVATE_KEY.PEM</i></b></pre>

If you're on windows you'll need to convert the .pem file to .ppk to work with putty.  Here is a link to instructions for the file conversion - [Connecting to Your Linux Instance from Windows Using PuTTY](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/putty.html)

3\. We provide a CloudFormation template to help attendees get started. This template launches much of the infrastructure required, but leaves certain components for you, the participant, to implement.

_Prior to launching a stack, be aware that a few of the resources launched need to be manually deleted when the workshop is over. When finished working, please review the "Workshop Cleanup" section to learn what manual teardown is required by you._

Click on the Deploy to AWS button below to launch the required infrastructure in the Ireland (eu-west-1) region.

 [![Launch 360 Live Streaming Stack into Ireland with CloudFormation](images/deploy-to-aws.png)](https://console.aws.amazon.com/cloudformation/home?region=eu-west-1#/stacks/new?stackName=immersive-live-streaming-stack&templateURL=https://s3-eu-west-1.amazonaws.com/immersive-streaming-workshop/start.yaml)  

The template will automatically bring you to the CloudFormation Dashboard and start the stack creation process in the specified region. Click "Next" on the page it brings you to. Do not change anything on the first screen.

![CloudFormation PARAMETERS](/images/cf-initial.png)

The template sets up a VPC, IAM roles, S3 bucket, SQS, ALB, and EC2 Instances running various components of the solution - origin, cache, and transcode.  The idea is to provide a contained environment, so as not to interfere with any other provisioned resources in your account.  In order to demonstrate cost optimization strategies, the EC2 Instances are [EC2 Spot Instances](https://aws.amazon.com/ec2/spot/) deployed by [Spot Fleet](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-fleet.html).  If you are new to [CloudFormation](https://aws.amazon.com/cloudformation/), take the opportunity to review the [template](https://github.com/awslabs/immersive-media-refarch/blob/master/workshop/start.yaml) during stack creation.

**IMPORTANT**  
*On the parameter selection page of launching your CloudFormation stack, make sure to choose the key pair that you created in step 1. If you don't see a key pair to select, check your region and try again.*

![CloudFormation PARAMETERS](/images/cf-params.png)

**Create the stack**  
After you've selected your ssh key pair, click **Next**. On the **Options** page, accept all defaults- you don't need to make any changes. Click **Next**. On the **Review** page, under **Capabilities** check the box next to **"I acknowledge that AWS CloudFormation might create IAM resources."** and click **Create**. Your CloudFormation stack is now being created.

**Checkpoint**  
Periodically check on the stack creation process in the CloudFormation Dashboard.  Your stack should show status **CREATE\_COMPLETE** in roughly 5-10 minutes.  In the Outputs tab, take note of the **primaryOriginElasticIp** and **clientWebsiteUrl** values; you will need these in the following labs.     

![CloudFormation CREATION\_COMPLETE](/images/cf-complete.png)

When your stack moves to a **CREATE\_COMPLETE** status, you won't necessarily see EC2 instances yet. If you don't, go to the EC2 console and click on **Spot Requests**. There you will see the pending or fulfilled spot requests. Once they are fulfilled, you will see your EC2 instances within the EC2 console.

If there an error occurs during stack creation, CloudFormation will rollback and terminate.  You can investigate and troubleshoot by looking in the Events tab. Errors encountered during stack creation will appear in the event log. 

## Lab 1 - Live Streaming Service

In this lab, you will live stream to the origin and confirm that it plays back with a test client. But, first, a word on transmitting live video...

In the real-world, content is captured in real-time via a camera, compressed, and sent to a central location for further processing and distribution. Broadcasting from a remote production location to distribution infrastructure is called *Contribution* and it requires careful consideration of the network charactaristics between these two geographic points.

- Does the remote location have dedicated bandwidth, public internet connectivity, cellular or nothing at all?
- What data rate is required to create a quality end-user experience?
- Do we need redundant contribution streams over multiple network paths?
- Do users have latency expectations?
- Which protocol(s) are supported by on-premise equipment and the origin?

In a development environment, you can avoid most of these questions by using a local test signal to simulate a live stream. FFmpeg has been built into the origin and you'll use it to generate the live signal. But, don't forget to connect other devices if bandwidth is available. 

**IMPORTANT**
_Mobile phones will not warn you when streaming over cellular networks and can quickly eat up capped data plans. AWS **_IS NOT_** liable for data charges incurred as a part of this workshop._

From the Cloudformation console, select the stack you created, then Outputs. Find _**primaryOriginElasticIp**_ and note the value. This is the IP address of your media origin. 

{image of cloudformation console, highligh pimaryOrigin}

SSH into the origin instance with the following command:

<pre>$ ssh -i <b><i>PRIVATE_KEY.PEM</i></b> ec2-user@<b><i>primaryOriginElasticIp</b></i></pre>

Next, start ffmpeg to simulate a live signal. The following command uses lavfi/libavfilter with ffmpeg to generate a test pattern. A full description of each flag can be found in the appendix.

_Use of a terminal multiplexer like screen or tmux is advised to open multiple shells over a single SSH session._

<pre>
$ ffmpeg -stats -re -f lavfi -i aevalsrc="sin(400*2*PI*t)" -f lavfi -i testsrc=size=1280x720:rate=30 -vcodec libx264 -b:v 500k -c:a aac -b:a 160k -vf "format=yuv420p" -f flv 'rtmp://localhost/live/test'
</pre>

With the test stream running and connected to the origin, new [Apple HLS](https://developer.apple.com/streaming/) transport stream segments are generated and old segments cleaned-up by the nginx-rtmp module. Confirm that this is the case by listing the directory contents periodically or _watch_-ing the segment manifest file.

<pre>$ sudo watch -n 0.5 cat /var/lib/nginx/hls/test_1280/index.m3u8</pre>

{image or gif of updating manifest file}

Now for the exciting part - _playing the live stream_. Within the CloudFormation console, find the Output listed as _**clientWebsiteUrl**_. This is a static website, built with [A-Frame](https://aframe.io/) and [HLS.js](https://github.com/video-dev/hls.js/), hosted in an S3 bucket. Copy the link or open it in a new browser tab, but note that playback requires a value for the _url_ query string parameter at the end. To view the stream from the origin combine the _**primaryOriginElasticIp**_ with the nginx-rtmp application (hls) and stream name (test). You'll end up with something similar to this example:

<pre>http://<b>YOUR_TRANSCODINGEGRESS_BUCKET</b>.s3-website-REGION.amazonaws.com/?url=http://<b>primaryOriginElasticIp</b>/hls/test.m3u8</pre>

You should now see spherical colorbars and hear a test tone from the system. Success!

{gif of colorbars and ticking}


## Lab 2 - Video on Demand

What about participants who aren't able to attend during the scheduled session?You should create a Video-on-Demand recording that allows anyone to virtually attend when they chose. Thankfully, the nginx-rtmp record directive that works like a VCR. You'll use this to capture the live source and then transcode the recording with a fleet of EC2 instances. 

{diagram}

With the VOD transcode fleet, jobs can run much slower than real-time, emphasizing quality over real-time delivery. Additionally, if we want to create additional ABR renditions or apply alternate projection mapping filters, you'll need a file-based transcoder.


### Config Changes


1\. SSH into the Origin

<pre>$ ssh -i <b><i>PRIVATE_KEY.PEM</i></b> ec2-user@<b><i>primaryOriginElasticIp</b></i></pre>

Modify the nginx configuration to include the record directive. This records all audio/video streams to /var/lib/nginx/rec, rolls over the file when the size reaches 128M, and, upon recording creation, executes a script to upload the asset into S3. A full listing and description of the nginx-rtmp directives can be found [here](https://github.com/arut/nginx-rtmp-module/wiki/Directives).

<pre>$ sudo nano /etc/nginx/rtmp.d/rtmp.conf</pre>

```
   ...
      # put record directive configuration here
      record all;
      record_path /var/lib/nginx/rec;
      record_max_size 128000K;
      exec_record_done /usr/local/bin/record-postprocess.sh $path $basename;
   ...
```

2\. Restart nginx for the changes to take effect.

<pre>$ sudo service nginx restart</pre>

### Testing Video-on-Demand

Recording begins when a stream is published to the nginx application. Upon stream stop, nginx-rtmp finishes the recording and executes a script to upload into **_s3IngressBucket_**. New objects in this bucket generate an event, which is published to _**transcodingQueue**_. _**transcodingSpotFleet**_ periodically polls this queue and transcodes the recordings and resulting ABR outputs are uploaded into **_s3EgressBucket_**, the same bucket hosting our client page.

With the configuration updates in place, you can now test the full system functionality. There's a few components to the VOD system, so you'll want to examine each one to validate proper execution. 

1\. SSH into the origin and start the ffmpeg test stream

<pre>
$ ffmpeg -stats -re -f lavfi -i aevalsrc="sin(400*2*PI*t)" -f lavfi -i testsrc=size=1280x720:rate=30 -vcodec libx264 -b:v 500k -c:a aac -b:a 160k -vf "format=yuv420p" -f flv 'rtmp://localhost/live/test'
</pre>

2\. Open the SQS console, select the queue containing _**-transcodingQueue**_, select _Queue Actions_ from the menu and then _View Messages_. Finally, to view messages as they appear, click the blue _Start Polling for Messages_ button

{image example}

Simple Queue Service (SQS) decouples the transcode requests from the transcode fleet. It carries the S3 bucket event, generated when a new recording is put into **_s3IngressBucket_**, and serves as a job queue for the _**transcodingSpotFleet**_. In the event that an instance fails or is terminated by EC2 Spot, events will return to the queue and be processed by another node. This system also uses the queue depth to autoscale _**transcodingSpotFleet**_ based on number of recordings waiting to be processed, though it has been set to 1 to minimze workshop costs.

3\. Back in the terminal window, stop the ffmpeg test source by pressting ctrl+c

4\. Confirm message has been generated in the queue

![Queue Message](images/queue_message.png)

The transcode worker is running a polling script every 5 seconds to pull down any new job from SQS. By now, it should be processing a job. We can confirm this by looking at the CPU utilization, viewing the notification in the Cloudwatch Log Stream, or by simply waiting for the output to appear in the S3 bucket _**transcodingEgressBucketId**_.

5\. In the EC2 console, search for 'transcoding', this will filter for the EC2 instance we have deployed that has the _transcodingSecurityGroup_ attached. Select the resulting instance and, at the bottom of the console, select the _Monitoring_ tab. Here, we should see a sharp incline in the CPU utilization while the instance is processing.

{cpu incline example}

6\. When the CPU metric goes down, our VOD transcode is complete. Navigate to the S3 console and search/select the bucket containing _**transcodingEgress**_. Here, you should see a key starting with test-_TIMESTAMP/_, this was the output directory of the transcode job and is now the object prefix within S3. Within, there should be many transport stream (.ts) and manifest (.m3u8) objects. Select the MANIFEST.m3u8 and note the link, this is our playback URL for the video-on-demand recording, now transcoded for adaptive bitrate delivery.

7\. To test playback, use the client from Lab 1. If you've closed the tab, the URL can be found by opening the Cloudformation console and selecting up the Cloudformation Output _**clientWebsiteUrl**_. Next, update the ?url= query parameter with the newly created m3u8 URL and confirm that the VOD asset plays for approximately the duration ffmpeg was streaming. 

<pre>http://<b><i>clientWebsiteUrl</b></i>?url=https://s3-us-west-2.amazonaws.com/<b><i>transcodingEgressBucketId</b></i>/test-1508866984/MANIFEST.M3U8
</pre>

You've successfully modified the architecture to record a live stream, transcode it with EC2, and host it with an S3 bucket. Great work! With our live and VOD functional, let's make sure it stays operational during the event, no matter how many people tune in!


## Lab 3 - Reliability

In the previous two labs, a web browser retrieved the stream. This worked well for functional play testing, but now you need to simulate many simultanious client requests and validate that the system functions for more than a few users. [Apache Jmeter](https://jmeter.apache.org/) is a Java based test framework that simulates client load at scale. The Jmeter configuration is outside of the workshop scope, but we encourage you to browse the documentation and lab.jmx file to learn more.

In addition to generating load, Jmeter can produce basic results visualization in a webpage. This will prove useful to see how caching affects server response time. This lab will focus only on response time, however, additional metrics can be gathered by implementing Real User Metrics in the player or implementing custom CloudWatch metrics for the service. Check out [Raising the Bar on Video Streaming Quality](https://www.youtube.com/watch?v=IGXrnQviFLc) for a fantasitc overview of how Amazon Video addresses this common challenge.

{architecture diagram}

1\. To begin, deploy the following Cloudformation template in any region that *is not* Ireland. The goal is to simulate load coming from real users, so use a different region. If you have not already done so, you will need to create an SSH keypair for this region. Please refer to the steps in Lab 0.

[![Launch 360 Live Streaming Stack into Ireland with CloudFormation](images/deploy-to-aws.png)](https://console.aws.amazon.com/cloudformation/home?region=us-west-2#/stacks/new?stackName=ecs-deep-learning-stack&templateURL=https://s3.amazonaws.com/ecs-dl-workshop-us-west-2/ecs-deep-learning-workshop.yaml)  


2\. If necessary, start the test stream on the origin. You may have to SSH back into the instance or switch back to the Ireland region to retrieve the IP address.

<pre>$ ssh -i <b><i>PRIVATE_KEY.PEM</i></b> ec2-user@<b><i>primaryOriginElasticIp</b></i></pre>

<pre>
$ ffmpeg -stats -re -f lavfi -i aevalsrc="sin(400*2*PI*t)" -f lavfi -i testsrc=size=1280x720:rate=30 -vcodec libx264 -b:v 500k -c:a aac -b:a 160k -vf "format=yuv420p" -f flv 'rtmp://localhost/live/test'
</pre>


3\. From the EC2 Console in the new region, determine the IP address of the instance deployed by the recent template, then SSH into it.

<pre>$ ssh -i <b><i>PRIVATE_KEY.PEM</i></b> ec2-user@<b><i>loadTestingEC2Instance</b></i></pre>

4\. Run jmeter replacing the _-Jhost_ flag with the **_originElasticIpAddress_**. Once executed, the test will run for 3 minutes, simulating 150 clients, ramping up over a period of 15 seconds. A log of the test and an HTML webpage will be generated in the required web-hosted directory.

_Note that the HLS path /hls/test.m3u8 is hardcoded into the jmx file. If you're using a different streamname than test, you must modify this to continue._

<pre>$ jmeter -n -t ~/lab.jmx -l /var/www/html/results/$(date +%H%M%S).txt -e -o /var/www/html/results/$(date +%H%M%S)/ -Jthreads=150 -Jrampup=15 -Jhost <b><i>originElasticIpAddress</b></i></pre>

5\. In the EC2 console, watch the test impact CPU in near real-time by selecting the instance, then the _Monitoring_ tab.

{screenshot of uptick in cpu}

The load on the origin, omitting long-running processes and ffmpeg, is ~2%. This isn't much, but remember, you only simulated 150 clients. What if you were expecting 150,000 concurrent viewers? (Hey, who knows, maybe it's a really popular workshop!). It would be difficult to find an instance with 2000% more CPU power and costly to send the _contribution_ feed to multiple origins. Recall that this was one of the early considerations and the reason you're using a test source on the origin itself. Bandwidth can be expensive, especially from events in Las Vegas!

So, what to do? You reduce load on the origin by introducing caches.

### Edge Cache _a.k.a._ Origin Protection Cache _a.k.a_ Proxy Cache

For the purposes of live streaming a [proxy cache](https://www.wikiwand.com/en/Web_cache), when properly configured, can:

* Reduce load on the origin by orders of magnitude with caching and request coalescing
* Protect the origin(s) from unforseen CDN issues, like the [thundering herd problem](https://www.wikiwand.com/en/Thundering_herd_problem), during a largescale live event
* Scale horizontally and, with a diversified EC2 Spot Fleet request, cheaply
* Use multiple upstream origins for 1+1 redundancy
* Terminate SSL connections

Just like dividing responsibility between cooks (origin) and the wait staff (caches) at your favorite resturant, you can use this pattern to improve reliability. With deterministic load on the origin, you don't have to worry about it being crushed by unforseen load, rendering the service unavailable. Afterall, cooks should be making declicious food, not taking orders and serving it. (I'm getting hungry... but back to the video!)

The origin converts the contribution stream into adaptive bitrate, while the cache tier serves and caches the response data for a period of time or the _Time-To-Live_ value (TTL). The TTL is set by the origin and controls downstream cache behavior. For Apple HLS, especially live, it's important to control the segment manifest TTL seperately from the media segments. The segment manifest updates with every new segment made available by the origin and, if it's cached too long, could cause client issues.

{diagram of caching in action}

**_edgeCacheSpotFleet_**, managed by an EC2 Spot Fleet, uses Application Load Balancer and an Autoscaling Group to dynamically scale based on load. To keep costs at a minimum, this workshop defaults to a single instance, but you can override this in the future by changing the _**edgeCacheSpotFleetMaximumCapacity**_ parameter while launching the stack in Cloudformation.

Let's test this tier to see how it changes the performance charataristics of the system.


1\. SSH into the load testing instance if you haven't already done so.

<pre>$ ssh -i <b><i>PRIVATE_KEY.PEM</i></b> ec2-user@<b><i>loadTestingEC2Instance</b></i></pre>

2\. Run the same Jmeter load test, this time updating the -Jhost flag to point to the DNS of the Application Load Balancer that's handling requests for the cache fleet, called _**applicationLoadBalancerDns**_ in the Ireland Cloudformation Outputs.

<pre>$ jmeter -n -t ~/lab.jmx -l /var/www/html/results/$(date +%H%M%S).txt -e -o /var/www/html/results/$(date +%H%M%S)/ -Jthreads=150 -Jrampup=15 -Jhost <b><i>applicationLoadBalancerDns</b></i></pre>

3\. In the EC2 console, watch the load test impact origin CPU in near real-time by selecting the instance, then the _Monitoring_ tab. The origin load is almost invisible compared to the 2% from the previous test, success!

4\. When Jmeter is complete, access the results via a web browser and explore the response time metric.

<pre>http://<b><i>loadTestingEC2Instance</b></i>/results/<b><i>HHMMSS</b></i>/</pre>

The response time metric will vary depending on client location and internet connectivity. re:Invent is a global conference for attendees all over the world, how can you improve service response time performance for any viewer, no matter the location?


### Content Delivery Network

Introducing a [Content Delivery Network](https://www.wikiwand.com/en/Content_delivery_network) (CDN) is another common strategy to improve client performance while further decreasing load on the service components (origin, cache). We have not configured the CDN as part of this lab, so you need to configure Cloudfront before testing.

1\. Open the Cloudfront console, click Create Distribution, then Get Started under the Web heading

2\. Configure the Distribution by populating the Origin Domain Name field with the _**applicationLoadBalancerDns**_. The default configuration is suffecient for this workshop, scroll to the bottom of the page and click _Create Distribuion_. 

With this configuration, initial client requests to Cloudfront and cache misses will be fulfilled from the **_edgeCacheSpotFleet_**. If **_edgeCacheSpotFleet_** also cache misses, requests will finally be fulfilled by the origin.

{visual representation of caching}

3\. Now you're ready to test. SSH into one the load testing instance

<pre>$ ssh -i <b><i>PRIVATE_KEY.PEM</i></b> ec2-user@<b><i>loadTestingEC2Instance</b></i></pre>

4\. Update the _-Jhost_ flag to point to the Domain of the Cloudfront Distribution, found in the Cloudfront console under Domain Name.

{SCREENSHOT}

<pre>$ jmeter -n -t ~/lab.jmx -l /var/www/html/results/$(date +%H%M%S).txt -e -o /var/www/html/results/$(date +%H%M%S)/ -Jthreads=150 -Jrampup=15 -Jhost <b><i>cloudfrontDistributionDns</b></i></pre>

5\. When Jmeter is complete, access the results via a web browser. Compare the response time metrics against the previous test.

<pre>http://<b><i>loadTestingEC2Instance</b></i>/results/<b><i>HHMMSS</b></i>/</pre>

Adding a CDN improved client response time by a HUGE amount! The viewers will definitely appreciate the performance enhancements and the processing costs to serve all of them have decreased significantly. Win, win!

## Conclusion

We hope you enjoyed the workshop and are inspired to incorporate these learnings into your own video streaming projects. Please submit any questions or issues to the github repo and we'll do our best to answer. 

## To Try or Build

Here's a few extra things to try if you still have time left over during the workshop:

* Try using your own camera and RTMP capable encoder to contribute a source to the origin (beware bandwidth requirements)
* Try adjusting the fleet target size, creating a few VOD recordings, and watching the _**transcodingSpotFleet**_ scale up

Please submit pull requests to this workshop or associated parent reference architecture. We're happy to help you get started with any of these items:

* Implement a SNS email notification to notify an administrator when a recording has completed processing
* Decrease overall live latency by tuning the HLS segment sizes
* Implement cubemap filter in VOD processing fleet to compare against live spherical projection
* Implement OAI so that only Cloudfront can access the origin/cache fleet
* Implement a CI/CD testing for the Codepipeline


### Cleanup and Disclaimer

This section will appear again below as a reminder because you will be deploying infrastructure on AWS which will have an associated cost. Fortunately, this workshop should take no more than 2 hours to complete, so costs will be minimal. See the appendix for an estimate of what this workshop should cost to run. When you're done with the workshop, follow these steps to make sure everything is cleaned up.

* Delete any manually created resources throughout the labs.
* Delete any files stored on S3.
* Delete both CloudFormation stacks launched throughout the workshop.

## Appendix

### Cost Breakdown

### FFmpeg Command Reference

<pre>
$ ffmpeg -stats -re -f lavfi -i aevalsrc="sin(400*2*PI*t)" -f lavfi -i testsrc=size=1280x720:rate=30 -vcodec libx264 -b:v 500k -c:a aac -b:a 160k -vf "format=yuv420p" -f flv 'rtmp://localhost/live/test'
</pre>

### 360 Cameras We've Tested

Ricoh Theta
insta360 one
insta360 ?

## Additional Resources and References
## Live Streaming Basics



Bandwidth optimization and Quality
Adaptive Focus
HEVClive production, multi-camera, switching/editing (vremiere

https://code.facebook.com/posts/1126354007399553/next-generation-video-encoding-techniques-for-360-video-and-vr/
http://web.cecs.pdx.edu/~fliu/project/vremiere/

https://github.com/facebook/transform360 – ffmpeg cubemap
https://github.com/arut/nginx-rtmp-module – nginx rtmp




When Jmeter is complete, you can access the results via a web browser.

<pre>http://<b><i>loadTestingEc2Instance</b></i>/results/</pre> 

 Click on the directory named _HHMMSS_ timestamp associated with the jmeter test and review the results.

 {image of origin results, don't confuse with ffmpeg}

Note the average latency, percentiles, etc. Not bad for a single instance! Keep this tab open and compare the origin performance, with that of the cache and CDN to discover the value of those additional tiers.


