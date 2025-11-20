"""Tests for sr_graph module."""

import pytest
import json
import io
from unittest.mock import Mock, MagicMock
from src.sr_graph import SRHybridServer


def create_test_handler():
    """Create a test handler with mocked socket."""
    # Create a mock request with proper rfile and wfile
    request = MagicMock()
    request.makefile.return_value = io.BytesIO(b"GET / HTTP/1.1\r\n\r\n")
    
    # Create handler but don't let __init__ run
    handler = SRHybridServer.__new__(SRHybridServer)
    handler.send_response = Mock()
    handler.send_header = Mock()
    handler.end_headers = Mock()
    handler.wfile = Mock()
    
    return handler


def test_health_endpoint():
    """Test health check endpoint."""
    handler = create_test_handler()
    handler.path = "/health"
    
    handler.handle_health()
    
    handler.send_response.assert_called_once_with(200)
    assert handler.wfile.write.called
    
    # Check response content
    response_data = handler.wfile.write.call_args[0][0]
    response_json = json.loads(response_data.decode())
    assert response_json["status"] == "ok"
    assert response_json["service"] == "sr-hybrid"


def test_metrics_endpoint():
    """Test metrics endpoint."""
    handler = create_test_handler()
    handler.path = "/metrics"
    
    handler.handle_metrics()
    
    handler.send_response.assert_called_once_with(200)
    assert handler.wfile.write.called


def test_status_endpoint():
    """Test status endpoint."""
    handler = create_test_handler()
    handler.path = "/status"
    
    handler.handle_status()
    
    handler.send_response.assert_called_once_with(200)
    assert handler.wfile.write.called
    
    # Check response content
    response_data = handler.wfile.write.call_args[0][0]
    response_json = json.loads(response_data.decode())
    assert response_json["service"] == "sr-hybrid"
    assert response_json["status"] == "running"
    assert "components" in response_json
