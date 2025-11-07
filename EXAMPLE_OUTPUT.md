# Example Output Structure

When you run the `autobuilder_v2.1.ps1` script, it creates a new repository with the following structure:

```
%USERPROFILE%\SuperRealityOS\super-reality-os-cloudroutes\
│
├── .github/
│   └── workflows/
│       └── validate.yml           # GitHub Actions workflow for shellcheck
│
├── aws/
│   ├── link_aws.sh                # Main AWS infrastructure provisioning script
│   └── README.md                  # AWS deployment documentation
│
├── .git/                          # Git repository (initialized automatically)
├── .gitignore                     # Git ignore rules
├── COPILOT_PROMPT.md             # Instructions for AI-assisted development
└── README.md                      # Main repository documentation
```

## File Contents

### 1. `.github/workflows/validate.yml`

```yaml
name: validate
on: { push: { branches: [ "main" ] } }
jobs:
  shellcheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install shellcheck
        run: sudo apt-get update && sudo apt-get install -y shellcheck
      - name: Lint link_aws.sh
        run: shellcheck aws/link_aws.sh
```

This workflow automatically validates the bash script syntax on every push to main.

### 2. `aws/link_aws.sh`

A complete, idempotent bash script (89 lines) that provisions:

**AWS Resources Created:**
- S3 Bucket: `sr-os-{account}-cloudroutes` 
  - Versioning enabled
  - AES256 encryption
- ECR Repository: `sr-os/core`
  - Image scanning on push
  - AES256 encryption
- IAM Role: `sr-os-ec2-ssm-role`
  - Policies: SSM, CloudWatch, ECR Read-Only
- IAM Instance Profile: `sr-os-ec2-ssm-profile`
- Security Group: `sr-os-sg` (egress-only)
- EC2 Instance: t3.large, Amazon Linux 2023
  - SSM-managed (no SSH)
  - Docker pre-installed
  - Tags: System=SuperRealityOS, Component=CloudRoutes, Owner=AlexLeBrun

**Key Features:**
- Idempotent: safe to run multiple times
- Region: ca-central-1 (configurable via REGION env var)
- Error handling with `set -euo pipefail`
- Helpful output messages

### 3. `aws/README.md`

```markdown
# Super Reality OS — CloudRoutes (AWS Link v1)
Region: ca-central-1

## CloudShell (recommended)
```bash
REGION=ca-central-1
curl -fsSL https://raw.githubusercontent.com/{user}/super-reality-os-cloudroutes/main/aws/link_aws.sh -o link_aws.sh && \
chmod +x link_aws.sh && ./link_aws.sh
```

## Local (if AWS CLI is authenticated)
```bash
chmod +x aws/link_aws.sh
./aws/link_aws.sh
```

Creates: S3 (versioned, encrypted), ECR, IAM Role+Profile, egress-only SG, EC2 t3.large (SSM-managed).
Tags: System=SuperRealityOS, Component=CloudRoutes, Owner=AlexLeBrun
```

### 4. `COPILOT_PROMPT.md`

```markdown
ROLE: Super Reality Architect DevOps Copilot. Repo=super-reality-os-cloudroutes (owner={user}). Cloud=AWS (ca-central-1).
GOAL: Maintain idempotent infra link and extend to multi-cloud on request—no follow-ups.

DO:
	1.	Keep aws/link_aws.sh as source-of-truth.
	2.	When extending, add Terraform + AWS CDK (TS) mirroring resources/tags.
	3.	Provide one-click run paths (CloudShell + local CLI) and update README.
	4.	Enforce tags: System=SuperRealityOS, Component=CloudRoutes, Owner=AlexLeBrun.
	5.	Prefer SSM over SSH; deny inbound by default.
OUTPUT: concise steps + exact commands.
```

This file provides context to GitHub Copilot for future development on the repository.

### 5. `.gitignore`

```
*.log
.DS_Store
```

### 6. Main `README.md`

Comprehensive documentation including:
- Overview of the CloudRoutes system
- Region information
- Usage instructions for CloudShell and local deployment
- List of AWS resources created
- Resource tags
- Connection instructions

## Automatic Actions

After creating all files, the script automatically:

1. **Initializes Git**: `git init`
2. **Stages all files**: `git add .`
3. **Creates commit**: `git commit -m "Super Reality OS — CloudRoutes AWS Link v1"`
4. **Sets main branch**: `git branch -M main`
5. **Adds remote**: Points to `https://github.com/{user}/super-reality-os-cloudroutes.git`
6. **Creates GitHub repo**: Uses `gh repo create` if it doesn't exist
7. **Pushes to GitHub**: `git push -u origin main`
8. **Opens CloudShell**: Launches AWS CloudShell in your browser
9. **Copies command**: Puts the deployment command on your clipboard

## Post-Execution

After the script completes:

1. Your browser opens to AWS CloudShell
2. Your clipboard contains the deployment command
3. Simply paste (Ctrl+V) in CloudShell and press Enter
4. AWS resources are provisioned automatically

## Example Session Output

```
✓ GitHub CLI authenticated as: your-username
✓ Created directory: C:\Users\YourName\SuperRealityOS\super-reality-os-cloudroutes
✓ Created folder structure
✓ Generated aws/link_aws.sh (89 lines)
✓ Generated aws/README.md
✓ Generated .github/workflows/validate.yml
✓ Generated COPILOT_PROMPT.md
✓ Generated .gitignore
✓ Git repository initialized
✓ Files committed
✓ Repository created on GitHub
✓ Pushed to origin/main

✅ Copied CloudShell command to clipboard.
▶ In CloudShell, paste (Ctrl+V) and press Enter to complete AWS link-up.

[AWS CloudShell opens in browser]
```

## Verification

You can verify the created repository at:
```
https://github.com/{your-username}/super-reality-os-cloudroutes
```

The GitHub Actions workflow will run automatically on the first push, validating the bash script with shellcheck.
