"""Tests for sr_routing module."""

import pytest
from src.sr_routing import Router, RouteType, get_router
from src.sr_errors import RoutingError


def test_router_register_and_route():
    """Test registering and routing."""
    router = Router()
    
    def handler(x):
        return x * 2
    
    router.register("double", handler)
    result = router.route("double", 5)
    assert result == 10


def test_router_route_not_found():
    """Test routing to non-existent route."""
    router = Router()
    
    with pytest.raises(RoutingError) as exc_info:
        router.route("nonexistent")
    
    assert "not found" in str(exc_info.value)


def test_router_get_routes():
    """Test getting all routes."""
    router = Router()
    
    def handler():
        pass
    
    router.register("route1", handler, RouteType.AGENT)
    router.register("route2", handler, RouteType.BRIDGE)
    
    routes = router.get_routes()
    assert "route1" in routes
    assert "route2" in routes
    assert routes["route1"]["type"] == "agent"
    assert routes["route2"]["type"] == "bridge"


def test_router_unregister():
    """Test unregistering a route."""
    router = Router()
    
    def handler():
        pass
    
    router.register("route1", handler)
    router.unregister("route1")
    
    with pytest.raises(RoutingError):
        router.route("route1")


def test_get_router_singleton():
    """Test that get_router returns singleton."""
    router1 = get_router()
    router2 = get_router()
    assert router1 is router2
