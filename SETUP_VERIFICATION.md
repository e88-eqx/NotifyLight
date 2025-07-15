# NotifyLight Setup Verification Guide

## Overview

The `setup-verify.sh` script provides automated verification of your NotifyLight backend installation. It tests the complete notification flow without requiring a mobile app, making it perfect for initial setup validation and CI/CD pipelines.

## Prerequisites

### Required Tools
- **curl**: For making HTTP requests to the API
- **bash**: Shell environment (version 4.0+)

### Optional Tools
- **jq**: For JSON parsing and pretty output formatting
- **docker**: If using containerized deployment

### Installation Commands

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install curl jq
```

**macOS:**
```bash
brew install curl jq
```

**CentOS/RHEL:**
```bash
sudo yum install curl jq
```

## Quick Start

### 1. Basic Verification
```bash
./setup-verify.sh
```

### 2. With API Key
```bash
./setup-verify.sh --api-key your-api-key-here
```

### 3. Verbose Output
```bash
./setup-verify.sh -v --api-key your-api-key-here
```

### 4. Custom API URL
```bash
./setup-verify.sh --api-url https://your-domain.com --api-key your-api-key-here
```

## Configuration

### Environment Variables

The script respects the following environment variables:

```bash
# API server URL (default: http://localhost:3000)
export NOTIFYLIGHT_API_URL="https://your-domain.com"

# API key for authentication
export NOTIFYLIGHT_API_KEY="your-api-key-here"
```

### .env File Support

The script automatically reads API keys from your `.env` file:

```bash
# .env file
API_KEY=your-super-secret-api-key-here
NOTIFYLIGHT_API_URL=http://localhost:3000
```

## Tests Performed

The script performs 5 core tests that validate the complete notification flow:

### 1. Health Check
- **Endpoint**: `GET /health`
- **Purpose**: Verifies basic server connectivity and status
- **Success Criteria**: Returns 200 status with health information

### 2. Device Registration
- **Endpoint**: `POST /register-device`
- **Purpose**: Tests device registration with dummy data
- **Test Data**: Generates unique device tokens and user IDs
- **Success Criteria**: Successfully registers a test device

### 3. Push Notification
- **Endpoint**: `POST /notify`
- **Purpose**: Tests push notification sending
- **Test Data**: Sends notification to registered test device
- **Success Criteria**: API accepts and processes push notification

### 4. In-App Message
- **Endpoint**: `POST /notify`
- **Purpose**: Tests in-app message creation
- **Test Data**: Creates message with actions for test user
- **Success Criteria**: Successfully creates in-app message

### 5. Message Retrieval
- **Endpoint**: `GET /messages/:userId`
- **Purpose**: Tests message retrieval for users
- **Test Data**: Retrieves messages for test user
- **Success Criteria**: Returns message list (should contain in-app message)

## Dummy Data Generation

The script generates unique test data to avoid conflicts:

```bash
# Generated format (timestamp + random number)
USER_ID="test-user-1641234567-1234"
DEVICE_TOKEN="test-device-token-1641234567-1234"
```

### Why Unique IDs?
- Prevents conflicts during repeated testing
- Allows multiple script runs without cleanup
- Ensures isolated test environments
- Supports parallel testing scenarios

## Command Line Options

```bash
Usage: ./setup-verify.sh [options]

