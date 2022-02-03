#!/bin/bash

# This script performs below tasks
# 1. Create pipeline  # Not available in MVP
# 2. Create launch constraint roles across all accounts using SERVICE MANAGED PERMISSIONS
# 3. Create Service Catalog portfolio/products for DEV and PROD environments and share with the organization


S3RootURL="https://s3.amazonaws.com/vinjak-outbox"
S3RootURL="https://vinjak-outbox.s3.us-east-2.amazonaws.com"
ParamValue="${S3RootURL}/aws-custom-sc-pipeline/"
LcLocURL="${ParamValue}/templates/lc_roles"
SCDevPortURL="${ParamValue}/templates/dev-portfolio"
SCDevPrdURL="${ParamValue}/templates/dev-portfolio/sc_products"
SCProdPortURL="${ParamValue}/templates/prod-portfolio"
SCProdPrdURL="${ParamValue}/templates/prod-portfolio/sc_products"
AWS_REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
ROOT_ID=$(aws organizations list-roots --query 'Roots[0].Id' --output text) # manually enter this value if this script is not executed in management account.
ORG_ID=$(aws organizations describe-organization --query Organization.Id --output text) # manually enter this value if this script is not executed in management account.


echo "Step-2: Creating launch constraint roles with SERVICE MANAGED PERMISSIONS"

aws cloudformation create-stack-set --stack-set-name SC-LCROLES-EC2VPC --template-url "${LcLocURL}/sc-ec2vpc-launchrole.yml" --permission-model SERVICE_MANAGED --auto-deployment Enabled=true,RetainStacksOnAccountRemoval=true --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM
aws cloudformation create-stack-instances --stack-set-name SC-LCROLES-EC2VPC --deployment-targets OrganizationalUnitIds=${ROOT_ID} --regions "${AWS_REGION}"

aws cloudformation create-stack-set --stack-set-name SC-LCROLES-RDS --template-url "${LcLocURL}/sc-rds-launchrole.yml" --permission-model SERVICE_MANAGED --auto-deployment Enabled=true,RetainStacksOnAccountRemoval=true --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM
aws cloudformation create-stack-instances --stack-set-name SC-LCROLES-RDS --deployment-targets OrganizationalUnitIds=${ROOT_ID} --regions "${AWS_REGION}"

aws cloudformation create-stack --stack-name SC-LCROLES-EC2VPC --template-url "${LcLocURL}/sc-ec2vpc-launchrole.yml" 
aws cloudformation wait stack-create-complete --stack-name SC-LCROLES-EC2VPC

aws cloudformation create-stack --stack-name SC-LCROLES-RDS --template-url "${LcLocURL}/sc-rds-launchrole.yml" 
aws cloudformation wait stack-create-complete --stack-name SC-LCROLES-RDS


echo "Step-3: Create Service Catalog portfolio/products for DEV and PROD envs"
s_name=SC-DEV-Portfolio
aws cloudformation create-stack --stack-name ${s_name} --template-url  "${SCDevPortURL}/sc-dev-portfolio.yml" --parameters "[{\"ParameterKey\":\"OrgId\",\"ParameterValue\":\"${ORG_ID}\"}]" --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND
echo "waiting for stack ${s_name} to complete..."
aws cloudformation wait stack-create-complete --stack-name ${s_name}

s_name=SC-DEV-EC2-Product
aws cloudformation create-stack --stack-name ${s_name} --template-url  "${SCDevPrdURL}/sc-dev-product-ec2-linux.json" --parameters "[{\"ParameterKey\":\"RepoRootURL\",\"ParameterValue\":\"$ParamValue\"}]" --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND
echo "waiting for stack ${s_name} to complete..."
aws cloudformation wait stack-create-complete --stack-name ${s_name}

#s_name=SC-DEV-VPC-Product
#aws cloudformation create-stack --stack-name ${s_name} --template-url  "${S3RootURL}/templates/dev-portfolio/sc_products/sc-dev-product-vpc-ra.json" --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND
#echo "waiting for stack ${s_name} to complete..."
#aws cloudformation wait stack-create-complete --stack-name ${s_name}

s_name=SC-DEV-MYSQL-Product
aws cloudformation create-stack --stack-name ${s_name} --template-url  "${SCDevPrdURL}/sc-dev-product-mysql-ra.json" --parameters "[{\"ParameterKey\":\"RepoRootURL\",\"ParameterValue\":\"$ParamValue\"}]" --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND
echo "waiting for stack ${s_name} to complete..."
aws cloudformation wait stack-create-complete --stack-name ${s_name}
