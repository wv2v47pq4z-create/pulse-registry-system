@echo off
REM SR-OS AutoPost Remote Executor Node - Windows Launcher
REM This script launches the autopost client with proper environment setup

cd /d "%~dp0.."

REM Check Python installation
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python not found. Please install Python 3.10 or higher.
    exit /b 1
)

REM Check Python version
python -c "import sys; exit(0 if sys.version_info >= (3, 10) else 1)" >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python 3.10 or higher is required.
    python --version
    exit /b 1
)

REM Check dependencies
python -c "import requests" >nul 2>&1
if errorlevel 1 (
    echo ERROR: Dependencies not installed. Running pip install...
    python -m pip install -r requirements.txt
    if errorlevel 1 (
        echo ERROR: Failed to install dependencies.
        exit /b 1
    )
)

REM Run the client
echo Starting SR-OS AutoPost Client...
python autopost_client.py run

exit /b %errorlevel%
