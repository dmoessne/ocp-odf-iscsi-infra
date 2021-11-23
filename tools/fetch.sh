#!/bin/bash
if [ -z "$1" ]
then
      echo "setting minor to 8"
      minor="8"
else
      echo "minor is set to ${1}"
      minor=${1}
fi
if [ -z "$2" ]
then
      echo "setting zstream to 0"
      zstream="0"
else
      echo "z-stream is set to ${2}"
      zstream=${2}
fi
CL_URL="https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.${minor}.${zstream}/openshift-client-linux-4.${minor}.${zstream}.tar.gz"
IN_URL="https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.${minor}.${zstream}/openshift-install-linux-4.${minor}.${zstream}.tar.gz"
#echo $CL_URL
#echo $IN_URL
wget -qO - ${CL_URL}  |sudo tar xfz - -C /usr/local/bin/ oc kubectl
wget -qO - ${IN_URL}  |sudo tar xfz - -C /usr/local/bin/ openshift-install
echo
echo "verfying versions"
oc version
openshift-install version
