"""Routing logic for SR-HYBRID System."""

from typing import Any, Callable, Dict, Optional
from enum import Enum

from .sr_logging import get_logger
from .sr_errors import RoutingError

logger = get_logger("routing")


class RouteType(Enum):
    """Types of routes available in the system."""
    AGENT = "agent"
    BRIDGE = "bridge"
    GROUNDING = "grounding"
    STATE = "state"


class Router:
    """Message and request routing system."""
    
    def __init__(self):
        self._routes: Dict[str, Callable] = {}
        self._route_metadata: Dict[str, dict] = {}
        logger.info("Router initialized")
    
    def register(
        self,
        route_name: str,
        handler: Callable,
        route_type: RouteType = RouteType.AGENT,
        metadata: Optional[dict] = None
    ) -> None:
        """
        Register a route handler.
        
        Args:
            route_name: Name of the route
            handler: Callable handler function
            route_type: Type of route
            metadata: Optional metadata about the route
        """
        self._routes[route_name] = handler
        self._route_metadata[route_name] = {
            "type": route_type.value,
            "metadata": metadata or {}
        }
        logger.info(f"Route registered: {route_name} (type={route_type.value})")
    
    def route(self, route_name: str, *args, **kwargs) -> Any:
        """
        Route a message to the appropriate handler.
        
        Args:
            route_name: Name of the route
            *args: Positional arguments for handler
            **kwargs: Keyword arguments for handler
        
        Returns:
            Handler result
        
        Raises:
            RoutingError: If route not found or handler fails
        """
        if route_name not in self._routes:
            logger.error(f"Route not found: {route_name}")
            raise RoutingError(
                f"Route '{route_name}' not found",
                details={"route": route_name, "available": list(self._routes.keys())}
            )
        
        try:
            handler = self._routes[route_name]
            logger.debug(f"Routing to: {route_name}")
            result = handler(*args, **kwargs)
            logger.debug(f"Route {route_name} completed successfully")
            return result
        except Exception as e:
            logger.error(f"Route {route_name} failed: {e}")
            raise RoutingError(
                f"Route '{route_name}' handler failed: {e}",
                details={"route": route_name, "error": str(e)}
            )
    
    def get_routes(self) -> Dict[str, dict]:
        """Get all registered routes with metadata."""
        return {
            name: self._route_metadata[name]
            for name in self._routes.keys()
        }
    
    def unregister(self, route_name: str) -> None:
        """Unregister a route."""
        if route_name in self._routes:
            del self._routes[route_name]
            del self._route_metadata[route_name]
            logger.info(f"Route unregistered: {route_name}")


# Global router instance
_router: Optional[Router] = None


def get_router() -> Router:
    """Get the global router instance."""
    global _router
    if _router is None:
        _router = Router()
    return _router
