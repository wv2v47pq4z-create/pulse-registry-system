"""Agent management for SR-HYBRID System."""

from typing import Any, Callable, Dict, Optional
from datetime import datetime

from .sr_logging import get_logger
from .sr_errors import AgentError
from .sr_recursion import get_recursion_guard
from .sr_state import get_state_manager

logger = get_logger("agents")


class Agent:
    """Base agent class."""
    
    def __init__(self, name: str, handler: Callable):
        self.name = name
        self.handler = handler
        self.call_count = 0
        self.last_called = None
        logger.info(f"Agent created: {name}")
    
    def call(self, *args, **kwargs) -> Any:
        """Call the agent handler."""
        self.call_count += 1
        self.last_called = datetime.utcnow().isoformat()
        logger.debug(f"Agent {self.name} called (count={self.call_count})")
        
        # Track metric for monitoring
        from .sr_metrics import track_agent_call
        track_agent_call(self.name)
        
        try:
            result = self.handler(*args, **kwargs)
            logger.debug(f"Agent {self.name} completed successfully")
            return result
        except Exception as e:
            logger.error(f"Agent {self.name} failed: {e}")
            raise AgentError(
                f"Agent '{self.name}' execution failed: {e}",
                details={"agent": self.name, "error": str(e)}
            )


class AgentManager:
    """Manage multiple agents in the system."""
    
    def __init__(self):
        self._agents: Dict[str, Agent] = {}
        self.state_manager = get_state_manager()
        self.recursion_guard = get_recursion_guard()
        logger.info("AgentManager initialized")
    
    def register(self, name: str, handler: Callable) -> Agent:
        """
        Register a new agent.
        
        Args:
            name: Agent name
            handler: Agent handler function
        
        Returns:
            Registered agent
        """
        agent = Agent(name, handler)
        self._agents[name] = agent
        logger.info(f"Agent registered: {name}")
        return agent
    
    def call(self, name: str, *args, **kwargs) -> Any:
        """
        Call an agent by name with recursion tracking.
        
        Args:
            name: Agent name
            *args: Positional arguments
            **kwargs: Keyword arguments
        
        Returns:
            Agent result
        
        Raises:
            AgentError: If agent not found or call fails
        """
        if name not in self._agents:
            logger.error(f"Agent not found: {name}")
            raise AgentError(
                f"Agent '{name}' not found",
                details={"agent": name, "available": list(self._agents.keys())}
            )
        
        with self.recursion_guard.track(f"agent:{name}"):
            agent = self._agents[name]
            return agent.call(*args, **kwargs)
    
    def get_agent(self, name: str) -> Optional[Agent]:
        """Get an agent by name."""
        return self._agents.get(name)
    
    def get_all_agents(self) -> Dict[str, Agent]:
        """Get all registered agents."""
        return self._agents.copy()
    
    def get_stats(self) -> Dict[str, dict]:
        """Get statistics for all agents."""
        return {
            name: {
                "call_count": agent.call_count,
                "last_called": agent.last_called
            }
            for name, agent in self._agents.items()
        }
    
    def unregister(self, name: str) -> None:
        """Unregister an agent."""
        if name in self._agents:
            del self._agents[name]
            logger.info(f"Agent unregistered: {name}")


# Global agent manager instance
_agent_manager: Optional[AgentManager] = None


def get_agent_manager() -> AgentManager:
    """Get the global agent manager instance."""
    global _agent_manager
    if _agent_manager is None:
        _agent_manager = AgentManager()
    return _agent_manager
