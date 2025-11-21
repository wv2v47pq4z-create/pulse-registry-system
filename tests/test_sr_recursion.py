"""Tests for sr_recursion module."""

import pytest
from src.sr_recursion import RecursionGuard, get_recursion_guard
from src.sr_errors import RecursionLimitError


def test_recursion_guard_track():
    """Test recursion tracking."""
    guard = RecursionGuard(max_depth=5)
    
    with guard.track("operation1"):
        assert guard.depth == 1
        with guard.track("operation2"):
            assert guard.depth == 2
        assert guard.depth == 1
    assert guard.depth == 0


def test_recursion_guard_limit():
    """Test recursion limit enforcement."""
    guard = RecursionGuard(max_depth=3)
    
    with pytest.raises(RecursionLimitError):
        with guard.track():
            with guard.track():
                with guard.track():
                    # This fourth level should fail
                    with guard.track():
                        pass


def test_recursion_guard_reset():
    """Test resetting recursion depth."""
    guard = RecursionGuard()
    with guard.track():
        assert guard.depth == 1
    guard.reset()
    assert guard.depth == 0


def test_get_recursion_guard_singleton():
    """Test that get_recursion_guard returns singleton."""
    guard1 = get_recursion_guard()
    guard2 = get_recursion_guard()
    assert guard1 is guard2
