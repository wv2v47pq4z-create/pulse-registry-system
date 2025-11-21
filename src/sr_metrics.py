"""Prometheus metrics for SR-HYBRID System."""

from prometheus_client import Counter, Gauge

# Prometheus metrics - Global counters and gauges
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


def track_message():
    """Track a message being processed."""
    sr_hybrid_total_messages.inc()


def track_grounding():
    """Track a grounding operation."""
    sr_hybrid_grounding_total.inc()


def track_agent_call(agent_name: str):
    """Track an agent call."""
    sr_hybrid_agent_calls_total.labels(agent_name=agent_name).inc()


def update_drift_score(score: float):
    """Update the drift score gauge."""
    sr_hybrid_drift_score.set(score)


def track_error(error_type: str):
    """Track an error occurrence."""
    sr_hybrid_errors_total.labels(error_type=error_type).inc()
