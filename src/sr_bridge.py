"""Bridge module for SR-HYBRID System inter-component communication."""

from typing import Any, Dict, Optional
from datetime import datetime

from .sr_logging import get_logger
from .sr_errors import BridgeError
from .sr_state import get_state_manager

logger = get_logger("bridge")


class Bridge:
    """Bridge for inter-component communication."""
    
    def __init__(self):
        self.state_manager = get_state_manager()
        self.message_count = 0
        logger.info("Bridge initialized")
    
    def send(
        self,
        source: str,
        destination: str,
        message: Dict[str, Any],
        metadata: Optional[dict] = None
    ) -> Dict[str, Any]:
        """
        Send a message from source to destination.
        
        Args:
            source: Source component
            destination: Destination component
            message: Message payload
            metadata: Optional metadata
        
        Returns:
            Message with envelope
        
        Raises:
            BridgeError: If send fails
        """
        try:
            self.message_count += 1
            
            envelope = {
                "id": f"msg_{self.message_count}",
                "source": source,
                "destination": destination,
                "timestamp": datetime.utcnow().isoformat(),
                "payload": message,
                "metadata": metadata or {}
            }
            
            # Store message in state
            self.state_manager.set(
                f"bridge:message:{envelope['id']}",
                envelope,
                metadata={"type": "bridge_message"}
            )
            
            logger.info(
                f"Message sent: {source} -> {destination} (id={envelope['id']})"
            )
            return envelope
            
        except Exception as e:
            logger.error(f"Bridge send failed: {e}")
            raise BridgeError(
                f"Failed to send message from {source} to {destination}: {e}",
                details={"source": source, "destination": destination, "error": str(e)}
            )
    
    def receive(self, message_id: str) -> Optional[Dict[str, Any]]:
        """
        Receive a message by ID.
        
        Args:
            message_id: Message ID to retrieve
        
        Returns:
            Message envelope or None if not found
        """
        message = self.state_manager.get(f"bridge:message:{message_id}")
        if message:
            logger.debug(f"Message received: {message_id}")
        else:
            logger.warning(f"Message not found: {message_id}")
        return message
    
    def get_message_count(self) -> int:
        """Get total number of messages sent."""
        return self.message_count


# Global bridge instance
_bridge: Optional[Bridge] = None


def get_bridge() -> Bridge:
    """Get the global bridge instance."""
    global _bridge
    if _bridge is None:
        _bridge = Bridge()
    return _bridge
