#!/usr/bin/env python3
"""
SR-OS AutoPost Remote Executor Node - Heartbeat Monitor

This script performs health checks and can be used for monitoring
the autopost client's operational status.

Usage:
    python heartbeat.py [--config CONFIG_PATH]
"""

import sys
import json
import argparse
from pathlib import Path
from datetime import datetime, timezone, timedelta

# Check Python version
if sys.version_info < (3, 10):
    print("ERROR: Python 3.10 or higher is required")
    sys.exit(1)


class HeartbeatMonitor:
    """Monitor the health and status of the autopost client"""
    
    def __init__(self, config_path: str = "config.json"):
        self.config_path = Path(config_path)
        self.config = self._load_config()
        self.status = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "healthy": True,
            "checks": []
        }
    
    def _load_config(self) -> dict:
        """Load configuration"""
        if not self.config_path.exists():
            example_config = Path("config.example.json")
            if example_config.exists():
                with open(example_config, 'r') as f:
                    return json.load(f)
        
        try:
            with open(self.config_path, 'r') as f:
                return json.load(f)
        except Exception as e:
            return {}
    
    def check(self, name: str, passed: bool, message: str) -> None:
        """Record a check result"""
        self.status["checks"].append({
            "name": name,
            "passed": passed,
            "message": message
        })
        if not passed:
            self.status["healthy"] = False
    
    def check_python_version(self) -> None:
        """Check Python version"""
        version = sys.version_info
        required = (3, 10)
        passed = version >= required
        self.check(
            "python_version",
            passed,
            f"Python {version.major}.{version.minor}.{version.micro}" + 
            ("" if passed else f" (requires {required[0]}.{required[1]}+)")
        )
    
    def check_dependencies(self) -> None:
        """Check required dependencies"""
        try:
            import requests
            self.check("dependencies", True, f"requests {requests.__version__}")
        except ImportError:
            self.check("dependencies", False, "requests library not installed")
    
    def check_configuration(self) -> None:
        """Check configuration file"""
        if not self.config:
            self.check("configuration", False, "config.json not found or invalid")
            return
        
        required_keys = ["api_url", "api_key", "watch_folder"]
        missing = [k for k in required_keys if k not in self.config]
        
        if missing:
            self.check("configuration", False, f"Missing keys: {', '.join(missing)}")
        else:
            self.check("configuration", True, "All required keys present")
    
    def check_watch_folder(self) -> None:
        """Check watch folder exists"""
        watch_folder = Path(self.config.get("watch_folder", "./watch_folder"))
        
        if watch_folder.exists():
            file_count = sum(1 for _ in watch_folder.rglob("*") if _.is_file())
            self.check("watch_folder", True, f"Exists with {file_count} files")
        else:
            self.check("watch_folder", False, f"Does not exist: {watch_folder}")
    
    def check_logs_directory(self) -> None:
        """Check logs directory"""
        log_file = Path(self.config.get("log_file", "./logs/autopost_status.jsonl"))
        log_dir = log_file.parent
        
        if log_dir.exists():
            if log_file.exists():
                with open(log_file, 'r') as f:
                    lines = sum(1 for _ in f)
                self.check("logs", True, f"{lines} log entries")
            else:
                self.check("logs", True, "Directory exists, no logs yet")
        else:
            self.check("logs", False, f"Directory does not exist: {log_dir}")
    
    def check_tracking_file(self) -> None:
        """Check posted files tracking"""
        tracking_file = Path("posted_files.json")
        
        if tracking_file.exists():
            try:
                with open(tracking_file, 'r') as f:
                    data = json.load(f)
                count = len(data)
                self.check("tracking", True, f"{count} files tracked")
            except json.JSONDecodeError:
                self.check("tracking", False, "Invalid JSON in posted_files.json")
        else:
            self.check("tracking", True, "No tracking file yet (will be created)")
    
    def check_recent_activity(self) -> None:
        """Check for recent activity in logs"""
        log_file = Path(self.config.get("log_file", "./logs/autopost_status.jsonl"))
        
        if not log_file.exists():
            self.check("recent_activity", True, "No activity yet")
            return
        
        try:
            # Read last line
            with open(log_file, 'r') as f:
                lines = f.readlines()
            
            if not lines:
                self.check("recent_activity", True, "No activity yet")
                return
            
            last_entry = json.loads(lines[-1])
            last_time = datetime.fromisoformat(last_entry["timestamp"].replace('Z', '+00:00'))
            age = datetime.now(timezone.utc) - last_time
            
            # Consider activity recent if within 24 hours
            if age < timedelta(hours=24):
                self.check("recent_activity", True, f"Last activity: {age.seconds // 3600}h {(age.seconds // 60) % 60}m ago")
            else:
                self.check("recent_activity", False, f"Last activity: {age.days} days ago")
        
        except Exception as e:
            self.check("recent_activity", False, f"Could not parse logs: {e}")
    
    def run_all_checks(self) -> dict:
        """Run all health checks"""
        self.check_python_version()
        self.check_dependencies()
        self.check_configuration()
        self.check_watch_folder()
        self.check_logs_directory()
        self.check_tracking_file()
        self.check_recent_activity()
        
        return self.status
    
    def print_status(self) -> None:
        """Print status in human-readable format"""
        print("SR-OS AutoPost Heartbeat Monitor")
        print("=" * 40)
        print(f"Timestamp: {self.status['timestamp']}")
        print(f"Overall Status: {'✓ HEALTHY' if self.status['healthy'] else '✗ UNHEALTHY'}")
        print()
        
        for check in self.status["checks"]:
            symbol = "✓" if check["passed"] else "✗"
            print(f"{symbol} {check['name']}: {check['message']}")
        
        print()
        print("=" * 40)
        
        if self.status["healthy"]:
            print("All checks passed!")
            return 0
        else:
            print("Some checks failed - review above for details")
            return 1


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="SR-OS AutoPost Heartbeat Monitor"
    )
    parser.add_argument(
        "--config",
        default="config.json",
        help="Path to configuration file"
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output as JSON instead of human-readable format"
    )
    
    args = parser.parse_args()
    
    monitor = HeartbeatMonitor(config_path=args.config)
    status = monitor.run_all_checks()
    
    if args.json:
        print(json.dumps(status, indent=2))
        return 0 if status["healthy"] else 1
    else:
        return monitor.print_status()


if __name__ == "__main__":
    sys.exit(main())
