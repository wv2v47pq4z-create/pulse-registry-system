# SR-OS AutoPost Remote Executor Node - Build Deployment Package (Windows)
# Creates a ZIP file with all necessary files for deployment

param(
    [string]$OutputPath = "sr-autopost-deploy.zip"
)

$ErrorActionPreference = "Stop"

# Change to project root
Set-Location (Split-Path $PSScriptRoot -Parent)

Write-Host "SR-OS AutoPost Deployment Package Builder" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Create temporary build directory
$BuildDir = Join-Path $env:TEMP "sr-autopost-build-$(Get-Random)"
Write-Host "Creating build directory: $BuildDir"
New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null

try {
    # Copy files
    Write-Host "Copying files..." -ForegroundColor Cyan
    
    $filesToCopy = @(
        "autopost_client.py",
        "config.example.json",
        "posted_files.json",
        "requirements.txt",
        "README.md",
        "CONTRIBUTING.md",
        "MASTER_PROMPT.md",
        "COPILOT_AUTOPOST_AGENT.md"
    )
    
    foreach ($file in $filesToCopy) {
        if (Test-Path $file) {
            Copy-Item $file -Destination $BuildDir
            Write-Host "  ✓ $file"
        }
    }
    
    # Copy LICENSE if exists
    if (Test-Path "LICENSE") {
        Copy-Item "LICENSE" -Destination $BuildDir
        Write-Host "  ✓ LICENSE"
    }
    
    # Copy directories
    Write-Host "Copying directories..." -ForegroundColor Cyan
    
    $dirsToCopy = @("deploy", "scripts")
    
    foreach ($dir in $dirsToCopy) {
        if (Test-Path $dir) {
            Copy-Item $dir -Destination $BuildDir -Recurse
            Write-Host "  ✓ $dir/"
        }
    }
    
    # Copy tests if exists
    if (Test-Path "tests") {
        Copy-Item "tests" -Destination $BuildDir -Recurse
        Write-Host "  ✓ tests/"
    }
    
    # Create logs directory
    $logsDir = Join-Path $BuildDir "logs"
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
    New-Item -ItemType File -Path (Join-Path $logsDir "autopost_status.jsonl") -Force | Out-Null
    Write-Host "  ✓ logs/"
    
    # Copy .github/workflows if exists
    if (Test-Path ".github/workflows") {
        $githubDir = Join-Path $BuildDir ".github"
        New-Item -ItemType Directory -Path $githubDir -Force | Out-Null
        Copy-Item ".github/workflows" -Destination $githubDir -Recurse
        Write-Host "  ✓ .github/workflows/"
    }
    
    # Create ZIP archive
    Write-Host ""
    Write-Host "Creating ZIP archive..." -ForegroundColor Cyan
    
    if (Test-Path $OutputPath) {
        Remove-Item $OutputPath -Force
    }
    
    Compress-Archive -Path "$BuildDir\*" -DestinationPath $OutputPath -CompressionLevel Optimal
    
    Write-Host ""
    Write-Host "✓ Package created: $OutputPath" -ForegroundColor Green
    Write-Host ""
    
    # Show package details
    $zipInfo = Get-Item $OutputPath
    $sizeKB = [math]::Round($zipInfo.Length / 1KB, 2)
    $sizeMB = [math]::Round($zipInfo.Length / 1MB, 2)
    
    Write-Host "Package Details:" -ForegroundColor Cyan
    Write-Host "  Path: $($zipInfo.FullName)"
    Write-Host "  Size: $sizeKB KB ($sizeMB MB)"
    Write-Host "  Created: $($zipInfo.CreationTime)"
    Write-Host ""
    
    # Show some contents
    Write-Host "Package Contents (first 20 items):" -ForegroundColor Cyan
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipInfo.FullName)
    $entries = $zip.Entries | Select-Object -First 20
    foreach ($entry in $entries) {
        Write-Host "  $($entry.FullName)"
    }
    if ($zip.Entries.Count -gt 20) {
        Write-Host "  ... and $($zip.Entries.Count - 20) more files"
    }
    $zip.Dispose()
    
    Write-Host ""
    Write-Host "Done!" -ForegroundColor Green
}
catch {
    Write-Error "Failed to create package: $_"
    exit 1
}
finally {
    # Clean up build directory
    if (Test-Path $BuildDir) {
        Remove-Item $BuildDir -Recurse -Force
    }
}
