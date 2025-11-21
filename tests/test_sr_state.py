"""Tests for sr_state module."""

import pytest
from src.sr_state import StateManager, get_state_manager


def test_state_manager_set_and_get():
    """Test setting and getting state values."""
    manager = StateManager()
    manager.set("key1", "value1")
    assert manager.get("key1") == "value1"


def test_state_manager_default_value():
    """Test getting with default value."""
    manager = StateManager()
    assert manager.get("nonexistent", "default") == "default"


def test_state_manager_delete():
    """Test deleting state values."""
    manager = StateManager()
    manager.set("key1", "value1")
    manager.delete("key1")
    assert manager.get("key1") is None


def test_state_manager_clear():
    """Test clearing all state."""
    manager = StateManager()
    manager.set("key1", "value1")
    manager.set("key2", "value2")
    manager.clear()
    assert manager.get("key1") is None
    assert manager.get("key2") is None


def test_state_manager_get_all():
    """Test getting all state."""
    manager = StateManager()
    manager.set("key1", "value1")
    manager.set("key2", "value2")
    all_state = manager.get_all()
    assert all_state == {"key1": "value1", "key2": "value2"}


def test_state_manager_metadata():
    """Test state metadata."""
    manager = StateManager()
    metadata = {"source": "test"}
    manager.set("key1", "value1", metadata=metadata)
    stored_metadata = manager.get_metadata("key1")
    assert stored_metadata["source"] == "test"
    assert "updated_at" in stored_metadata


def test_get_state_manager_singleton():
    """Test that get_state_manager returns singleton."""
    manager1 = get_state_manager()
    manager2 = get_state_manager()
    assert manager1 is manager2
