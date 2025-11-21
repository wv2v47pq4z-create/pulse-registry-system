"""Tests for sr_metrics module."""

import pytest
from src.sr_metrics import (
    track_message,
    track_grounding,
    track_agent_call,
    update_drift_score,
    track_error,
    sr_hybrid_total_messages,
    sr_hybrid_grounding_total,
    sr_hybrid_agent_calls_total,
    sr_hybrid_drift_score,
    sr_hybrid_errors_total,
)


def test_track_message():
    """Test message tracking."""
    initial = sr_hybrid_total_messages._value.get()
    track_message()
    assert sr_hybrid_total_messages._value.get() > initial


def test_track_grounding():
    """Test grounding tracking."""
    initial = sr_hybrid_grounding_total._value.get()
    track_grounding()
    assert sr_hybrid_grounding_total._value.get() > initial


def test_track_agent_call():
    """Test agent call tracking."""
    track_agent_call("test_agent")
    # Verify metric exists for the agent
    assert sr_hybrid_agent_calls_total.labels(agent_name="test_agent")


def test_update_drift_score():
    """Test drift score update."""
    update_drift_score(0.5)
    assert sr_hybrid_drift_score._value.get() == 0.5
    
    update_drift_score(0.8)
    assert sr_hybrid_drift_score._value.get() == 0.8


def test_track_error():
    """Test error tracking."""
    initial = sr_hybrid_errors_total.labels(error_type="test_error")._value.get()
    track_error("test_error")
    assert sr_hybrid_errors_total.labels(error_type="test_error")._value.get() > initial
