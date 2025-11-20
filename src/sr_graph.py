"""Main application graph with HTTP server and metrics for SR-HYBRID System."""

import os
import json
from typing import Dict, Any
from http.server import HTTPServer, BaseHTTPRequestHandler
from prometheus_client import Counter, Gauge, generate_latest, CONTENT_TYPE_LATEST

from .sr_logging import setup_logging, get_logger
from .sr_state import get_state_manager
from .sr_recursion import get_recursion_guard
from .sr_grounding import get_grounding_engine
from .sr_routing import get_router
from .sr_bridge import get_bridge
from .sr_conflict import get_conflict_resolver
from .sr_agents import get_agent_manager

# Setup logging
setup_logging()
logger = get_logger("graph")

# Prometheus metrics
sr_hybrid_total_messages = Counter(
    'sr_hybrid_total_messages',
    'Total number of messages processed'
)

sr_hybrid_recursion_depth = Gauge(
    'sr_hybrid_recursion_depth',
    'Current recursion depth'
)

sr_hybrid_drift_score = Gauge(
    'sr_hybrid_drift_score',
    'Current drift score'
)

sr_hybrid_grounding_total = Counter(
    'sr_hybrid_grounding_total',
    'Total number of grounding operations'
)

sr_hybrid_agent_calls_total = Counter(
    'sr_hybrid_agent_calls_total',
    'Total number of agent calls',
    ['agent_name']
)

sr_hybrid_errors_total = Counter(
    'sr_hybrid_errors_total',
    'Total number of errors',
    ['error_type']
)


class SRHybridServer(BaseHTTPRequestHandler):
    """HTTP server for health checks and metrics."""
    
    def log_message(self, format, *args):
        """Override to use our logger."""
        logger.info(f"{self.address_string()} - {format % args}")
    
    def do_GET(self):
        """Handle GET requests."""
        if self.path == '/health':
            self.handle_health()
        elif self.path == '/metrics':
            self.handle_metrics()
        elif self.path == '/status':
            self.handle_status()
        else:
            self.send_error(404, "Not Found")
    
    def handle_health(self):
        """Health check endpoint."""
        try:
            response = {"status": "ok", "service": "sr-hybrid"}
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())
        except Exception as e:
            logger.error(f"Health check failed: {e}")
            sr_hybrid_errors_total.labels(error_type="health_check").inc()
            self.send_error(500, str(e))
    
    def handle_metrics(self):
        """Prometheus metrics endpoint."""
        try:
            # Update current metrics from system state
            state_manager = get_state_manager()
            recursion_guard = get_recursion_guard()
            grounding_engine = get_grounding_engine()
            bridge = get_bridge()
            agent_manager = get_agent_manager()
            
            # Update gauges
            sr_hybrid_recursion_depth.set(recursion_guard.depth)
            
            # Update counters from system state
            sr_hybrid_total_messages.inc(0)  # Just ensure it exists
            sr_hybrid_grounding_total._value._value = grounding_engine.grounding_count
            
            # Update agent call counts
            for agent_name, stats in agent_manager.get_stats().items():
                sr_hybrid_agent_calls_total.labels(agent_name=agent_name)._value._value = stats['call_count']
            
            metrics = generate_latest()
            self.send_response(200)
            self.send_header('Content-Type', CONTENT_TYPE_LATEST)
            self.end_headers()
            self.wfile.write(metrics)
        except Exception as e:
            logger.error(f"Metrics generation failed: {e}")
            sr_hybrid_errors_total.labels(error_type="metrics").inc()
            self.send_error(500, str(e))
    
    def handle_status(self):
        """System status endpoint."""
        try:
            state_manager = get_state_manager()
            recursion_guard = get_recursion_guard()
            grounding_engine = get_grounding_engine()
            bridge = get_bridge()
            agent_manager = get_agent_manager()
            
            status = {
                "service": "sr-hybrid",
                "status": "running",
                "components": {
                    "state_manager": "active",
                    "recursion_guard": {
                        "max_depth": recursion_guard.max_depth,
                        "current_depth": recursion_guard.depth
                    },
                    "grounding_engine": {
                        "total_cycles": grounding_engine.grounding_count
                    },
                    "bridge": {
                        "total_messages": bridge.get_message_count()
                    },
                    "agents": {
                        "count": len(agent_manager.get_all_agents()),
                        "stats": agent_manager.get_stats()
                    }
                }
            }
            
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(status, indent=2).encode())
        except Exception as e:
            logger.error(f"Status check failed: {e}")
            sr_hybrid_errors_total.labels(error_type="status").inc()
            self.send_error(500, str(e))


def run_server(host: str = "0.0.0.0", port: int = 8080):
    """
    Run the HTTP server.
    
    Args:
        host: Host to bind to
        port: Port to bind to
    """
    logger.info(f"Starting SR-HYBRID server on {host}:{port}")
    
    # Initialize all components
    state_manager = get_state_manager()
    recursion_guard = get_recursion_guard()
    grounding_engine = get_grounding_engine()
    router = get_router()
    bridge = get_bridge()
    conflict_resolver = get_conflict_resolver()
    agent_manager = get_agent_manager()
    
    logger.info("All components initialized")
    
    # Create and start server
    server = HTTPServer((host, port), SRHybridServer)
    logger.info(f"Server listening on http://{host}:{port}")
    logger.info(f"Health endpoint: http://{host}:{port}/health")
    logger.info(f"Metrics endpoint: http://{host}:{port}/metrics")
    logger.info(f"Status endpoint: http://{host}:{port}/status")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        logger.info("Server shutting down...")
        server.shutdown()
        logger.info("Server stopped")


def main():
    """Main entry point."""
    host = os.getenv("SR_HOST", "0.0.0.0")
    port = int(os.getenv("SR_PORT", "8080"))
    run_server(host, port)


if __name__ == "__main__":
    main()
