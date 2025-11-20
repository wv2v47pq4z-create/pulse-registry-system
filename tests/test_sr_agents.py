"""Tests for sr_agents module."""

import pytest
from src.sr_agents import Agent, AgentManager, get_agent_manager
from src.sr_errors import AgentError


def test_agent_call():
    """Test calling an agent."""
    def handler(x):
        return x * 2
    
    agent = Agent("test_agent", handler)
    result = agent.call(5)
    
    assert result == 10
    assert agent.call_count == 1


def test_agent_manager_register():
    """Test registering an agent."""
    manager = AgentManager()
    
    def handler():
        return "result"
    
    agent = manager.register("test_agent", handler)
    assert agent.name == "test_agent"


def test_agent_manager_call():
    """Test calling agent through manager."""
    manager = AgentManager()
    
    def handler(x):
        return x * 2
    
    manager.register("double", handler)
    result = manager.call("double", 5)
    
    assert result == 10


def test_agent_manager_call_nonexistent():
    """Test calling non-existent agent."""
    manager = AgentManager()
    
    with pytest.raises(AgentError) as exc_info:
        manager.call("nonexistent")
    
    assert "not found" in str(exc_info.value)


def test_agent_manager_get_agent():
    """Test getting an agent."""
    manager = AgentManager()
    
    def handler():
        pass
    
    manager.register("test_agent", handler)
    agent = manager.get_agent("test_agent")
    
    assert agent is not None
    assert agent.name == "test_agent"


def test_agent_manager_get_all_agents():
    """Test getting all agents."""
    manager = AgentManager()
    
    def handler():
        pass
    
    manager.register("agent1", handler)
    manager.register("agent2", handler)
    
    agents = manager.get_all_agents()
    assert len(agents) == 2
    assert "agent1" in agents
    assert "agent2" in agents


def test_agent_manager_get_stats():
    """Test getting agent stats."""
    manager = AgentManager()
    
    def handler():
        return "result"
    
    manager.register("test_agent", handler)
    manager.call("test_agent")
    
    stats = manager.get_stats()
    assert "test_agent" in stats
    assert stats["test_agent"]["call_count"] == 1


def test_agent_manager_unregister():
    """Test unregistering an agent."""
    manager = AgentManager()
    
    def handler():
        pass
    
    manager.register("test_agent", handler)
    manager.unregister("test_agent")
    
    with pytest.raises(AgentError):
        manager.call("test_agent")


def test_get_agent_manager_singleton():
    """Test that get_agent_manager returns singleton."""
    manager1 = get_agent_manager()
    manager2 = get_agent_manager()
    assert manager1 is manager2
