# W.I.P 360-degree live streaming on AWS

# Overview




# Requirements

* AWS account - if you don't have one, it's easy and free to create one
* AWS IAM account with elevated privileges allowing you to interact with CloudFormation, IAM, EC2, ECS, S3, Cloudwatch, and Cloudfront
* A workstation or laptop with an ssh client installed, such as putty on Windows or terminal or iterm on Mac
* Familiarity with Bash, ffmpeg, nginx, and video processing

# Labs

The labs in this directory are designed to be completed in sequential order. If you're attending an AWS event, your host will give you an overview of the technology and expectations for each lab. If you're following along at home, we've provided the presentation materials as a pdf. Feel free to open issue tickets on the repo if you have questions.

_Lab 1_

# Conventions

# Cleanup and Disclaimer

# Lab 1

In this lab we will build a basic live streaming system using open source software. From this basic system we will be able to view a 360-degree live stream coming from a camera, but more importantly, we can use it as the basis to build in best-practices and introduce new features later in this workshop.

Because on-site internet bandwidth can be a challenge, the first thing we want to do is set up a reliable test source

Camera -> Encoder -> Origin <-> Client
Test Source /


# Lab 2

Camera -> Encoder -> Origin <-> CDN <-> Client


# Lab 3

Camera -> Encoder -> Origin <-> CDN <-> Client
             |
            S3 (VOD)