Options:
  -h, --help              Show help message
  -v, --verbose           Enable verbose output
  --api-url URL           API server URL (default: http://localhost:3000)
  --api-key KEY           API key for authentication

Environment Variables:
  NOTIFYLIGHT_API_URL     API server URL
  NOTIFYLIGHT_API_KEY     API key for authentication
```

## Output Format

### Success Output
```
✅ Health check: Server is responding
✅ Device registration: Working
✅ Push notification: Working
✅ In-app message: Working
✅ Message retrieval: Working

=== Verification Summary ===
Results:
  Total Tests: 7
  Passed: 7
  Warnings: 0
  Failed: 0
  Success Rate: 100%

✅ All tests passed! NotifyLight backend is working correctly.
```

### Failure Output
```
❌ Health check: Server is not responding
   Fix: Ensure server is running - docker-compose up -d

❌ Device registration: Failed
   Fix: Check server logs and API key configuration

=== Verification Summary ===
Results:
  Total Tests: 7
  Passed: 5
  Warnings: 0
  Failed: 2
  Success Rate: 71%

❌ Some tests failed. Please address the issues above.
```

## Error Handling

### Common Issues and Solutions

**Server Not Responding**
```bash
❌ Health check: Server is not responding
```
**Solution**: Start your NotifyLight server
```bash
docker-compose up -d
# or
npm start
```

**Invalid API Key**
```bash
❌ Device registration: Failed
```
**Solution**: Check API key configuration
```bash
# Verify .env file
cat .env | grep API_KEY

# Or set environment variable
export NOTIFYLIGHT_API_KEY="your-correct-api-key"
```

**Missing Prerequisites**
```bash
❌ curl: Not installed (required for API testing)
```
**Solution**: Install required tools
```bash
# Ubuntu/Debian
sudo apt-get install curl jq

# macOS
brew install curl jq
```

## Integration with CI/CD

### GitHub Actions
```yaml
name: NotifyLight Verification
on: [push, pull_request]

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Start NotifyLight
        run: docker-compose up -d
        
      - name: Wait for server
        run: sleep 10
        
      - name: Run verification
        run: ./setup-verify.sh --api-key ${{ secrets.NOTIFYLIGHT_API_KEY }}
        
      - name: Stop services
        run: docker-compose down
```

### Jenkins Pipeline
```groovy
pipeline {
    agent any
    
    stages {
        stage('Deploy') {
            steps {
                sh 'docker-compose up -d'
            }
        }
        
        stage('Verify') {
            steps {
                sh './setup-verify.sh --api-key ${NOTIFYLIGHT_API_KEY}'
            }
        }
    }
    
    post {
        always {
            sh 'docker-compose down'
        }
    }
}
```

## Advanced Usage

### Verbose Mode
Shows detailed request/response information:
```bash
./setup-verify.sh -v --api-key your-key
```

Output includes:
- Full HTTP request details
- Response codes and bodies
- Generated test data
- Detailed error messages

### Custom Validation
The script validates each API endpoint according to NotifyLight's specification:

```bash
# Health endpoint validation
curl -X GET http://localhost:3000/health
# Expected: 200 OK with {"status": "healthy"}

# Device registration validation
curl -X POST http://localhost:3000/register-device \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-key" \
  -d '{"token":"test-token","platform":"test","userId":"test-user"}'
# Expected: 200 OK with {"success": true}

# Notification validation
curl -X POST http://localhost:3000/notify \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-key" \
  -d '{"title":"Test","message":"Test","users":["test-user"]}'
# Expected: 200 OK with {"success": true}
```

## Security Considerations

### API Key Handling
- Never commit API keys to version control
- Use environment variables or .env files
- Rotate API keys regularly
- Use different keys for different environments

### Test Data Cleanup
The script uses temporary test data that doesn't require cleanup:
- Uses unique identifiers to avoid conflicts
- Test devices are isolated from production data
- No persistent state changes

## Troubleshooting

### Debug Mode
For debugging issues, use verbose mode:
```bash
./setup-verify.sh -v --api-key your-key
```

### Manual Testing
Test individual endpoints manually:
```bash
# Test health endpoint
curl -v http://localhost:3000/health

# Test with authentication
curl -v -H "X-API-Key: your-key" http://localhost:3000/register-device
```

### Log Analysis
Check NotifyLight server logs:
```bash
# Docker deployment
docker-compose logs -f

# Direct deployment
tail -f logs/notifylight.log
```

## Exit Codes

The script returns appropriate exit codes for automation:

- **0**: All tests passed
- **1**: One or more tests failed
- **1**: Prerequisites not met

## Support

For issues with the verification script:

1. **Check Prerequisites**: Ensure curl and jq are installed
2. **Verify Server**: Confirm NotifyLight server is running
3. **Check API Key**: Validate API key configuration
4. **Review Logs**: Check server logs for errors
5. **Use Verbose Mode**: Run with `-v` flag for detailed output

## Examples

### Production Deployment Verification
```bash
# Production server verification
./setup-verify.sh \
  --api-url https://notifications.yourcompany.com \
  --api-key $PRODUCTION_API_KEY
```

### Development Environment
```bash
# Local development verification
./setup-verify.sh -v
```

### Automated Testing
```bash
# CI/CD pipeline verification
./setup-verify.sh --api-key $CI_API_KEY && echo "Deployment successful"
```

This verification script ensures your NotifyLight backend is properly configured and ready to handle real notifications from your mobile applications.