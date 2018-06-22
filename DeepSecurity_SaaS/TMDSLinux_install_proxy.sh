#!/bin/bash

# Numeric value relates to a named policy in the Trend Micro console.
# This policy, if using a forward proxy, must reflect the proxy for
# access to Trend Micro's Global Smart Protecion Network.
POLICYID=''

# Forward proxy agents should use for access to the Internet.
PROXY='' # IP_Address:Port_Number

# TenantID and Token should be constants for the organization.
TENANTID=''
TOKEN=''

SOURCEURL='https://app.deepsecurity.trendmicro.com:443'

# Source: https://help.deepsecurity.trendmicro.com/software.html
# Desc: Deep Security Agent 10.0.0-2797 for amzn2-x86_64
# Update: 10.0_U10
# File: Agent-amzn2-10.0.0-2797.x86_64.zip
URL_MAIN_RELEASE='https://files.trendmicro.com/products/deepsecurity/en/10.0/Agent-amzn2-10.0.0-2797.x86_64.zip'

FLAG_MAIN_RELEASE=0 # flag to indicate if main release should be used

CMD_AgentReset="/opt/ds_agent/dsa_control -r"
CMD_DSA_SetProxy=""
CMD_Relay_SetProxy=""
CMD_ActivateAgent=""


#####################################################################
download_latest() {
  echo "Downloading from \"feature release\" branch..."

  if [ -n "$PROXY" ]; then
    # proxy is TRUE
    CURL_AgentPackage="curl -x http://$PROXY $SOURCEURL/software/deploymentscript/platform/linux-secure/ -o   /tmp/DownloadInstallAgentPackage --silent --tlsv1"

    CMD_DSA_SetProxy="/opt/ds_agent/dsa_control -x dsm_proxy://$PROXY/"

    CMD_Relay_SetProxy="/opt/ds_agent/dsa_control -y relay_proxy://$PROXY/"

    # create a different global CURL variable
    CURL="curl -x http://$PROXY "

  else
    # proxy is FALSE
    CURL_AgentPackage="curl $SOURCEURL/software/deploymentscript/platform/linux-secure/ -o  /tmp/DownloadInstallAgentPackage --silent --tlsv1"
  fi


  if type curl >/dev/null 2>&1; then
    echo "Downloading agent installation script..."
    echo $CURL_AgentPackage
    $CURL_AgentPackage
    err=$?
    echo ""

    if [[ $err -eq 60 ]]; then
       echo "TLS certificate validation for the agent package download has failed. Please check that your Deep  Security Manager TLS certificate is signed by a trusted root certificate authority. For more information,  search for \"deployment scripts\" in the Deep Security Help Center."
       logger -t TLS certificate validation for the agent package download has failed. Please check that your Deep  Security Manager TLS certificate is signed by a trusted root certificate authority. For more information,  search for \"deployment scripts\" in the Deep Security Help Center.
       exit 2;
    fi

    if [ -s /tmp/DownloadInstallAgentPackage ]; then
      # Added to support download of agent softare via forward proxy
      if [ -n "$PROXY" ]; then
        echo "Reconfiguring DownloadInstallAgentPackage to support proxy..."
        sed -i 's/^CURL=/#CURL=/g' /tmp/DownloadInstallAgentPackage
      fi

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

  # Test to ensure agent installation script executed properly.
  if [ ! -f /opt/ds_agent/dsa_control ]; then
    echo "Failed to execute the agent installation script."
    logger -t Failed to execute agent installation script
    false
  fi

  sleep 15
}


