#!/bin/bash

 #Install pip
 curl -O https://bootstrap.pypa.io/get-pip.py
 python get-pip.py --user
 ls -a ~
 export PATH=~/.local/bin:$PATH
 source ~/.bash_profile
 pip --version

 #install aws cli
 pip install awscli --upgrade --user
 aws --version


#Get Temp Credentials, Role name at end must be the same as the Intsance profile attached to EC2
 #role_name=$( curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/ )
 #curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/${role_name}
 #
 #access=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$role_name | awk '/AccessKeyId/ {print $3}' | sed 's/[^0-9A-Z]*//g' )
 #echo $access
 #secret=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$role_name | awk '/SecretAccessKey/ {print $3}' | sed 's/[^0-9A-Za-z/+=]*//g')
 #echo $secret
 #
 #aws configure set aws_access_key_id $access
 #aws configure set aws_secret_access_key $secret
 aws configure set region us-east-1


#Make the TMDS dir and download the required scripts for this execution
 mkdir /tmp/TMDS
 cd /tmp/TMDS
 curl -LO https://s3.amazonaws.com/tmds-scripts/Install-TMDSLinux.sh
 curl -LO https://s3.amazonaws.com/tmds-scripts/parse.py


#AWS CLI command to get parameters from parameter store
 params=$(aws ssm get-parameters-by-path --path /TMDS/)
 echo ${params}

#Call python script to parse the parameter store json file and returns just the parameter values in order of TenantID, Token, and LinuxPolicyID and store in tmds parameter
 tmds=$(python ./parse.py "$params")
 echo ${tmds}

#Parse the tmds varible into 3 separate parameters
 tenant=$(echo ${tmds} | cut -d "," -f 1)
 echo ${tenant}

 token=$(echo ${tmds} | cut -d "," -f 2)
 echo ${token}

 policy=$(echo ${tmds} | cut -d "," -f 3)
 echo ${policy}

#Run the install script with arguments

execute="sh ./Install-TMDSLinux.sh ${tenant} ${token} ${policy}"
echo $execute
sudo ${execute}