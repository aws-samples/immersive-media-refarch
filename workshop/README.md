# W.I.P 360-degree live streaming on AWS

## Overview

360-degree video allows content creators to capture and deliver unique experiences. Social Media sites have implemented 360-degree video into their platforms, making it simple to access, but what of those who attempt to build our own unique experiences, where do we begin? Additionally, live streaming, a commodotized consumer product spanning far outside the realm of Social Media, still poses unique implementation challenges.

In this workshop, you'll is to combine these technologies. Demystifying live streaming, while brrining the unique experience of immersive video.

### Requirements

* AWS account - if you don't have one, it's easy and free to create one
* AWS IAM account with elevated privileges allowing you to interact with CloudFormation, IAM, EC2, ECS, S3, Cloudwatch, and Cloudfront
* A workstation or laptop with an ssh client installed, such as putty on Windows or terminal on Mac
* Familiarity with Command Line (Bash), web servers, and video processing is a plus, but not absolutely required

### Labs

The labs in this directory are designed to be completed in sequential order. If you're attending an AWS event, your host will give you an overview of the technology and expectations for each lab. If you're following along at home, we've provided the presentation materials as a pdf. Feel free to open issue tickets on the repo if you have questions or issues. Please use a modern verion of the Google Chrome browser as this is what we've used to design the workshop.

**Lab 1:** Simple Live Streaming Service

**Lab 2:** Video-on-Demand Recording

**Lab 3:** Caching and Content Delivery

### Conventions

Throughout this README, we provide commands for you to run in the terminal.  These commands will look like this: 

<pre>
$ ssh -i <b><i>PRIVATE_KEY.PEM</i></b> ec2-user@<b><i>primaryOriginIP</i></b>
</pre>

The command starts after $.  Words that are ***UPPER_ITALIC_BOLD*** indicate a value that is unique to your environment.  For example, the ***PRIVATE\_KEY.PEM*** refers to the private key of an SSH key pair that you've created, and the camelCase ***primaryOriginIP*** is a value provided found in the console.


### Cleanup and Disclaimer

TODO


## Challenge

Imagine that you're part of the Re:Invent `17 team. There's limited session availablity and not everyone can attend in person - what could you do? As the organizer, you could stream the sessions in regular old fixed/flat view with a narrow field-of-vision **_or_** you could "raise the bar" on conference streaming vy delivering an immersive experience. Your challenge, should you choose to accept it, is to build this immersive live streaming system by following this workshop.

{marketechture}

## Lab 0 - Setup

1\. First, you'll need to select a [region](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html). For this lab, you need to choose either **Ohio** or **Oregon**. At the top right hand corner of the AWS Console, you'll see a **Support** dropdown. To the left of that is the region selection dropdown.

2\. Next, you need to create an SSH key pair which is used to login to the instances once provisioned.  Go to the EC2 Dashboard and click on **Key Pairs** in the left menu under Network & Security.  Click **Create Key Pair**, provide a name (can be anything, make it something memorable) when prompted, and click **Create**.  Once created, the private key in the form of .pem file will be automatically downloaded.  

If you're using linux or mac, change the permissions of the .pem file to be less open.  

<pre>$ chmod 400 <b><i>PRIVATE_KEY.PEM</i></b></pre>

If you're on windows you'll need to convert the .pem file to .ppk to work with putty.  Here is a link to instructions for the file conversion - [Connecting to Your Linux Instance from Windows Using PuTTY](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/putty.html)

3\. We provide a CloudFormation template to help attendees get started. This template launches much of the infrastructure required, but leaves certain components for you, the participant, to build.

{architecture diagram}

*Prior to launching a stack, be aware that a few of the resources launched need to be manually deleted when the workshop is over. When finished working, please review the "Workshop Cleanup" section to learn what manual teardown is required by you.*

Click on one of these CloudFormation templates that matches the region you created your keypair in to launch your stack:  

