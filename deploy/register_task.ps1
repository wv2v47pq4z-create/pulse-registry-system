# SR-OS AutoPost Remote Executor Node - Windows Task Scheduler Registration
# This PowerShell script registers a scheduled task for automated execution

param(
    [string]$InstallPath = $PSScriptRoot,
    [string]$IntervalMinutes = "60"
)

# Normalize install path
$InstallPath = (Resolve-Path "$InstallPath\..").Path

Write-Host "SR-OS AutoPost Task Registration" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Install Path: $InstallPath"
Write-Host "Interval: $IntervalMinutes minutes"
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Warning "This script should be run as Administrator for best results."
    Write-Host "Continuing with current user privileges..."
    Write-Host ""
}

# Load task XML template
$xmlPath = Join-Path $PSScriptRoot "sr-autopost-task.xml"
if (-not (Test-Path $xmlPath)) {
    Write-Error "Task XML template not found: $xmlPath"
    exit 1
}

$xmlContent = Get-Content $xmlPath -Raw
$xmlContent = $xmlContent -replace '%INSTALL_PATH%', $InstallPath

# Save modified XML to temp file
$tempXml = [System.IO.Path]::GetTempFileName()
$xmlContent | Out-File -FilePath $tempXml -Encoding UTF8

try {
    # Check if task already exists
    $taskName = "SR-OS AutoPost Client"
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    
    if ($existingTask) {
        Write-Host "Task '$taskName' already exists." -ForegroundColor Yellow
        $response = Read-Host "Do you want to replace it? (Y/N)"
        if ($response -ne "Y" -and $response -ne "y") {
            Write-Host "Registration cancelled." -ForegroundColor Yellow
            exit 0
        }
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Host "Existing task removed." -ForegroundColor Green
    }
    
    # Register the task
    Write-Host "Registering scheduled task..." -ForegroundColor Cyan
    Register-ScheduledTask -Xml (Get-Content $tempXml | Out-String) -TaskName $taskName -Force | Out-Null
    
    Write-Host ""
    Write-Host "SUCCESS: Task registered successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Task Details:" -ForegroundColor Cyan
    Write-Host "  Name: $taskName"
    Write-Host "  Trigger: Runs every $IntervalMinutes minutes"
    Write-Host "  Action: Executes autopost client in $InstallPath"
    Write-Host ""
    Write-Host "Management Commands:" -ForegroundColor Cyan
    Write-Host "  Start task:   Start-ScheduledTask -TaskName '$taskName'"
    Write-Host "  Stop task:    Stop-ScheduledTask -TaskName '$taskName'"
    Write-Host "  View status:  Get-ScheduledTask -TaskName '$taskName' | Get-ScheduledTaskInfo"
    Write-Host "  Unregister:   Unregister-ScheduledTask -TaskName '$taskName'"
    Write-Host ""
    
    # Optionally start the task immediately
    $runNow = Read-Host "Do you want to run the task now? (Y/N)"
    if ($runNow -eq "Y" -or $runNow -eq "y") {
        Write-Host "Starting task..." -ForegroundColor Cyan
        Start-ScheduledTask -TaskName $taskName
        Start-Sleep -Seconds 2
        $taskInfo = Get-ScheduledTask -TaskName $taskName | Get-ScheduledTaskInfo
        Write-Host "Task Status: $($taskInfo.LastTaskResult)" -ForegroundColor Green
    }
}
catch {
    Write-Error "Failed to register task: $_"
    exit 1
}
finally {
    # Clean up temp file
    if (Test-Path $tempXml) {
        Remove-Item $tempXml -Force
    }
}

Write-Host ""
Write-Host "Registration complete!" -ForegroundColor Green
