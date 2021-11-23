# Setup aws tools and install ocp tools

Reference:
* [Installing or updating the latest version of the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
* [Configuration and credential file settings](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html) 

## install aws tools

```bash
<laptop>$ sudo -i 
<laptop># curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
<laptop># unzip awscli-bundle.zip
<laptop># ./awscli-bundle/install -i /usr/local/aws -b /bin/aws
<laptop># /bin/aws --version
<laptop># logout
<laptop>$ 
<laptop>$ mkdir $HOME/.aws
<laptop>$ export AWSKEY= <redacted>
<laptop>$ export AWSSECRETKEY= <redacted>
<laptop>$ export REGION=us-west-2
<laptop>$ cat << EOF >> $HOME/.aws/credentials
[default]
aws_access_key_id = ${AWSKEY}
aws_secret_access_key = ${AWSSECRETKEY}
region = $REGION
EOF
<laptop>$ 
<laptop>$ aws sts get-caller-identity
{
    "UserId": "<redacted>",
    "Account": "<redacted>",
    "Arn": "<redacted>"
}
<laptop>$ 
```

## install openshift-installer and oc tools

There is a small script called fetch.sh to be run as root, taking minor version and z-stream as an argument to fetch ```openshift-installer``` and ```oc``` direct from the mirror and put them into ```/usr/local/bin/```

```bash
<laptop>$ sudo tools/fetch.sh 8 18
minor is set to 8
z-stream is set to 18

verfying versions
Client Version: 4.8.18
openshift-install 4.8.18
built from commit bd366e3cdcf892e1bddd841c702738f5254a0188
release image quay.io/openshift-release-dev/ocp-release@sha256:321aae3d3748c589bc2011062cee9fd14e106f258807dc2d84ced3f7461160ea
<laptop>$ 
```


Next step is [creating install-config.yaml and deploying the cluster](Create_install-config.yaml_and_deploy_cluster.md)
