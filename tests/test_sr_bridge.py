"""Tests for sr_bridge module."""

import pytest
from src.sr_bridge import Bridge, get_bridge


def test_bridge_send():
    """Test sending a message."""
    bridge = Bridge()
    message = {"data": "test"}
    
    envelope = bridge.send("source", "destination", message)
    
    assert envelope["source"] == "source"
    assert envelope["destination"] == "destination"
    assert envelope["payload"] == message
    assert "id" in envelope
    assert "timestamp" in envelope


def test_bridge_receive():
    """Test receiving a message."""
    bridge = Bridge()
    message = {"data": "test"}
    
    envelope = bridge.send("source", "destination", message)
    received = bridge.receive(envelope["id"])
    
    assert received == envelope


def test_bridge_receive_nonexistent():
    """Test receiving non-existent message."""
    bridge = Bridge()
    
    received = bridge.receive("nonexistent")
    assert received is None


def test_bridge_message_count():
    """Test message count tracking."""
    bridge = Bridge()
    
    initial_count = bridge.get_message_count()
    bridge.send("source", "destination", {"data": "test"})
    
    assert bridge.get_message_count() == initial_count + 1


def test_get_bridge_singleton():
    """Test that get_bridge returns singleton."""
    bridge1 = get_bridge()
    bridge2 = get_bridge()
    assert bridge1 is bridge2
