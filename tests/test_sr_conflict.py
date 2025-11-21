"""Tests for sr_conflict module."""

import pytest
from src.sr_conflict import ConflictResolver, ConflictResolutionStrategy, get_conflict_resolver
from src.sr_errors import ConflictError


def test_conflict_resolver_latest_wins():
    """Test LATEST_WINS strategy."""
    resolver = ConflictResolver(ConflictResolutionStrategy.LATEST_WINS)
    values = [{"a": 1}, {"a": 2}, {"a": 3}]
    
    result = resolver.resolve(values)
    assert result == {"a": 3}


def test_conflict_resolver_merge():
    """Test MERGE strategy."""
    resolver = ConflictResolver(ConflictResolutionStrategy.MERGE)
    values = [{"a": 1}, {"b": 2}, {"c": 3}]
    
    result = resolver.resolve(values, strategy=ConflictResolutionStrategy.MERGE)
    assert result == {"a": 1, "b": 2, "c": 3}


def test_conflict_resolver_single_value():
    """Test resolving with single value."""
    resolver = ConflictResolver()
    values = [{"a": 1}]
    
    result = resolver.resolve(values)
    assert result == {"a": 1}


def test_conflict_resolver_no_values():
    """Test resolving with no values."""
    resolver = ConflictResolver()
    
    with pytest.raises(ConflictError):
        resolver.resolve([])


def test_conflict_resolver_count():
    """Test conflict count tracking."""
    resolver = ConflictResolver()
    
    initial_count = resolver.get_conflict_count()
    resolver.resolve([{"a": 1}, {"a": 2}])
    
    assert resolver.get_conflict_count() == initial_count + 1


def test_get_conflict_resolver_singleton():
    """Test that get_conflict_resolver returns singleton."""
    resolver1 = get_conflict_resolver()
    resolver2 = get_conflict_resolver()
    assert resolver1 is resolver2
