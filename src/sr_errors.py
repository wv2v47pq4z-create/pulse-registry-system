"""Error handling and custom exceptions for SR-HYBRID System."""

from typing import Optional


class SRError(Exception):
    """Base exception for SR-HYBRID system."""
    
    def __init__(self, message: str, details: Optional[dict] = None):
        super().__init__(message)
        self.message = message
        self.details = details or {}


class RecursionLimitError(SRError):
    """Raised when recursion depth limit is exceeded."""
    pass


class GroundingError(SRError):
    """Raised when grounding operation fails."""
    pass


class RoutingError(SRError):
    """Raised when routing operation fails."""
    pass


class BridgeError(SRError):
    """Raised when bridge operation fails."""
    pass


class ConflictError(SRError):
    """Raised when conflict resolution fails."""
    pass


class StateError(SRError):
    """Raised when state management fails."""
    pass


class AgentError(SRError):
    """Raised when agent operation fails."""
    pass
