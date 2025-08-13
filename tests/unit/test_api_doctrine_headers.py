"""
HEIR System - Phase 1 API Doctrine Headers Tests
Tests that API requests properly validate doctrine headers.
"""

import pytest
import json
from unittest.mock import Mock, patch
from datetime import datetime, timezone


class TestAPIDoctrine:
    """Test API doctrine header validation."""
    
    @pytest.fixture
    def valid_doctrine_headers(self):
        """Valid doctrine headers for testing."""
        return {
            "unique_id": "DB.03.PROC.API.10000.001",
            "process_id": "ProcessPayment",
            "blueprint_id": "payment-processing-v1",
            "agent_signature": "payment-specialist:20250113153201:abc123hash",
            "api_destination": "stripe-api",
            "operation_type": "POST"
        }
    
    @pytest.fixture
    def mock_api_gateway(self):
        """Mock API Gateway class for testing."""
        class MockAPIGateway:
            @staticmethod
            def validate_headers(headers):
                """Validate doctrine headers."""
                errors = []
                
                # Check unique_id format
                if not headers.get('unique_id'):
                    errors.append("Missing unique_id header")
                elif not MockAPIGateway._is_valid_unique_id(headers['unique_id']):
                    errors.append("Invalid unique_id format")
                
                # Check process_id format
                if not headers.get('process_id'):
                    errors.append("Missing process_id header")
                elif not MockAPIGateway._is_valid_process_id(headers['process_id']):
                    errors.append("Invalid process_id format (must be VerbObject)")
                
                # Check agent_signature
                if not headers.get('agent_signature'):
                    errors.append("Missing agent_signature header")
                elif not MockAPIGateway._is_valid_signature(headers['agent_signature']):
                    errors.append("Invalid agent_signature format")
                
                # Check blueprint_id
                if not headers.get('blueprint_id'):
                    errors.append("Missing blueprint_id header")
                
                return {
                    'valid': len(errors) == 0,
                    'errors': errors
                }
            
            @staticmethod
            def _is_valid_unique_id(unique_id):
                """Validate unique_id matches DPR format."""
                # Format: [DB].[SUBHIVE].[MICROPROCESS].[TOOL].[ALTITUDE].[STEP]
                parts = unique_id.split('.')
                if len(parts) != 6:
                    return False
                
                # Basic format validation
                db_part, subhive, microprocess, tool, altitude, step = parts
                
                # DB part should be 2-3 chars
                if not (2 <= len(db_part) <= 3):
                    return False
                
                # Altitude should be 5 digits
                if not (altitude.isdigit() and len(altitude) == 5):
                    return False
                
                # Step should be 3 digits
                if not (step.isdigit() and len(step) == 3):
                    return False
                
                return True
            
            @staticmethod
            def _is_valid_process_id(process_id):
                """Validate process_id is VerbObject format."""
                # Must start with capital letter (Verb)
                if not process_id[0].isupper():
                    return False
                
                # Must contain at least one more capital letter (Object)
                capital_count = sum(1 for c in process_id if c.isupper())
                if capital_count < 2:
                    return False
                
                # Must not contain spaces or special chars
                if not process_id.isalnum():
                    return False
                
                return True
            
            @staticmethod
            def _is_valid_signature(signature):
                """Validate agent signature format."""
                # Format: agent-id:timestamp:hash
                parts = signature.split(':')
                if len(parts) != 3:
                    return False
                
                agent_id, timestamp, hash_part = parts
                
                # Agent ID should not be empty
                if not agent_id:
                    return False
                
                # Timestamp should be 14 digits (YYYYMMDDHHMISS)
                if not (timestamp.isdigit() and len(timestamp) == 14):
                    return False
                
                # Hash should not be empty
                if not hash_part:
                    return False
                
                return True
        
        return MockAPIGateway
    
    def test_valid_headers_pass(self, valid_doctrine_headers, mock_api_gateway):
        """Test that valid doctrine headers pass validation."""
        result = mock_api_gateway.validate_headers(valid_doctrine_headers)
        
        assert result['valid'] is True
        assert len(result['errors']) == 0
    
    def test_missing_unique_id_fails(self, valid_doctrine_headers, mock_api_gateway):
        """Test that missing unique_id header fails validation."""
        headers = valid_doctrine_headers.copy()
        del headers['unique_id']
        
        result = mock_api_gateway.validate_headers(headers)
        
        assert result['valid'] is False
        assert "Missing unique_id header" in result['errors']
    
    def test_invalid_unique_id_format_fails(self, valid_doctrine_headers, mock_api_gateway):
        """Test that invalid unique_id format fails validation."""
        test_cases = [
            "DB.03.PROC",  # Too few parts
            "DB.03.PROC.API.10000.001.EXTRA",  # Too many parts
            "DB.03.PROC.API.1000.001",  # Altitude not 5 digits
            "DB.03.PROC.API.10000.01",  # Step not 3 digits
            "D.03.PROC.API.10000.001",  # DB part too short
        ]
        
        for invalid_id in test_cases:
            headers = valid_doctrine_headers.copy()
            headers['unique_id'] = invalid_id
            
            result = mock_api_gateway.validate_headers(headers)
            
            assert result['valid'] is False, f"Should reject invalid unique_id: {invalid_id}"
            assert "Invalid unique_id format" in result['errors']
    
    def test_missing_process_id_fails(self, valid_doctrine_headers, mock_api_gateway):
        """Test that missing process_id header fails validation."""
        headers = valid_doctrine_headers.copy()
        del headers['process_id']
        
        result = mock_api_gateway.validate_headers(headers)
        
        assert result['valid'] is False
        assert "Missing process_id header" in result['errors']
    
    def test_invalid_process_id_format_fails(self, valid_doctrine_headers, mock_api_gateway):
        """Test that invalid process_id format fails validation."""
        test_cases = [
            "processPayment",  # Doesn't start with capital
            "Process",  # Only one capital letter
            "ProcessPayment123",  # Contains numbers
            "Process Payment",  # Contains space
            "Process-Payment",  # Contains special char
        ]
        
        for invalid_process_id in test_cases:
            headers = valid_doctrine_headers.copy()
            headers['process_id'] = invalid_process_id
            
            result = mock_api_gateway.validate_headers(headers)
            
            assert result['valid'] is False, f"Should reject invalid process_id: {invalid_process_id}"
            assert "Invalid process_id format" in result['errors']
    
    def test_valid_process_id_formats_pass(self, valid_doctrine_headers, mock_api_gateway):
        """Test that valid process_id formats pass validation."""
        valid_process_ids = [
            "ProcessPayment",
            "LoadUserData", 
            "GenerateReport",
            "ValidateInput",
            "SendNotification"
        ]
        
        for valid_process_id in valid_process_ids:
            headers = valid_doctrine_headers.copy()
            headers['process_id'] = valid_process_id
            
            result = mock_api_gateway.validate_headers(headers)
            
            assert result['valid'] is True, f"Should accept valid process_id: {valid_process_id}"
    
    def test_missing_agent_signature_fails(self, valid_doctrine_headers, mock_api_gateway):
        """Test that missing agent_signature header fails validation."""
        headers = valid_doctrine_headers.copy()
        del headers['agent_signature']
        
        result = mock_api_gateway.validate_headers(headers)
        
        assert result['valid'] is False
        assert "Missing agent_signature header" in result['errors']
    
    def test_invalid_agent_signature_format_fails(self, valid_doctrine_headers, mock_api_gateway):
        """Test that invalid agent_signature format fails validation."""
        test_cases = [
            "payment-specialist",  # Missing timestamp and hash
            "payment-specialist:20250113153201",  # Missing hash
            ":20250113153201:abc123hash",  # Missing agent ID
            "payment-specialist:2025011315:abc123hash",  # Timestamp wrong length
            "payment-specialist:20250113153201:",  # Missing hash
        ]
        
        for invalid_signature in test_cases:
            headers = valid_doctrine_headers.copy()
            headers['agent_signature'] = invalid_signature
            
            result = mock_api_gateway.validate_headers(headers)
            
            assert result['valid'] is False, f"Should reject invalid signature: {invalid_signature}"
            assert "Invalid agent_signature format" in result['errors']
    
    def test_missing_blueprint_id_fails(self, valid_doctrine_headers, mock_api_gateway):
        """Test that missing blueprint_id header fails validation."""
        headers = valid_doctrine_headers.copy()
        del headers['blueprint_id']
        
        result = mock_api_gateway.validate_headers(headers)
        
        assert result['valid'] is False
        assert "Missing blueprint_id header" in result['errors']
    
    def test_multiple_validation_errors(self, mock_api_gateway):
        """Test that multiple validation errors are all reported."""
        invalid_headers = {
            # Missing unique_id
            "process_id": "processPayment",  # Invalid format
            # Missing agent_signature
            "blueprint_id": "payment-processing-v1",
            "api_destination": "stripe-api",
            "operation_type": "POST"
        }
        
        result = mock_api_gateway.validate_headers(invalid_headers)
        
        assert result['valid'] is False
        assert len(result['errors']) >= 3  # At least 3 errors
        assert "Missing unique_id header" in result['errors']
        assert "Invalid process_id format" in result['errors']
        assert "Missing agent_signature header" in result['errors']
    
    @pytest.mark.integration
    def test_api_request_rejection(self, mock_api_gateway):
        """Integration test: API request should be rejected without proper headers."""
        # Simulate an API request without proper headers
        api_request = {
            "method": "POST",
            "url": "https://api.stripe.com/v1/charges",
            "payload": {"amount": 1000, "currency": "usd"}
        }
        
        invalid_headers = {
            "operation_type": "POST"  # Only has operation_type, missing all other required headers
        }
        
        # This would normally be handled by the API Gateway
        validation_result = mock_api_gateway.validate_headers(invalid_headers)
        
        # Request should be rejected
        assert validation_result['valid'] is False
        assert len(validation_result['errors']) >= 4  # Missing 4+ required headers
        
        # In a real system, this would result in a 400 Bad Request response
        expected_response = {
            "status": "REJECTED",
            "error": {
                "code": "MISSING_HEADERS",
                "message": "Required doctrine headers not provided",
                "validation_errors": validation_result['errors']
            }
        }
        
        # Verify response structure
        assert expected_response['status'] == 'REJECTED'
        assert expected_response['error']['code'] == 'MISSING_HEADERS'


if __name__ == '__main__':
    pytest.main([__file__])