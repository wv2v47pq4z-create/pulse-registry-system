<#
.SYNOPSIS
  Automates setup for inkonchain/ink-web-app on Windows PowerShell.

.DESCRIPTION
  - Checks Node version and tries to switch to Node 20 using nvm (nvm-windows) if available.
  - Enables Corepack and activates pnpm@9.12.1 (falls back to npm global install if needed).
  - Clones the repository (if not present).
  - Copies .env.example to .env.local (if present).
  - Runs pnpm install.
  - Starts dev server (pnpm dev) or builds for production (pnpm build && pnpm start).

.PARAMETER Action
  'dev' (default) to run pnpm dev, or 'build' to build & start the production server.

.PARAMETER RepoUrl
  Repo URL to clone. Default: https://github.com/inkonchain/ink-web-app.git

.PARAMETER Branch
  Branch or commit to checkout after cloning (default: main)

.NOTES
  - Script will prompt you to manually install Node 20 if neither Node nor nvm is present.
  - Run PowerShell as normal user for most steps; admin required only for installing system tools.
#>

param(
    [ValidateSet("dev","build")]
    [string]$Action = "dev",

    [string]$RepoUrl = "https://github.com/inkonchain/ink-web-app.git",

    [string]$Branch = "main"
)

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = (Get-Date).ToString("u")
    Write-Host "[$ts] [$Level] $Message"
}

function Command-Exists {
    param([string]$cmd)
    $null -ne (Get-Command $cmd -ErrorAction SilentlyContinue)
}

function Get-Node-Major {
    try {
        $v = (& node -v 2>$null)
        if (-not $v) { return $null }
        if ($v -match '^v([0-9]+)') { return [int]$matches[1] }
        return $null
    } catch {
        return $null
    }
}

function Ensure-Node20 {
    $nodeMajor = Get-Node-Major
    if ($nodeMajor -eq 20) {
        Write-Log "Node 20 detected."
        return $true
    } elseif ($nodeMajor -ne $null) {
        Write-Log "Node version detected: $nodeMajor (not 20). Attempting to use nvm if available." "WARN"
    } else {
        Write-Log "Node not found." "WARN"
    }

    if (Command-Exists nvm) {
        Write-Log "nvm detected. Installing/using Node 20 via nvm..."
        & nvm install 20.0.0 | Out-Null
        & nvm use 20.0.0 | Out-Null
        Start-Sleep -Seconds 1
        $nodeMajor = Get-Node-Major
        if ($nodeMajor -eq 20) {
            Write-Log "Switched to Node 20 via nvm."
            return $true
        } else {
            Write-Log "Failed to switch to Node 20 via nvm." "ERROR"
            return $false
        }
    } else {
        Write-Log "nvm not found. Please install nvm-windows or Node 20 manually and re-run the script." "ERROR"
        Write-Host ""
        Write-Host "Options:"
        Write-Host " - Install nvm-windows from https://github.com/coreybutler/nvm-windows/releases (recommended)"
        Write-Host " - Or install Node 20 using the Windows installer: https://nodejs.org/en/download/"
        Write-Host ""
        return $false
    }
}

function Ensure-Pnpm {
    if (Command-Exists pnpm) {
        $pv = (& pnpm -v) -split '\r?\n' | Select-Object -First 1
        Write-Log "pnpm detected (version $pv)."
        return $true
    }

    if (Command-Exists corepack) {
        Write-Log "Enabling corepack and preparing pnpm@9.12.1..."
        try {
            & corepack enable
            & corepack prepare pnpm@9.12.1 --activate
            Start-Sleep -Seconds 1
            if (Command-Exists pnpm) {
                Write-Log "pnpm activated via corepack."
                return $true
            }
        } catch {
            Write-Log "corepack prepare failed: $_" "WARN"
        }
    }

    Write-Log "Attempting to install pnpm globally with npm..."
    if (Command-Exists npm) {
        & npm i -g pnpm@9.12.1
        if (Command-Exists pnpm) {
            Write-Log "pnpm installed via npm."
            return $true
        } else {
            Write-Log "pnpm global install failed or pnpm not on PATH." "ERROR"
            return $false
        }
    } else {
        Write-Log "npm not found. Can't install pnpm." "ERROR"
        return $false
    }
}

function Clone-Repo {
    param([string]$url, [string]$branch)
    $name = [System.IO.Path]::GetFileNameWithoutExtension($url)
    if (Test-Path $name) {
        Write-Log "Directory '$name' already exists. Skipping clone."
        Set-Location $name
        if ($branch) {
            Write-Log "Trying to checkout branch/commit: $branch"
            if (Command-Exists git) { & git fetch --all; & git checkout $branch } else { Write-Log "git not found, cannot checkout." "WARN" }
        }
        return $name
    }

    if (-not (Command-Exists git)) {
        Write-Log "git is not installed. Please install git and re-run." "ERROR"
        throw "git-not-found"
    }

    Write-Log "Cloning $url ..."
    & git clone $url
    if ($LASTEXITCODE -ne 0) {
        Write-Log "git clone failed." "ERROR"
        throw "git-clone-failed"
    }
    Set-Location $name
    if ($branch) {
        Write-Log "Checking out $branch"
        & git checkout $branch
    }
    return $name
}

function Setup-Env {
    if (Test-Path ".env.local") {
        Write-Log ".env.local already exists. Leaving it unchanged."
        return
    }
    if (Test-Path ".env.example") {
        Write-Log "Copying .env.example to .env.local"
        Copy-Item -Path ".env.example" -Destination ".env.local"
        Write-Log "Copied. Please edit .env.local to fill required values."
    } else {
        Write-Log ".env.example not found. Skipping env setup." "WARN"
    }
}

function Install-Dependencies {
    Write-Log "Installing dependencies with pnpm..."
    & pnpm install
    if ($LASTEXITCODE -ne 0) {
        Write-Log "pnpm install failed." "ERROR"
        throw "pnpm-install-failed"
    }
    Write-Log "Dependencies installed."
}

function Run-Action {
    param([string]$action)
    if ($action -eq "dev") {
        Write-Log "Starting development server (pnpm dev). Use Ctrl+C to stop."
        & pnpm dev
    } else {
        Write-Log "Building production bundle (increasing Node memory) then starting."
        $env:NODE_OPTIONS="--max_old_space_size=8192"
        & pnpm build
        if ($LASTEXITCODE -ne 0) {
            Write-Log "pnpm build failed." "ERROR"
            throw "build-failed"
        }
        & pnpm start
    }
}

# Main
try {
    Write-Log "Starting automation script. Action=$Action, RepoUrl=$RepoUrl, Branch=$Branch"

    # Ensure Node 20
    if (-not (Ensure-Node20)) {
        Write-Log "Cannot continue without Node 20. Exiting." "ERROR"
        exit 2
    }

    # Ensure pnpm 9.12.1
    if (-not (Ensure-Pnpm)) {
        Write-Log "pnpm setup failed. Exiting." "ERROR"
        exit 3
    }

    # Clone repo
    $proj = Clone-Repo -url $RepoUrl -branch $Branch

    # Setup .env
    Setup-Env

    # Install deps
    Install-Dependencies

    # Run selected action
    Run-Action -action $Action

} catch {
    Write-Log "Script failed: $_" "ERROR"
    exit 10
}
