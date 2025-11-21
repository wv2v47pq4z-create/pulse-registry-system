"""Tests for sr_grounding module."""

import pytest
from src.sr_grounding import GroundingEngine, get_grounding_engine


def test_grounding_engine_ground():
    """Test grounding data."""
    engine = GroundingEngine()
    data = {"key": "value"}
    grounded = engine.ground(data)
    
    assert grounded["key"] == "value"
    assert "_grounded_at" in grounded
    assert "_grounding_cycle" in grounded
    assert grounded["_grounding_cycle"] == 1


def test_grounding_engine_ground_with_context():
    """Test grounding with context."""
    engine = GroundingEngine()
    data = {"key": "value"}
    context = {"source": "test"}
    grounded = engine.ground(data, context=context)
    
    assert "_context" in grounded
    assert grounded["_context"] == context


def test_grounding_engine_validate():
    """Test grounding validation."""
    engine = GroundingEngine()
    data = {"key": "value"}
    
    assert not engine.validate_grounding(data)
    
    grounded = engine.ground(data)
    assert engine.validate_grounding(grounded)


def test_grounding_engine_drift_score():
    """Test drift score calculation."""
    engine = GroundingEngine()
    data1 = {"a": 1, "b": 2}
    data2 = {"a": 1, "c": 3}
    
    drift = engine.get_drift_score(data1, data2)
    assert 0.0 <= drift <= 1.0


def test_grounding_engine_drift_score_identical():
    """Test drift score for identical data."""
    engine = GroundingEngine()
    data = {"a": 1, "b": 2}
    
    drift = engine.get_drift_score(data, data)
    assert drift == 0.0


def test_get_grounding_engine_singleton():
    """Test that get_grounding_engine returns singleton."""
    engine1 = get_grounding_engine()
    engine2 = get_grounding_engine()
    assert engine1 is engine2
