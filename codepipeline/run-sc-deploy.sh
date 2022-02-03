#!/bin/bash
shopt -s nullglob
echo `pwd`


ASTR=$((aws cloudformation update-stack --stack-name SC-DEV-Portfolio --template-url  "https://$DEPLOY_BUCKET.s3.amazonaws.com/templates/dev-portfolio/sc-dev-portfolio.yml" --parameters '[{"ParameterKey":"OrgId","UsePreviousValue":true}]' --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND) 2>&1)
ACODE=$?
if [[ "$ACODE" -eq "255" && "$ASTR" =~ .(No updates are to be performed\.)$ ]]
then 
  echo "No updates, continue."
elif [[ "$ACODE" -eq "0" ]]
then
  echo "Stack update in progress"
else
  echo "$ACODE $ASTR"
  touch FAILED
fi

ASTR=$((aws cloudformation update-stack --stack-name SC-DEV-EC2-Product --template-url  "https://$DEPLOY_BUCKET.s3.amazonaws.com/templates/dev-portfolio/sc_products/sc-dev-product-ec2-linux.json" --parameters '[{"ParameterKey":"RepoRootURL","UsePreviousValue":true}]' --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND) 2>&1)
ACODE=$?
if [[ "$ACODE" -eq "255" && "$ASTR" =~ .(No updates are to be performed\.)$ ]]
then 
  echo "No updates, continue."
elif [[ "$ACODE" -eq "0" ]]
then
  echo "Stack update in progress"
else
  echo "$ACODE $ASTR"
  touch FAILED
fi

ASTR=$((aws cloudformation update-stack --stack-name SC-DEV-MYSQL-Product --template-url  "https://$DEPLOY_BUCKET.s3.amazonaws.com/templates/dev-portfolio/sc_products/sc-dev-product-mysql-ra.json" --parameters '[{"ParameterKey":"RepoRootURL","UsePreviousValue":true}]' --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND) 2>&1)
ACODE=$?
if [[ "$ACODE" -eq "255" && "$ASTR" =~ .(No updates are to be performed\.)$ ]]
then 
  echo "No updates, continue."
elif [[ "$ACODE" -eq "0" ]]
then
  echo "Stack update in progress"
else
  echo "$ACODE $ASTR"
  touch FAILED
fi

if [ -e FAILED ]; then
  echo Deploy FAILED at least once!
  exit 1
else
  echo Deploy completed!
  exit 0
fi