Region | Launch Template
------------ | -------------  
**Ohio** (us-east-2) | [![Launch ECS Deep Learning Stack into Ohio with CloudFormation](images/deploy-to-aws.png)](https://console.aws.amazon.com/cloudformation/home?region=us-east-2#/stacks/new?stackName=ecs-deep-learning-stack&templateURL=https://s3.amazonaws.com/ecs-dl-workshop-us-east-2/ecs-deep-learning-workshop.yaml)  
**Oregon** (us-west-2) | [![Launch ECS Deep Learning Stack into Oregon with CloudFormation](images/deploy-to-aws.png)](https://console.aws.amazon.com/cloudformation/home?region=us-west-2#/stacks/new?stackName=ecs-deep-learning-stack&templateURL=https://s3.amazonaws.com/ecs-dl-workshop-us-west-2/ecs-deep-learning-workshop.yaml)  

The template will automatically bring you to the CloudFormation Dashboard and start the stack creation process in the specified region. Click "Next" on the page it brings you to. Do not change anything on the first screen.
![CloudFormation PARAMETERS](/images/cf-initial.png)

The template sets up a VPC, IAM roles, S3 bucket, SQS, and EC2 Instances running various components of the solution - origin, cache, and transcode.  The idea is to provide a contained environment, so as not to interfere with any other provisioned resources in your account.  In order to demonstrate cost optimization strategies, the EC2 Instances are [EC2 Spot Instances](https://aws.amazon.com/ec2/spot/) deployed by [Spot Fleet](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-fleet.html).  If you are new to [CloudFormation](https://aws.amazon.com/cloudformation/), take the opportunity to review the [template](https://github.com/awslabs/immersive-media-refarch/blob/master/workshop/start.yaml) during stack creation.

**IMPORTANT**  
*On the parameter selection page of launching your CloudFormation stack, make sure to choose the key pair that you created in step 1. If you don't see a key pair to select, check your region and try again.*
![CloudFormation PARAMETERS](/images/cf-params.png)

**Create the stack**  
After you've selected your ssh key pair, click **Next**. On the **Options** page, accept all defaults- you don't need to make any changes. Click **Next**. On the **Review** page, under **Capabilities** check the box next to **"I acknowledge that AWS CloudFormation might create IAM resources."** and click **Create**. Your CloudFormation stack is now being created.

**Checkpoint**  
Periodically check on the stack creation process in the CloudFormation Dashboard.  Your stack should show status **CREATE\_COMPLETE** in roughly 5-10 minutes.  In the Outputs tab, take note of the **primaryOriginElasticIp** and **clientWebsiteUrl** values; you will need these in the following labs.     

![CloudFormation CREATION\_COMPLETE](/images/cf-complete.png)

Note that when your stack moves to a **CREATE\_COMPLETE** status, you won't necessarily see EC2 instances yet. If you don't, go to the EC2 console and click on **Spot Requests**. There you will see the pending or fulfilled spot requests. Once they are fulfilled, you will see your EC2 instances within the EC2 console.

If there was an error during the stack creation process, CloudFormation will rollback and terminate.  You can investigate and troubleshoot by looking in the Events tab.  Any errors encountered during stack creation will appear in the event log. 

## Lab 1 - Simple Streaming Service

In this lab, you will live stream to the origin and confirm that it plays back with a test client. But, first, a word on transmitting live video...

In the real-world, content is captured in real-time via a camera, compressed, and sent to a central location for further processing and distribution. Streaming from a remote production location to distribution infrastructure is called *Contribution* and it requires careful consideration of the network charactaristics between these two geographic points.

- Will the remote location have dedicated bandwidth or only public internet connectivity?
- What data rate is required to create a quality end-user experience?
- Redundant contribution streams over multiple network paths?
- Do users have latency expectations?
- Which protocol is most appropriate? HLS/RTMP/RTP?

By using a test source to simulate a live stream, you can test the infrastructure local to the region in which it is deployed and avoid first-mile connectivity challenges. Use the test source for the labs, but don't forget to connect other devices if bandwidth is available. Proceed with caution on mobile phones though, they will not warn you when streaming over cellular networks and can quickly eat up capped data plans. AWS **_IS NOT_** liable for data charges incurred as a part of this workshop.

From the Cloudformation console, select the stack you created, then Outputs. Find _**primaryOriginElasticIp**_ and note the value. This is the IP address of your media origin. 

{image of cloudformation console, highligh pimaryOrigin}

SSH into the origin instance with the following command:

<pre>$ ssh -i <b><i>PRIVATE_KEY.PEM</i></b> ec2-user@<b><i>primaryOriginElasticIp</b></i></pre>

Next, start ffmpeg to simulate a real-time source. The following command uses lavfi/libavfilter with ffmpeg to generate a test pattern.

{additional details on ffmpeg command when finished with rightsizing}

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

{picture of colorbars}


## Lab 2 - Video on Demand

What about participants who aren't able to attend during the scheduled session? We should provide them with Video-on-Demand recording to allow anyone to virtually attend when they chose. Thankfully, the nginx-rtmp record directive that works like a VCR. You'll use this to capture the live source and then transcode the recording with a fleet of EC2 instances. 

{diagram}

With the VOD transcode fleet, jobs can run much slower than real-time, emphasizing quality over real-time delivery. Additionally, if we want to create additional ABR renditions or apply alternate projection mapping filters, you'll need a file-based transcoder.


### Config Changes


SSH into the Origin

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

Restart nginx for the changes to take effect.

<pre>$ sudo service nginx restart</pre>

### VOD Test

Recording begins when a stream is published to the nginx application. Upon stream stop, nginx-rtmp finishes the recording and executes a script that uploads it to **_s3IngressBucket_**. New objects in this bucket generate an event, which is published to _**transcodingQueue**_. _**transcodingSpotFleet**_ periodically polls this queue and transcodes the recording. Resulting ABR outputs are uploaded into **_s3EgressBucket_**, the same bucket hosting our client page.

With the configuration updates in place, you can now test the full system functionality. There's a few components to the VOD system, so you'll want to examine each one to validate proper execution. 

1\. SSH into the origin and start the ffmpeg test stream

<pre>
$ ffmpeg -stats -re -f lavfi -i aevalsrc="sin(400*2*PI*t)" -f lavfi -i testsrc=size=1280x720:rate=30 -vcodec libx264 -b:v 500k -c:a aac -b:a 160k -vf "format=yuv420p" -f flv 'rtmp://localhost/live/test'
</pre>

2\. Open the SQS console, select the queue containing _**-transcodingQueue**_, select _Queue Actions_ from the menu and then _View Messages_. Finally, to view messages as they appear, click the blue _Start Polling for Messages_ button

{image example}

Simple Queue Service (SQS) decouples the transcode requests from the transcode fleet. It carries the S3 bucket event, generated when a new recording is put into **_s3IngressBucket_**, and serves as a job queue for the _**transcodingSpotFleet**_. In the event that an instance fails or is terminated by EC2 Spot, events will return to the queue and be processed by another node. This system also uses the queue depth to autoscale _**transcodingSpotFleet**_ based on number of recordings waiting to be processed.

3\. Back in the terminal window, stop the ffmpeg test source by pressting ctrl+c

4\. Confirm message has been generated in the queue

![Queue Message](images/queue_message.png)

The transcode worker is running a polling script every 5 seconds to pull down any new job from SQS. By now, it should be processing a job. We can confirm this by looking at the CPU utilization, viewing the notification in the Cloudwatch Log Stream, or by simply waiting for the output to appear in the S3 bucket _**transcodingEgressBucketId**_.

5\. In the EC2 console, search for 'transcoding', this will filter for the EC2 instance we have deployed that has the _transcodingSecurityGroup_ attached. Select the resulting instance and, at the bottom of the console, select the _Monitoring_ tab. Here, we should see a sharp incline in the CPU utilization while the instance is processing.

{cpu incline example}

6\. When the CPU metric goes down, our VOD transcode is complete. Navigate to the S3 console and search/select the bucket containing _**transcodingEgress**_. Here, you should see a key starting with test-_TIMESTAMP/_, this was the output directory of the transcode job and is now the object prefix within S3. Within, there should be many transport stream (.ts) and manifest (.m3u8) objects. Select the MANIFEST.m3u8 and note the link, this is our playback URL for the video-on-demand recording, now transcoded for adaptive bitrate delivery.

To test playback, use the client from Lab 1. If you've closed the tab, the URL can be found by opening the Cloudformation console and selecting up the Cloudformation Output _**clientWebsiteUrl**_. Next, update the ?url= query parameter with the newly created m3u8 URL and confirm that the VOD asset plays for approximately the duration ffmpeg was streaming. 

<pre>http://<b><i>clientWebsiteUrl</b></i>?url=https://s3-us-west-2.amazonaws.com/<b><i>transcodingEgressBucketId</b></i>/test-1508866984/MANIFEST.M3U8
</pre>

You've successfully modified the architecture to record a live stream, transcode it with EC2, and host it with an S3 bucket. Great work! With our live and VOD functional, let's turn to scaling and reliability.


## Lab 3 - CDN and Caching

In the previous two labs, a web browser retrieved the stream. This worked well for playback testing, but now you need to simulate many simultanious client requests to ensure the system scales. [Apache Jmeter](https://jmeter.apache.org/) is a Java based test framework that simulates client load at scale. The Jmeter configuration is outside of the workshop scope, but we encourage you to browse the documentation and lab.jmx file to learn more.

In the real-world, load testing is typically part of a development/test pipeline, possibly even automated with services like Codepipeline and Codedeploy. For educational purposes, Jmeter will run on one of the _**transcodingSpotFleet**_ instances. Jmeter has already been installed and the required .jmx configuration is located in /home/ec2-user/.

In addition to generating load, Jmeter can produce basic results visualization. This will prove useful to review the results of each test to see how caching can affect server response times and errors. More advanced metrics can be gathered by implementing additional player-side tooling. [Raising the Bar on Video Streaming Quality](https://www.youtube.com/watch?v=IGXrnQviFLc) is a great overview of how Amazon Video addresses quality of service challenges for their customers.

Average Response Time
P90
Frustration metric

{architecture diagram}


SSH into the origin and start the ffmpeg test stream

<pre>$ ssh -i <b><i>PRIVATE_KEY.PEM</i></b> ec2-user@<b><i>primaryOriginElasticIp</b></i></pre>

<pre>
$ ffmpeg -stats -re -f lavfi -i aevalsrc="sin(400*2*PI*t)" -f lavfi -i testsrc=size=1280x720:rate=30 -vcodec libx264 -b:v 500k -c:a aac -b:a 160k -vf "format=yuv420p" -f flv 'rtmp://localhost/live/test'
</pre>

SSH into one of the transcoding EC2 instances. You can find this by searching 'transcoding' in the EC2 console.

<pre>$ ssh -i <b><i>PRIVATE_KEY.PEM</i></b> ec2-user@<b><i>transcodingInstance</b></i></pre>

Stop transcode watcher and any running VOD transcodes

<pre>$ stop transcode-workder</pre>
<pre>$ pkill ffmpeg</pre>

Run jmeter replacing the -Jhost flag with the **_originElasticIpAddress_**. This test will run for 3 minutes, simulating 50 clients, ramping up over a period of 15 seconds. A log of the test and an HTML webpage will be generated in the required web-hosted directory.

_Note that the HLS path /hls/test.m3u8 is hardcoded into the jmx file. If you're using a different streamname than test, you must modify this to continue._

<pre>$ jmeter -n -t ~/lab.jmx -l /var/www/html/results/$(date +%H%M%S).txt -e -o /var/www/html/results/$(date +%H%M%S)/ -Jthreads=50 -Jrampup=15 -Jhost <b><i>originElasticIpAddress</b></i></pre>

In the EC2 console, you can watch the load test impact CPU in near real-time by selecting the instance, then the _Monitoring_ tab.

When Jmeter is complete, you can access the results via a web browser

<pre>http://<b><i>transcodingInstanceIp</b></i>/results/origin/</pre> 

Note the average latency, percentiles, etc. Not bad for a single instance! Keep this tab open and compare the origin performance, with that of the cache and CDN to discover the value of those additional tiers. 


### Cache

The [proxy cache](https://www.wikiwand.com/en/Web_cache) will help reduce origin load, while protecting the all-important origin from unforseen CDN issues or the [thundering herd problem](https://www.wikiwand.com/en/Thundering_herd_problem) during a large scale live event. 

**_edgeCacheSpotFleet_** has been built using an Application Load Balancer in conjuntion with a fleet of EC2 instances from and EC2 Spot Fleet request. Let's test this tier to see how it benefits the overall performance of the system.

UPDATE With HLS, child manifests will be updating frequently. To prevent caching a manifest for too long and, thus, serving a _stale_ manifest, you can use Cach Behaviors to control the cache. By default Cloudformation will respect the Cache-Control headers provided by the upstream servers.

UPDATE something about cache nodes not storing state, being ephemeral and protection


### Upstream 

1\. SSH into one of the transcoding instances if you haven't already done so.

<pre>$ ssh -i <b><i>PRIVATE_KEY.PEM</i></b> ec2-user@<b><i>transcodingInstance</b></i></pre>

2\. Run the same Jmeter load test, this time updating the -Jhost flag to point to the DNS of ALB
<pre>$ jmeter -n -t ~/lab.jmx -l cache.txt -e -o cache/ -Jhost <b><i>applicationLoadBalancerDns</b></i> -Jthreads=50 -Jrampup=15 -Jduration</pre>

3\. In the EC2 console, watch the load test impact origin CPU in near real-time by selecting the instance, then the _Monitoring_ tab. Can you see how the origin suffers much less when a cache is in place?

4\. When Jmeter is complete, you can access the results via a web browser

<pre>http://<b><i>transcodingInstanceIp</b></i>/results/cache/</pre>

5\. Note the average latency, percentiles, etc. for the cache and compare against just using the origin. Faster response times and less origin load, nice!


### Content Delivery Network

Introducing a Content Delivery Network (CDN) is another common strategy to improve client performance while decreasing load on the backend. We have not configured the CDN as part of this lab, so you need to configure Cloudfront before testing.

1\. Open the Cloudfront console, click Create Distribution, then Get Started under the Web heading

2\. Configure the Distribution by populating the Origin Domain Name field with the _**applicationLoadBalancerDns**_. The default configuration is suffecient for this workshop, scroll to the bottom of the page and click Create Distribuion. 

With this configuration, initial client requests to Cloudfront and cache misses will be fulfilled from the **_edgeCacheSpotFleet_**. If **_edgeCacheSpotFleet_** also cache misses, requests will finally be fulfilled by the origin.

3\. Now you're ready to test. SSH into one of the transcoding nodes

<pre>$ ssh -i <b><i>PRIVATE_KEY.PEM</i></b> ec2-user@<b><i>transcodingInstance</b></i></pre>

4\. When Jmeter is complete, you can access the results via a web browser

<pre>http://<b><i>transcodingInstanceIp</b></i>/results/cdn/</pre>

5\. Update the -Jhost flag to point to the Domain of the Cloudfront Distribution, found in the Cloudfront console under Domain Name.

{SCREENSHOT}

<pre>$ jmeter -n -t ~/lab.jmx -l cdn.txt -e -o cdn/ -Jhost <b><i>cloudfrontDistributionDns</b></i> -Jthreads=50 -Jrampup=15 -Jduration</pre>

6\. Note the average latency, percentiles, etc. and compare against the cache/origin results. Adding the CDN improved latency by a HUGE amount. The viewers will definitely appreciate these performance enhancements and the processing costs to serve all of them have decreased significantly. Win, win!

## Conclusion

We hope you enjoyed the workshop and are inspired fold these learnings into your own projects. Please submit any questions or issues to the github repo and we'll do our best to answer. 

## Extra Credit

* Use your own camera and RTMP capable encoder to contribute a source to the origin (beware bandwidth requirements)
* Setup a SNS email notification to notify you when VOD has completed processing
* Decrease overall live latency by tuning the HLS segment sizes
* Implement cubemap filter in VOD processing fleet to compare against live spherical projection
* Implement OAI so that only Cloudfront can access the origin/cache fleet


## Appendix
## Additional Resources and References
### Live Streaming Basics

### 360 Video Basics

### 360 Cameras

Ricoh Theta
insta360 one
insta360 ?

Bandwidth optimization and Quality
Adaptive Focus
HEVClive production, multi-camera, switching/editing (vremiere

https://code.facebook.com/posts/1126354007399553/next-generation-video-encoding-techniques-for-360-video-and-vr/
http://web.cecs.pdx.edu/~fliu/project/vremiere/

https://github.com/facebook/transform360 – ffmpeg cubemap
https://github.com/arut/nginx-rtmp-module – nginx rtmp

### TODO

- add webserver to transcoder for jmeter results
- move jmeter config to /home/ec2-user from /root/repo



