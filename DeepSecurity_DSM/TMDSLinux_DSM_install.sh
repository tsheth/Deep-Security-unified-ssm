#!/bin/bash
# This script detects platform and architecture, then downloads and installs the matching Deep Security Agent package
 if [[ $(/usr/bin/id -u) -ne 0 ]]; then echo You are not running as the root user.  Please try again with root privileges.;
    logger -t You are not running as the root user.  Please try again with root privileges.;
    exit 1;
 fi;
 if type curl >/dev/null 2>&1; then
  SOURCEURL="https://$1:443"
  curl $SOURCEURL/software/deploymentscript/platform/linux/ -o /tmp/DownloadInstallAgentPackage --insecure --silent --tlsv1.2

  if [ -s /tmp/DownloadInstallAgentPackage ]; then
      . /tmp/DownloadInstallAgentPackage
      Download_Install_Agent
  else
     echo "Failed to download the agent installation script."
     logger -t Failed to download the Deep Security Agent installation script
     false
  fi
 else 
  echo "Please install CURL before running this script."
  logger -t Please install CURL before running this script
  false
 fi
sleep 15
/opt/ds_agent/dsa_control -r
/opt/ds_agent/dsa_control -a dsm://$1:4120/ "policyid:$2"