"""Conflict resolution for SR-HYBRID System."""

from typing import Any, Dict, List, Optional
from enum import Enum

from .sr_logging import get_logger
from .sr_errors import ConflictError

logger = get_logger("conflict")


class ConflictResolutionStrategy(Enum):
    """Strategies for resolving conflicts."""
    LATEST_WINS = "latest_wins"
    MERGE = "merge"
    PRIORITY = "priority"
    MANUAL = "manual"


class ConflictResolver:
    """Resolve conflicts between competing states or messages."""
    
    def __init__(self, default_strategy: ConflictResolutionStrategy = ConflictResolutionStrategy.LATEST_WINS):
        self.default_strategy = default_strategy
        self.conflict_count = 0
        logger.info(f"ConflictResolver initialized with strategy={default_strategy.value}")
    
    def resolve(
        self,
        conflicting_values: List[Dict[str, Any]],
        strategy: Optional[ConflictResolutionStrategy] = None,
        context: Optional[dict] = None
    ) -> Dict[str, Any]:
        """
        Resolve conflicts between multiple values.
        
        Args:
            conflicting_values: List of conflicting values
            strategy: Resolution strategy (uses default if None)
            context: Optional context for resolution
        
        Returns:
            Resolved value
        
        Raises:
            ConflictError: If resolution fails
        """
        if not conflicting_values:
            raise ConflictError("No values provided for conflict resolution")
        
        if len(conflicting_values) == 1:
            return conflicting_values[0]
        
        self.conflict_count += 1
        strategy = strategy or self.default_strategy
        
        logger.info(
            f"Resolving conflict #{self.conflict_count} with strategy={strategy.value}, "
            f"values={len(conflicting_values)}"
        )
        
        try:
            if strategy == ConflictResolutionStrategy.LATEST_WINS:
                result = self._resolve_latest_wins(conflicting_values)
            elif strategy == ConflictResolutionStrategy.MERGE:
                result = self._resolve_merge(conflicting_values)
            elif strategy == ConflictResolutionStrategy.PRIORITY:
                result = self._resolve_priority(conflicting_values, context)
            else:
                raise ConflictError(
                    f"Strategy {strategy.value} requires manual intervention",
                    details={"strategy": strategy.value}
                )
            
            logger.info(f"Conflict #{self.conflict_count} resolved successfully")
            return result
            
        except Exception as e:
            logger.error(f"Conflict resolution failed: {e}")
            raise ConflictError(
                f"Failed to resolve conflict: {e}",
                details={"strategy": strategy.value, "error": str(e)}
            )
    
    def _resolve_latest_wins(self, values: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Resolve by taking the latest value."""
        # Assume last value in list is latest
        return values[-1]
    
    def _resolve_merge(self, values: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Resolve by merging all values."""
        result = {}
        for value in values:
            result.update(value)
        return result
    
    def _resolve_priority(
        self,
        values: List[Dict[str, Any]],
        context: Optional[dict]
    ) -> Dict[str, Any]:
        """Resolve by priority (requires priority in values or context)."""
        if not context or "priorities" not in context:
            # Fallback to latest wins if no priority info
            return self._resolve_latest_wins(values)
        
        priorities = context["priorities"]
        for priority in sorted(priorities.keys(), reverse=True):
            for value in values:
                if value.get("priority") == priority:
                    return value
        
        return values[0]
    
    def get_conflict_count(self) -> int:
        """Get total number of conflicts resolved."""
        return self.conflict_count


# Global conflict resolver instance
_conflict_resolver: Optional[ConflictResolver] = None


def get_conflict_resolver() -> ConflictResolver:
    """Get the global conflict resolver instance."""
    global _conflict_resolver
    if _conflict_resolver is None:
        _conflict_resolver = ConflictResolver()
    return _conflict_resolver
