# Deep-Security-unified-ssm

## Day 1 Deployment: The day when EC2 will get created
  Using AWs Systems manager maintainance window

## Day 2 Deployment: DSA deployment in existing EC2 server
  Using  AWS Systems manager state manager or with cloudwatch event rule 
  


## Overview
This document is created for 2 diferent deploymnet functions which includes DSM manager deployment without multi tanency and Deep security as a service. SSM document also can be converted for DSM multitanency model. DSM deployment document is already published in AWS SSM document public repository.

Deployment document can be used in following automation scenarios
### Event driven agent deployment and activation using Cloudwatch rules
   This approach is useful when you wnat to activate EC2 instance everytime the state of instance changes to running. It can be used in EC2 systems manager state manager or by using Cloudwatch events rules. in any of the case it can make sure that agent will get activated and come to managed state. This feature is under development and script modification is required to prevent duplicate tasks.
    
### Systems manager maintainance window automation.
   This approach is useful when security is provided to EC2 owenr as a self service. EC2 owner can add the tag to EC2 server which can mark the server to deploy DSA and activate it during the maintainance window time line.
  
#### Steps to configure SSM maintainance window.
 
![alt text](https://github.com/tsheth/Deep-Security-unified-ssm/blob/master/git-snaps/1.PNG)

![alt text](https://github.com/tsheth/Deep-Security-unified-ssm/blob/master/git-snaps/2.PNG)

![alt text](https://github.com/tsheth/Deep-Security-unified-ssm/blob/master/git-snaps/3.PNG)

![alt text](https://github.com/tsheth/Deep-Security-unified-ssm/blob/master/git-snaps/4.PNG)

![alt text](https://github.com/tsheth/Deep-Security-unified-ssm/blob/master/git-snaps/5.PNG)

![alt text](https://github.com/tsheth/Deep-Security-unified-ssm/blob/master/git-snaps/6.PNG)

![alt text](https://github.com/tsheth/Deep-Security-unified-ssm/blob/master/git-snaps/7.PNG)

![alt text](https://github.com/tsheth/Deep-Security-unified-ssm/blob/master/git-snaps/8.PNG)

![alt text](https://github.com/tsheth/Deep-Security-unified-ssm/blob/master/git-snaps/9.PNG)

![alt text](https://github.com/tsheth/Deep-Security-unified-ssm/blob/master/git-snaps/10.PNG)




