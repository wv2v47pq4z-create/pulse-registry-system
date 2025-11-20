"""State management for SR-HYBRID System."""

from typing import Any, Dict, Optional
import threading
from datetime import datetime

from .sr_logging import get_logger
from .sr_errors import StateError

logger = get_logger("state")


class StateManager:
    """Thread-safe state management for the SR-HYBRID system."""
    
    def __init__(self):
        self._state: Dict[str, Any] = {}
        self._lock = threading.RLock()
        self._metadata: Dict[str, dict] = {}
        logger.info("StateManager initialized")
    
    def set(self, key: str, value: Any, metadata: Optional[dict] = None) -> None:
        """
        Set a state value with optional metadata.
        
        Args:
            key: State key
            value: State value
            metadata: Optional metadata about the state
        """
        with self._lock:
            self._state[key] = value
            self._metadata[key] = metadata or {}
            self._metadata[key]["updated_at"] = datetime.utcnow().isoformat()
            logger.debug(f"State set: {key} = {value}")
    
    def get(self, key: str, default: Any = None) -> Any:
        """
        Get a state value.
        
        Args:
            key: State key
            default: Default value if key doesn't exist
        
        Returns:
            State value or default
        """
        with self._lock:
            value = self._state.get(key, default)
            logger.debug(f"State get: {key} = {value}")
            return value
    
    def delete(self, key: str) -> None:
        """Delete a state value."""
        with self._lock:
            if key in self._state:
                del self._state[key]
                if key in self._metadata:
                    del self._metadata[key]
                logger.debug(f"State deleted: {key}")
    
    def clear(self) -> None:
        """Clear all state."""
        with self._lock:
            self._state.clear()
            self._metadata.clear()
            logger.info("State cleared")
    
    def get_all(self) -> Dict[str, Any]:
        """Get all state as a dictionary."""
        with self._lock:
            return self._state.copy()
    
    def get_metadata(self, key: str) -> dict:
        """Get metadata for a state key."""
        with self._lock:
            return self._metadata.get(key, {}).copy()


# Global state manager instance
_state_manager: Optional[StateManager] = None


def get_state_manager() -> StateManager:
    """Get the global state manager instance."""
    global _state_manager
    if _state_manager is None:
        _state_manager = StateManager()
    return _state_manager
