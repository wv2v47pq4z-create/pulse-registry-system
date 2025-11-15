#!/usr/bin/env python3
"""
SR-OS AutoPost Remote Executor Node Client

A Python-based automation tool that monitors a local folder and POSTs file
contents to a remote SR-OS API endpoint with idempotency tracking.

Usage:
    python autopost_client.py run   - Execute normal operation
    python autopost_client.py test  - Send dry-run test payload

Requirements: Python 3.10+
"""

import sys
import os
import json
import base64
import hashlib
import socket
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import argparse

# Check Python version
if sys.version_info < (3, 10):
    print("ERROR: Python 3.10 or higher is required")
    sys.exit(1)

try:
    import requests
except ImportError:
    print("ERROR: 'requests' library not found. Install with: pip install -r requirements.txt")
    sys.exit(1)


class AutoPostClient:
    """Main client for SR-OS AutoPost functionality"""
    
    def __init__(self, config_path: str = "config.json"):
        self.config_path = config_path
        self.config = self._load_config()
        self.posted_files_path = Path("posted_files.json")
        self.posted_files = self._load_posted_files()
        self.stats = {
            "found": 0,
            "posted": 0,
            "skipped": 0,
            "errors": 0
        }
        
    def _load_config(self) -> dict:
        """Load configuration from config.json, create from example if needed"""
        config_file = Path(self.config_path)
        example_config = Path("config.example.json")
        
        # Create config.json from example if it doesn't exist
        if not config_file.exists():
            if example_config.exists():
                import shutil
                shutil.copy(example_config, config_file)
                self.log("INFO", f"Created {self.config_path} from {example_config}")
            else:
                self.log("ERROR", f"Neither {self.config_path} nor {example_config} found")
                sys.exit(1)
        
        try:
            with open(config_file, 'r') as f:
                config = json.load(f)
            self.log("INFO", f"Configuration loaded from {self.config_path}")
            return config
        except json.JSONDecodeError as e:
            self.log("ERROR", f"Invalid JSON in {self.config_path}: {e}")
            sys.exit(1)
        except Exception as e:
            self.log("ERROR", f"Failed to load {self.config_path}: {e}")
            sys.exit(1)
    
    def _load_posted_files(self) -> dict:
        """Load tracking data of previously posted files"""
        if not self.posted_files_path.exists():
            return {}
        
        try:
            with open(self.posted_files_path, 'r') as f:
                return json.load(f)
        except json.JSONDecodeError:
            self.log("WARNING", f"Invalid JSON in {self.posted_files_path}, starting fresh")
            return {}
        except Exception as e:
            self.log("WARNING", f"Could not load {self.posted_files_path}: {e}")
            return {}
    
    def _save_posted_files(self) -> None:
        """Save tracking data of posted files"""
        try:
            with open(self.posted_files_path, 'w') as f:
                json.dump(self.posted_files, f, indent=2)
        except Exception as e:
            self.log("ERROR", f"Failed to save {self.posted_files_path}: {e}")
    
    def log(self, level: str, message: str, **kwargs) -> None:
        """Log message to console and JSONL file"""
        timestamp = datetime.now(timezone.utc).isoformat()
        
        # Console output
        console_msg = f"[{timestamp}] {level}: {message}"
        print(console_msg)
        
        # JSONL file output
        if self.config.get("enable_logging", True):
            log_file = Path(self.config.get("log_file", "./logs/autopost_status.jsonl"))
            log_file.parent.mkdir(parents=True, exist_ok=True)
            
            log_entry = {
                "timestamp": timestamp,
                "level": level,
                "message": message,
                **kwargs
            }
            
            try:
                with open(log_file, 'a') as f:
                    f.write(json.dumps(log_entry) + '\n')
            except Exception as e:
                print(f"[{timestamp}] WARNING: Failed to write to log file: {e}")
    
    def get_hostname(self) -> str:
        """Get system hostname for node identification"""
        try:
            return socket.gethostname()
        except:
            return "unknown-host"
    
    def calculate_sha256(self, content: bytes) -> str:
        """Calculate SHA256 hash of content"""
        return hashlib.sha256(content).hexdigest()
    
    def build_payload(self, file_path: Path, content: bytes) -> dict:
        """Build POST payload according to specification"""
        relative_path = str(file_path.relative_to(Path.cwd()))
        
        payload = {
            "node_id": f"autopost-node-{self.get_hostname()}",
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "file_path": relative_path.replace("\\", "/"),  # Normalize path separators
            "file_name": file_path.name,
            "file_content": base64.b64encode(content).decode('utf-8'),
            "file_size_bytes": len(content),
            "file_hash_sha256": self.calculate_sha256(content)
        }
        
        return payload
    
    def scan_files(self) -> List[Path]:
        """Recursively scan watch_folder for matching files"""
        watch_folder = Path(self.config.get("watch_folder", "./watch_folder"))
        
        if not watch_folder.exists():
            self.log("WARNING", f"Watch folder does not exist: {watch_folder}")
            return []
        
        file_extensions = self.config.get("file_extensions", [])
        max_size_mb = self.config.get("max_file_size_mb", 10)
        max_size_bytes = max_size_mb * 1024 * 1024
        
        matching_files = []
        
        for file_path in watch_folder.rglob("*"):
            if not file_path.is_file():
                continue
            
            # Check extension
            if file_extensions and file_path.suffix not in file_extensions:
                continue
            
            # Check size
            try:
                file_size = file_path.stat().st_size
                if file_size > max_size_bytes:
                    self.log("WARNING", f"File too large, skipping: {file_path} ({file_size / 1024 / 1024:.2f} MB)")
                    continue
            except Exception as e:
                self.log("WARNING", f"Could not stat file {file_path}: {e}")
                continue
            
            matching_files.append(file_path)
        
        return matching_files
    
    def post_file(self, file_path: Path) -> Tuple[bool, Optional[int], Optional[str]]:
        """POST a single file to the API endpoint"""
        try:
            # Read file content
            with open(file_path, 'rb') as f:
                content = f.read()
            
            # Build payload
            payload = self.build_payload(file_path, content)
            
            # Prepare headers
            headers = {
                "Content-Type": "application/json",
            }
            
            api_key = self.config.get("api_key")
            if api_key:
                headers["Authorization"] = f"Bearer {api_key}"
            
            # Make POST request
            api_url = self.config.get("api_url")
            response = requests.post(api_url, json=payload, headers=headers, timeout=30)
            
            # Check response
            if response.status_code in [200, 201, 202]:
                return True, response.status_code, None
            else:
                return False, response.status_code, f"{response.status_code} {response.reason}"
                
        except requests.exceptions.RequestException as e:
            return False, None, str(e)
        except Exception as e:
            return False, None, str(e)
    
    def run(self) -> int:
        """Execute normal operation - scan and post files"""
        self.log("INFO", "Starting SR-OS AutoPost Client (run mode)")
        
        # Scan for files
        watch_folder = Path(self.config.get("watch_folder", "./watch_folder"))
        self.log("INFO", f"Scanning watch_folder: {watch_folder}")
        
        files = self.scan_files()
        self.stats["found"] = len(files)
        self.log("INFO", f"Found {len(files)} files matching extensions")
        
        # Process each file
        for file_path in files:
            relative_path = str(file_path.relative_to(Path.cwd())).replace("\\", "/")
            
            # Check if already posted
            if relative_path in self.posted_files:
                self.log("INFO", f"Skipping already posted file: {relative_path}")
                self.stats["skipped"] += 1
                continue
            
            # Get file size for logging
            try:
                file_size = file_path.stat().st_size
                size_str = f"{file_size / 1024:.1f} KB" if file_size < 1024 * 1024 else f"{file_size / 1024 / 1024:.1f} MB"
            except:
                size_str = "unknown size"
            
            self.log("INFO", f"Processing file: {relative_path} ({size_str})")
            
            # POST file
            success, status_code, error = self.post_file(file_path)
            
            if success:
                self.log("SUCCESS", f"Posted {relative_path} (response: {status_code})", 
                        file=relative_path, status=status_code)
                
                # Track posted file
                self.posted_files[relative_path] = {
                    "posted_at": datetime.now(timezone.utc).isoformat(),
                    "file_hash": self.calculate_sha256(file_path.read_bytes()),
                    "status": "success"
                }
                self.stats["posted"] += 1
            else:
                error_msg = error or "Unknown error"
                self.log("ERROR", f"Failed to post {relative_path} (error: {error_msg})",
                        file=relative_path, error=error_msg)
                self.stats["errors"] += 1
        
        # Save tracking data
        self._save_posted_files()
        
        # Log summary
        self.log("INFO", 
                f"Summary - Found: {self.stats['found']}, "
                f"Posted: {self.stats['posted']}, "
                f"Skipped: {self.stats['skipped']}, "
                f"Errors: {self.stats['errors']}")
        
        return 0 if self.stats["errors"] == 0 else 1
    
    def test(self) -> int:
        """Send a dry-run test payload"""
        self.log("INFO", "Starting SR-OS AutoPost Client (test mode)")
        
        # Create test payload
        test_content = b"This is a test payload from SR-OS AutoPost Client"
        test_payload = {
            "node_id": f"autopost-node-{self.get_hostname()}",
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "file_path": "test/sample.txt",
            "file_name": "sample.txt",
            "file_content": base64.b64encode(test_content).decode('utf-8'),
            "file_size_bytes": len(test_content),
            "file_hash_sha256": self.calculate_sha256(test_content)
        }
        
        # Prepare headers
        headers = {
            "Content-Type": "application/json",
        }
        
        api_key = self.config.get("api_key")
        if api_key:
            headers["Authorization"] = f"Bearer {api_key}"
        
        # Make POST request
        try:
            api_url = self.config.get("api_url")
            self.log("INFO", f"Sending test payload to: {api_url}")
            
            response = requests.post(api_url, json=test_payload, headers=headers, timeout=30)
            
            if response.status_code in [200, 201, 202]:
                self.log("SUCCESS", f"Test payload sent successfully (response: {response.status_code})")
                return 0
            else:
                self.log("ERROR", f"Test failed with status: {response.status_code} {response.reason}")
                return 1
                
        except requests.exceptions.RequestException as e:
            self.log("ERROR", f"Test failed with error: {e}")
            return 1
        except Exception as e:
            self.log("ERROR", f"Unexpected error during test: {e}")
            return 1


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="SR-OS AutoPost Remote Executor Node Client",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "command",
        choices=["run", "test"],
        help="Command to execute: 'run' for normal operation, 'test' for dry-run"
    )
    parser.add_argument(
        "--config",
        default="config.json",
        help="Path to configuration file (default: config.json)"
    )
    
    args = parser.parse_args()
    
    try:
        client = AutoPostClient(config_path=args.config)
        
        if args.command == "run":
            return client.run()
        elif args.command == "test":
            return client.test()
        else:
            print(f"ERROR: Unknown command: {args.command}")
            return 1
            
    except KeyboardInterrupt:
        print("\nInterrupted by user")
        return 130
    except Exception as e:
        print(f"FATAL ERROR: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
