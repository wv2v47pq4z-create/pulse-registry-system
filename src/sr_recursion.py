"""Recursion guard and depth tracking for SR-HYBRID System."""

import threading
from typing import Optional
from contextlib import contextmanager

from .sr_logging import get_logger
from .sr_errors import RecursionLimitError

logger = get_logger("recursion")


class RecursionGuard:
    """Thread-safe recursion depth tracking and limiting."""
    
    def __init__(self, max_depth: int = 100):
        self.max_depth = max_depth
        self._depth = threading.local()
        self._lock = threading.Lock()
        logger.info(f"RecursionGuard initialized with max_depth={max_depth}")
    
    @property
    def depth(self) -> int:
        """Get current recursion depth for this thread."""
        return getattr(self._depth, "value", 0)
    
    @depth.setter
    def depth(self, value: int) -> None:
        """Set recursion depth for this thread."""
        self._depth.value = value
    
    @contextmanager
    def track(self, operation: str = "operation"):
        """
        Context manager to track recursion depth.
        
        Args:
            operation: Name of the operation being tracked
        
        Raises:
            RecursionLimitError: If max depth is exceeded
        """
        current_depth = self.depth
        
        if current_depth >= self.max_depth:
            logger.error(
                f"Recursion limit exceeded: {current_depth} >= {self.max_depth} "
                f"for operation '{operation}'"
            )
            raise RecursionLimitError(
                f"Maximum recursion depth ({self.max_depth}) exceeded",
                details={"operation": operation, "depth": current_depth}
            )
        
        self.depth = current_depth + 1
        logger.debug(f"Recursion depth: {self.depth} for '{operation}'")
        
        try:
            yield self.depth
        finally:
            self.depth = current_depth
            logger.debug(f"Recursion depth restored: {self.depth} for '{operation}'")
    
    def reset(self) -> None:
        """Reset recursion depth for current thread."""
        self.depth = 0
        logger.debug("Recursion depth reset")


# Global recursion guard instance
_recursion_guard: Optional[RecursionGuard] = None


def get_recursion_guard(max_depth: int = 100) -> RecursionGuard:
    """Get the global recursion guard instance."""
    global _recursion_guard
    if _recursion_guard is None:
        _recursion_guard = RecursionGuard(max_depth=max_depth)
    return _recursion_guard
