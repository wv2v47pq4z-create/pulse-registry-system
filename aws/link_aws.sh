#!/usr/bin/env bash
set -euo pipefail
REGION="${REGION:-ca-central-1}"
PREFIX="${PREFIX:-sr-os}"
NAME_TAG="${NAME_TAG:-sr-os-node}"
EC2_TYPE="${EC2_TYPE:-t3.large}"
ECR_REPO="${ECR_REPO:-sr-os/core}"
SG_NAME="${SG_NAME:-sr-os-sg}"
ROLE_NAME="${ROLE_NAME:-sr-os-ec2-ssm-role}"
PROFILE_NAME="${PROFILE_NAME:-sr-os-ec2-ssm-profile}"
export AWS_DEFAULT_REGION="$REGION"
say(){ printf "\n==> %s\n" "$*"; }
acct="$(aws sts get-caller-identity --query Account --output text)"
say "Linking Super Reality OS to AWS account ${acct} in ${REGION}"

# S3
BUCKET="${PREFIX}-${acct}-cloudroutes"
if ! aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null ; then
  say "Creating S3 bucket s3://${BUCKET}"
  if [ "$REGION" = "us-east-1" ]; then aws s3api create-bucket --bucket "$BUCKET"
  else aws s3api create-bucket --bucket "$BUCKET" --create-bucket-configuration LocationConstraint="$REGION"; fi
  aws s3api put-bucket-versioning --bucket "$BUCKET" --versioning-configuration Status=Enabled
  aws s3api put-bucket-encryption --bucket "$BUCKET" --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
else say "S3 bucket exists: s3://${BUCKET}"; fi

# ECR
if ! aws ecr describe-repositories --repository-names "$ECR_REPO" >/dev/null 2>&1 ; then
  say "Creating ECR repo ${ECR_REPO}"
  aws ecr create-repository --repository-name "$ECR_REPO" --image-scanning-configuration scanOnPush=true --encryption-configuration encryptionType=AES256 >/dev/null
else say "ECR repo exists: ${ECR_REPO}"; fi

# IAM Role + Instance Profile (SSM)
ASSUME_ROLE_DOC='{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
if ! aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1 ; then
  say "Creating IAM role ${ROLE_NAME}"
  aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document "$ASSUME_ROLE_DOC" >/dev/null
  aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
  aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
  aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
else say "IAM role exists: ${ROLE_NAME}"; fi

if ! aws iam get-instance-profile --instance-profile-name "$PROFILE_NAME" >/dev/null 2>&1 ; then
  say "Creating Instance Profile ${PROFILE_NAME}"
  aws iam create-instance-profile --instance-profile-name "$PROFILE_NAME" >/dev/null
  if ! aws iam get-instance-profile --instance-profile-name "$PROFILE_NAME" --query "InstanceProfile.Roles[?RoleName=='${ROLE_NAME}']|[0]" --output text | grep -q "${ROLE_NAME}"; then
    aws iam add-role-to-instance-profile --instance-profile-name "$PROFILE_NAME" --role-name "$ROLE_NAME"
  fi
else say "Instance Profile exists: ${PROFILE_NAME}"; fi

# SG (egress-only)
VPC_ID="$(aws ec2 describe-vpcs --query "Vpcs[?IsDefault==\`true\`].VpcId" --output text)"; [ -z "$VPC_ID" ] || [ "$VPC_ID" = "None" ] && VPC_ID="$(aws ec2 describe-vpcs --query "Vpcs[0].VpcId" --output text)"
SG_ID="$(aws ec2 describe-security-groups --filters "Name=group-name,Values=${SG_NAME}" "Name=vpc-id,Values=${VPC_ID}" --query "SecurityGroups[0].GroupId" --output text 2>/dev/null || true)"
if [ -z "$SG_ID" ] || [ "$SG_ID" = "None" ]; then
  say "Creating Security Group ${SG_NAME} in ${VPC_ID}"
  SG_ID="$(aws ec2 create-security-group --group-name "$SG_NAME" --description "SuperRealityOS egress-only" --vpc-id "$VPC_ID" --query GroupId --output text)"
  aws ec2 revoke-security-group-egress --group-id "$SG_ID" --ip-permissions "[]" >/dev/null 2>&1 || true
  aws ec2 authorize-security-group-egress --group-id "$SG_ID" --ip-permissions '[{"IpProtocol":"-1","IpRanges":[{"CidrIp":"0.0.0.0/0"}]}]'
else say "Security Group exists: ${SG_NAME} (${SG_ID})"; fi

# EC2 (SSM-managed; no SSH)
AMI_ID="$(aws ssm get-parameters --names /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 --query "Parameters[0].Value" --output text)"
IID="$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${NAME_TAG}" "Name=instance-state-name,Values=pending,running,stopped" --query "Reservations[].Instances[0].InstanceId" --output text 2>/dev/null || true)"
if [ -z "$IID" ] || [ "$IID" = "None" ]; then
  say "Launching EC2 ${EC2_TYPE} with SSM role"
  SUBNET_ID="$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=${VPC_ID}" --query "Subnets[0].SubnetId" --output text)"
  PROFILE_ARN="$(aws iam get-instance-profile --instance-profile-name "$PROFILE_NAME" --query "InstanceProfile.Arn" --output text)"
  USERDATA=$(base64 -w0 <<'UD'
#!/bin/bash
set -e
dnf install -y docker
systemctl enable docker --now
UD
)
  IID="$(aws ec2 run-instances --image-id "$AMI_ID" --instance-type "$EC2_TYPE" --iam-instance-profile Arn="$PROFILE_ARN" --security-group-ids "$SG_ID" --subnet-id "$SUBNET_ID" --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${NAME_TAG}},{Key=System,Value=SuperRealityOS},{Key=Component,Value=CloudRoutes},{Key=Owner,Value=AlexLeBrun}]" --user-data "$USERDATA" --query "Instances[0].InstanceId" --output text)"
  say "Instance launched: ${IID}"
else say "EC2 instance already present: ${IID}"; fi

PUBLIC_IP="$(aws ec2 describe-instances --instance-ids "$IID" --query "Reservations[0].Instances[0].PublicIpAddress" --output text 2>/dev/null || true)"
say "Done. Resources:"
echo "  S3: s3://${BUCKET}"
echo "  ECR: ${ECR_REPO}"
echo "  IAM Role: ${ROLE_NAME} | Profile: ${PROFILE_NAME}"
echo "  SG: ${SG_NAME} (${SG_ID})"
echo "  EC2: ${IID} (${EC2_TYPE}) PublicIP=${PUBLIC_IP}"
echo "  Tags: System=SuperRealityOS, Component=CloudRoutes, Owner=AlexLeBrun"
say "SSM Managed instances (first 10):"
aws ssm describe-instance-information --max-results 10 --query "InstanceInformationList[].InstanceId" --output table || true
