# Super Reality OS — CloudRoutes (AWS Link v1)

Region: ca-central-1

## CloudShell (recommended)

```bash
REGION=ca-central-1
curl -fsSL https://raw.githubusercontent.com/wv2v47pq4z-create/pulse-registry-system/main/aws/link_aws.sh -o link_aws.sh && \
chmod +x link_aws.sh && ./link_aws.sh
```

## Local (if AWS CLI is authenticated)

```bash
chmod +x aws/link_aws.sh
./aws/link_aws.sh
```

## What it creates

- **S3 bucket**: versioned and encrypted for CloudRoutes storage
- **ECR repository**: for container images with scan-on-push enabled
- **IAM Role + Instance Profile**: SSM-managed access for EC2 instances
- **Security Group**: egress-only (no inbound SSH)
- **EC2 instance**: t3.large with SSM management (no SSH keys required)

## Resource tags

All resources are tagged with:
- System=SuperRealityOS
- Component=CloudRoutes
- Owner=AlexLeBrun

## Features

- **Idempotent**: Safe to run multiple times
- **Secure by default**: No SSH access, SSM-only management
- **Encrypted**: S3 and ECR use encryption at rest
- **Versioned**: S3 bucket versioning enabled
