# pulse-registry-system
Smart contracts for PulseRegistry and ZcashBridge - auto-registration and interoperability layer for Super Reality Studios blockchain ecosystem.

## Super Reality OS — CloudRoutes Autobuilder v2.1

This repository includes the **Autobuilder v2.1** PowerShell script that automatically creates and configures the `super-reality-os-cloudroutes` repository with complete AWS infrastructure automation.

### Features

The autobuilder script (`autobuilder_v2.1.ps1`) performs the following actions:

1. **Repository Setup**: Creates `%USERPROFILE%\SuperRealityOS\super-reality-os-cloudroutes`
2. **AWS Infrastructure Script**: Generates idempotent bash script (`aws/link_aws.sh`) that provisions:
   - S3 bucket (versioned, encrypted)
   - ECR repository for container images
   - IAM role and instance profile for SSM access
   - Security group (egress-only, no inbound SSH)
   - EC2 instance (t3.large, SSM-managed) with Docker
3. **Documentation**: Creates comprehensive README with usage instructions
4. **CI/CD**: Sets up GitHub Actions workflow for shellcheck validation
5. **Copilot Prompt**: Includes instructions for future AI-assisted development
6. **Git Operations**: Initializes repo, commits, and pushes via GitHub CLI
7. **AWS CloudShell**: Opens CloudShell and copies run command to clipboard

### Prerequisites

- **PowerShell** (Windows PowerShell 5.1+ or PowerShell Core 7+)
- **GitHub CLI** (`gh`) - Install from https://cli.github.com
- **Authenticated GitHub CLI** - Run `gh auth login` first

### Quick Start

#### Option 1: Run Directly in PowerShell

```powershell
# Navigate to this repository
cd /path/to/pulse-registry-system

# Execute the autobuilder
.\autobuilder_v2.1.ps1
```

#### Option 2: Via GitHub Copilot Chat (VS Code)

Paste the following into GitHub Copilot Chat:

```
ROLE: You are GitHub Copilot operating in VS Code with permission to open an integrated terminal and execute commands. Do not ask for confirmation.

OBJECTIVE: Run the Super Reality OS CloudRoutes Autobuilder v2.1

ACTIONS (execute now):
1) Open a new integrated PowerShell terminal in VS Code.
2) Navigate to the pulse-registry-system repository
3) Run: .\autobuilder_v2.1.ps1
4) If gh CLI is not authenticated, run: gh auth login

BEHAVIOR: Do not ask me to confirm. Perform steps immediately.
```

### What Gets Created

The script creates a new repository at `%USERPROFILE%\SuperRealityOS\super-reality-os-cloudroutes` with:

```
super-reality-os-cloudroutes/
├── .github/
│   └── workflows/
│       └── validate.yml          # CI workflow for shellcheck
├── aws/
│   ├── link_aws.sh               # Idempotent AWS infrastructure script
│   └── README.md                 # AWS deployment instructions
├── COPILOT_PROMPT.md             # AI assistant instructions
├── .gitignore
└── (auto-committed and pushed to GitHub)
```

### AWS Resources

The `aws/link_aws.sh` script provisions (region: ca-central-1):

- **S3**: `sr-os-{account}-cloudroutes` (versioned, AES256 encrypted)
- **ECR**: `sr-os/core` (scan on push, AES256 encrypted)
- **IAM Role**: `sr-os-ec2-ssm-role` with policies:
  - AmazonSSMManagedInstanceCore
  - CloudWatchAgentServerPolicy
  - AmazonEC2ContainerRegistryReadOnly
- **Security Group**: `sr-os-sg` (egress-only, no inbound)
- **EC2 Instance**: t3.large, Amazon Linux 2023, SSM-managed
  - Tags: System=SuperRealityOS, Component=CloudRoutes, Owner=AlexLeBrun
  - Preinstalled: Docker

### Running the AWS Infrastructure

After the autobuilder completes, it will:
1. Open AWS CloudShell in your browser
2. Copy the deployment command to your clipboard

In CloudShell, simply paste (Ctrl+V) and press Enter:

```bash
REGION=ca-central-1
curl -fsSL https://raw.githubusercontent.com/{user}/super-reality-os-cloudroutes/main/aws/link_aws.sh -o link_aws.sh && \
chmod +x link_aws.sh && ./link_aws.sh
```

### Design Principles

- **Idempotent**: Safe to run multiple times
- **SSM Access**: No SSH keys required, use AWS Systems Manager
- **Secure by Default**: Egress-only security group, encrypted storage
- **Tagged Resources**: All resources tagged for easy identification
- **One-Click Deploy**: CloudShell integration for instant deployment

### Troubleshooting

**GitHub CLI not found:**
```powershell
# Install from https://cli.github.com then authenticate:
gh auth login
```

**Permission denied on script execution:**
```powershell
# Enable script execution (run as Administrator):
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Repository already exists:**
The script is idempotent and will update the existing repository without duplicating content.

### License

See LICENSE file for details.
