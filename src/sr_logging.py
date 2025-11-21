"""Centralized logging configuration for SR-HYBRID System."""

import logging
import os
import sys
from typing import Optional


def setup_logging(level: Optional[str] = None) -> logging.Logger:
    """
    Configure centralized logging for the SR-HYBRID system.
    
    Args:
        level: Log level (DEBUG, INFO, WARNING, ERROR, CRITICAL).
               If None, uses SR_LOG_LEVEL env var or defaults to INFO.
    
    Returns:
        Configured logger instance
    """
    log_level = level or os.getenv("SR_LOG_LEVEL", "INFO").upper()
    
    # Configure root logger
    logging.basicConfig(
        level=getattr(logging, log_level),
        format="%(asctime)s - %(levelname)s - %(name)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        handlers=[
            logging.StreamHandler(sys.stdout)
        ]
    )
    
    logger = logging.getLogger("sr_hybrid")
    logger.setLevel(getattr(logging, log_level))
    
    # Optional file logging
    log_dir = os.getenv("SR_LOG_DIR", "/app/logs")
    if os.path.exists(log_dir) or os.getenv("SR_LOG_FILE_ENABLED", "false").lower() == "true":
        try:
            os.makedirs(log_dir, exist_ok=True)
            file_handler = logging.FileHandler(os.path.join(log_dir, "sr_hybrid.log"))
            file_handler.setFormatter(
                logging.Formatter("%(asctime)s - %(levelname)s - %(name)s - %(message)s")
            )
            logger.addHandler(file_handler)
        except (OSError, PermissionError) as e:
            logger.warning(f"Could not set up file logging: {e}")
    
    return logger


def get_logger(name: str) -> logging.Logger:
    """Get a logger for a specific module."""
    return logging.getLogger(f"sr_hybrid.{name}")
