# Setup Scripts

This directory contains automation scripts for setting up and managing related projects from the inkonchain ecosystem.

## setup-ink-web-app.ps1

A Windows PowerShell automation script for setting up the [inkonchain/ink-web-app](https://github.com/inkonchain/ink-web-app) project.

## setup-ink-kit.ps1

A Windows PowerShell automation script for setting up the [inkonchain/ink-kit](https://github.com/inkonchain/ink-kit) project.

### Prerequisites

- Windows operating system
- PowerShell 5.1 or later
- Git for Windows
- Either:
  - [nvm-windows](https://github.com/coreybutler/nvm-windows/releases) (recommended), or
  - Node.js v20 installed directly

### Common Features (Both Scripts)

Both scripts share the same features and usage patterns:

- Automatically checks and switches to Node.js v20 using nvm-windows (if available)
- Enables Corepack and activates pnpm@9.12.1
- Clones the repository (if not already present)
- Sets up environment variables from `.env.example`
- Installs dependencies with pnpm
- Runs development server or builds for production

### Usage

#### Run development server (default):

```powershell
# For ink-web-app
.\scripts\setup-ink-web-app.ps1

# For ink-kit
.\scripts\setup-ink-kit.ps1
```

Or explicitly:

```powershell
.\scripts\setup-ink-web-app.ps1 -Action dev
.\scripts\setup-ink-kit.ps1 -Action dev
```

#### Build and run production server:

```powershell
.\scripts\setup-ink-web-app.ps1 -Action build
.\scripts\setup-ink-kit.ps1 -Action build
```

#### Custom repository or branch:

```powershell
.\scripts\setup-ink-web-app.ps1 -RepoUrl "https://github.com/your-fork/ink-web-app.git" -Branch "feature-branch"
.\scripts\setup-ink-kit.ps1 -RepoUrl "https://github.com/your-fork/ink-kit.git" -Branch "feature-branch"
```

### Parameters

- **Action**: `dev` (default) or `build`
  - `dev`: Runs the development server (`pnpm dev`)
  - `build`: Builds for production and starts the server (`pnpm build && pnpm start`)

- **RepoUrl**: Repository URL to clone
  - Default for ink-web-app: `https://github.com/inkonchain/ink-web-app.git`
  - Default for ink-kit: `https://github.com/inkonchain/ink-kit.git`

- **Branch**: Branch or commit to checkout after cloning (default: `main`)

### What the script does

1. **Node.js Setup**: Checks for Node.js v20. If not found or wrong version:
   - Attempts to use nvm-windows to install/switch to Node 20
   - Prompts user to install Node 20 manually if nvm is not available

2. **pnpm Setup**: Ensures pnpm is available:
   - Checks if pnpm is already installed
   - Tries to enable it via corepack
   - Falls back to global npm install if needed

3. **Repository Setup**: 
   - Clones the repository (if not present)
   - Checks out specified branch
   - Copies `.env.example` to `.env.local` (if present)

4. **Dependencies**: Runs `pnpm install`

5. **Run**: Starts development server or builds production bundle based on the `Action` parameter

### Exit Codes

- `0`: Success
- `2`: Node 20 setup failed
- `3`: pnpm setup failed
- `10`: Other runtime errors

### Notes

- The script will skip cloning if the repository directory already exists
- Existing `.env.local` files are preserved and not overwritten
- For production builds, Node memory is increased to 8GB (`--max_old_space_size=8192`)
- Run PowerShell as a normal user; admin rights are only needed for system-level tool installations

### Troubleshooting

**Node not found**: Install [nvm-windows](https://github.com/coreybutler/nvm-windows/releases) or [Node.js v20](https://nodejs.org/en/download/)

**Git not found**: Install [Git for Windows](https://git-scm.com/download/win)

**Permission errors**: Run PowerShell as administrator only if installing system tools; otherwise run as normal user

**pnpm install fails**: Check your internet connection and ensure Node.js is working correctly
