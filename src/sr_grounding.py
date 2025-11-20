"""Grounding logic for SR-HYBRID System."""

from typing import Any, Dict, Optional
from datetime import datetime

from .sr_logging import get_logger
from .sr_errors import GroundingError
from .sr_state import get_state_manager

logger = get_logger("grounding")


class GroundingEngine:
    """Grounding engine for stabilizing agent outputs."""
    
    def __init__(self):
        self.state_manager = get_state_manager()
        self.grounding_count = 0
        logger.info("GroundingEngine initialized")
    
    def ground(self, data: Dict[str, Any], context: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Ground data with context to ensure consistency.
        
        Args:
            data: Data to ground
            context: Optional grounding context
        
        Returns:
            Grounded data
        
        Raises:
            GroundingError: If grounding fails
        """
        try:
            self.grounding_count += 1
            logger.info(f"Grounding cycle {self.grounding_count} started")
            
            grounded = data.copy()
            grounded["_grounded_at"] = datetime.utcnow().isoformat()
            grounded["_grounding_cycle"] = self.grounding_count
            
            if context:
                grounded["_context"] = context
            
            # Store grounding metadata
            self.state_manager.set(
                f"grounding:{self.grounding_count}",
                {
                    "timestamp": grounded["_grounded_at"],
                    "data_keys": list(data.keys()),
                    "has_context": context is not None
                }
            )
            
            logger.info(f"Grounding cycle {self.grounding_count} completed")
            return grounded
            
        except Exception as e:
            logger.error(f"Grounding failed: {e}")
            raise GroundingError(f"Failed to ground data: {e}", details={"error": str(e)})
    
    def validate_grounding(self, data: Dict[str, Any]) -> bool:
        """
        Validate if data has been properly grounded.
        
        Args:
            data: Data to validate
        
        Returns:
            True if data is grounded, False otherwise
        """
        is_grounded = "_grounded_at" in data and "_grounding_cycle" in data
        logger.debug(f"Grounding validation: {is_grounded}")
        return is_grounded
    
    def get_drift_score(self, data1: Dict[str, Any], data2: Dict[str, Any]) -> float:
        """
        Calculate drift score between two data points.
        
        Args:
            data1: First data point
            data2: Second data point
        
        Returns:
            Drift score (0.0 = identical, 1.0 = completely different)
        """
        keys1 = set(data1.keys())
        keys2 = set(data2.keys())
        
        all_keys = keys1 | keys2
        if not all_keys:
            return 0.0
        
        common_keys = keys1 & keys2
        drift = 1.0 - (len(common_keys) / len(all_keys))
        
        logger.debug(f"Drift score calculated: {drift}")
        return drift


# Global grounding engine instance
_grounding_engine: Optional[GroundingEngine] = None


def get_grounding_engine() -> GroundingEngine:
    """Get the global grounding engine instance."""
    global _grounding_engine
    if _grounding_engine is None:
        _grounding_engine = GroundingEngine()
    return _grounding_engine