#####################################################################
download_main() {
  # Should only be used for 10.0 release of the agent to
  # support Amazon Linux v2 AMI.  Once 11.0 is released,
  # should no longer need this function.
  echo "Downloading from \"main\" branch..."

  if [ -n "$PROXY" ]; then
    # proxy is TRUE
    CURL_AgentPackage="curl -x http://$PROXY $URL_MAIN_RELEASE -o /tmp/dsa_agent.zip --silent --tlsv1"
    CMD_DSA_SetProxy="/opt/ds_agent/dsa_control -x dsm_proxy://$PROXY/"
    CMD_Relay_SetProxy="/opt/ds_agent/dsa_control -y relay_proxy://$PROXY/"
  else
    # proxy is FALSE
    CURL_AgentPackage="curl $URL_MAIN_RELEASE -o /tmp/dsa_agent.zip --silent --tlsv1"
  fi

  # confirm that cURL is installed
  type curl >/dev/null 2>&1;
  if [ $? -ne 0 ]; then
    echo "Please install CURL before running this script."
    logger -t Please install CURL before running this script
    exit 1
  fi

  echo "Downloading agent .zip bundle..."
  echo $CURL_AgentPackage
  $CURL_AgentPackage
  echo ""

  err=$?

  if [[ $err -eq 60 ]]; then
     echo "TLS certificate validation for the agent package download has failed. Please check that your Deep Security Manager TLS certificate is signed by a trusted root certificate authority. For more information, search for \"deployment scripts\" in the Deep Security Help Center."
     logger -t TLS certificate validation for the agent package download has failed. Please check that your Deep Security Manager TLS certificate is signed by a trusted root certificate authority. For more information, search for \"deployment scripts\" in the Deep Security Help Center.
     exit 2;
  fi

  if [ ! -s /tmp/dsa_agent.zip ]; then
    echo "Failed to download the agent installation bundle."
    logger -t Failed to download the Deep Security Agent installation bundle
    exit 1;
  fi

  # remove folder if already exists
  if [ -d /tmp/dsa_agent ]; then
    rm -rf /tmp/dsa_agent
  fi

  echo "Extracting .zip bundle..."
  unzip -o /tmp/dsa_agent.zip -d /tmp/dsa_agent > /dev/null 2>&1
  RPM_BUNDLE=`ls /tmp/dsa_agent/*.rpm`

  # exit if rpm cannot be found
  if [ ! -s $RPM_BUNDLE ]; then
    echo "Unable to locate .rpm bundle, exiting."
    exit 1;
  fi

  echo "Installing .rpm bundle..."
  rpm -ihv $RPM_BUNDLE

  # Test to ensure rpm installed correctly properly.
  if [ ! -s /opt/ds_agent/dsa_control ]; then
    echo "Failed to execute the agent installation script."
    logger -t Failed to execute agent installation script
    exit 1;
  fi

  sleep 15
}


#####################################################################
activate_agent() {
  echo "Activating the agent..."

  # Reset the agent if previously deployed.
  echo "Resetting the agent..."
  echo $CMD_AgentReset
  $CMD_AgentReset
  echo ""

  # If proxy present, configure agent to use the proxy.
  if [ -n "$PROXY" ]; then
    echo "Configuring agent proxy settings..."
    echo $CMD_DSA_SetProxy
    $CMD_DSA_SetProxy
    echo ""

    echo "Configuring relay proxy settings..."
    echo $CMD_Relay_SetProxy
    $CMD_Relay_SetProxy
    echo ""
  fi

  echo "Activating agent..."
  echo $CMD_ActivateAgent
  eval $CMD_ActivateAgent
  echo ""

  echo "Done"
}


#####################################################################
# Main Function
#

# determine if running as root
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  err_msg=`echo "$0 error, root priveleges required."`
  echo $err_msg
  logger -t $err_msg
  exit 1
fi

if [ "$#" -lt 3 ]; then
  printf "%s: insufficient arguments (%d).\n" $0 $#
  exit 1
fi

TENANTID=$1
TOKEN=$2
POLICYID=$3

CMD_ActivateAgent="/opt/ds_agent/dsa_control -a dsm://agents.deepsecurity.trendmicro.com:443/   \"tenantID:$1\" \"token:$2\" \"policyid:$3\""

if [ "$#" -eq 4 ]; then
  PROXY=$4
fi

# determine if running Amazon Linux release 2
if [ -s /etc/system-release ]; then
  cat /etc/system-release | grep -o "^Amazon Linux release 2" > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "Amazon Linux v2 detected..."
    FLAG_MAIN_RELEASE=1
  fi
fi

# download an rpm and install it
if [ $FLAG_MAIN_RELEASE -eq 0 ]; then
  download_latest
else
  download_main
fi

# activate the agent
activate_agent#!/usr/bin/env bash