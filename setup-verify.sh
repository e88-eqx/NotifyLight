#!/bin/bash

# NotifyLight Setup Verification Script
# Tests the full notification flow without requiring a mobile app
# Version: 2.0.0 - MVP Focus

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Unicode symbols
SUCCESS="✅"
FAILURE="❌"
WARNING="⚠️"
INFO="ℹ️"
ROCKET="🚀"

# Configuration
API_URL="${NOTIFYLIGHT_API_URL:-http://localhost:3000}"
API_KEY=""
VERBOSE=false

# Global variables
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0
TEST_USER_ID=""
TEST_DEVICE_TOKEN=""

# Helper functions
log_info() {
    echo -e "${INFO} ${BLUE}$1${NC}"
}

log_success() {
    echo -e "${SUCCESS} ${GREEN}$1${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
}

log_warning() {
    echo -e "${WARNING} ${YELLOW}$1${NC}"
    WARNING_CHECKS=$((WARNING_CHECKS + 1))
}

log_error() {
    echo -e "${FAILURE} ${RED}$1${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
}

increment_check() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
}

# Generate unique test data to avoid conflicts
generate_test_data() {
    local timestamp=$(date +%s)
    local random=$(shuf -i 1000-9999 -n 1 2>/dev/null || echo $((RANDOM % 9000 + 1000)))
    
    TEST_USER_ID="test-user-${timestamp}-${random}"
    TEST_DEVICE_TOKEN="test-device-token-${timestamp}-${random}"
    
    if [ "$VERBOSE" = true ]; then
        log_info "Generated test data:"
        log_info "  User ID: $TEST_USER_ID"
        log_info "  Device Token: $TEST_DEVICE_TOKEN"
    fi
}

# Read API key from environment or .env file
load_api_key() {
    # First try environment variable
    if [ -n "$NOTIFYLIGHT_API_KEY" ]; then
        API_KEY="$NOTIFYLIGHT_API_KEY"
        return 0
    fi
    
    # Then try .env file
    if [ -f ".env" ]; then
        API_KEY=$(grep "^API_KEY=" .env | cut -d= -f2 | tr -d '"' | tr -d "'" 2>/dev/null || echo "")
        if [ -n "$API_KEY" ]; then
            return 0
        fi
    fi
    
    # Ask user for API key
    echo -e "${YELLOW}API key not found in environment or .env file${NC}"
    echo -e "${CYAN}Please enter your API key (or press Enter to skip authenticated tests):${NC}"
    read -r API_KEY
    
    if [ -z "$API_KEY" ]; then
        log_warning "No API key provided - some tests will be skipped"
        return 1
    fi
    
    return 0
}

# Test API endpoint with proper error handling
test_api_endpoint() {
    local endpoint="$1"
    local method="${2:-GET}"
    local data="$3"
    local expected_status="${4:-200}"
    
    local url="$API_URL$endpoint"
    local headers=""
    
    if [ -n "$API_KEY" ]; then
        headers="-H X-API-Key:$API_KEY"
    fi
    
    if [ "$method" = "POST" ]; then
        headers="$headers -H Content-Type:application/json"
    fi
    
    local response
    if [ -n "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X "$method" $headers -d "$data" "$url" 2>/dev/null || echo -e "\n000")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" $headers "$url" 2>/dev/null || echo -e "\n000")
    fi
    
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')
    
    if [ "$VERBOSE" = true ]; then
        log_info "Request: $method $url"
        log_info "Response Code: $http_code"
        log_info "Response Body: $body"
    fi
    
    if [ "$http_code" = "$expected_status" ]; then
        return 0
    else
        if [ "$VERBOSE" = true ]; then
            log_error "Expected status $expected_status but got $http_code"
        fi
        return 1
    fi
}

# Check prerequisites
check_prerequisites() {
    echo -e "\n${WHITE}=== Checking Prerequisites ===${NC}"
    
    # Check curl
    increment_check
    if command -v curl &> /dev/null; then
        log_success "curl: Available"
    else
        log_error "curl: Not installed (required for API testing)"
        echo -e "   ${CYAN}Fix: Install curl - apt-get install curl (Ubuntu) or brew install curl (macOS)${NC}"
        return 1
    fi
    
    # Check jq (optional but helpful)
    increment_check
    if command -v jq &> /dev/null; then
        log_success "jq: Available (JSON parsing enabled)"
    else
        log_warning "jq: Not installed (JSON output will not be formatted)"
        echo -e "   ${CYAN}Fix: Install jq - apt-get install jq (Ubuntu) or brew install jq (macOS)${NC}"
    fi
    
    return 0
}

# Test 1: Health check (basic server response)
test_health_check() {
    echo -e "\n${WHITE}=== Test 1: Health Check ===${NC}"
    
    increment_check
    log_info "Testing basic server connectivity..."
    
    if test_api_endpoint "/health" "GET" "" "200"; then
        log_success "Health check: Server is responding"
        
        # Try to parse health response if jq is available
        if command -v jq &> /dev/null; then
            local health_response=$(curl -s "$API_URL/health" 2>/dev/null || echo "{}")
            local status=$(echo "$health_response" | jq -r '.status // "unknown"' 2>/dev/null || echo "unknown")
            local uptime=$(echo "$health_response" | jq -r '.uptime // "unknown"' 2>/dev/null || echo "unknown")
            
            log_info "Server status: $status"
            log_info "Server uptime: $uptime"
        fi
    else
        log_error "Health check: Server is not responding"
        echo -e "   ${CYAN}Fix: Ensure server is running - docker-compose up -d${NC}"
        return 1
    fi
}

# Test 2: Device registration
test_device_registration() {
    echo -e "\n${WHITE}=== Test 2: Device Registration ===${NC}"
    
    increment_check
    log_info "Testing device registration with dummy device..."
    
    if [ -z "$API_KEY" ]; then
        log_warning "Device registration: Skipped (no API key)"
        return 0
    fi
    
    local device_data=$(cat <<EOF
{
    "token": "$TEST_DEVICE_TOKEN",
    "platform": "test",
    "userId": "$TEST_USER_ID"
}
EOF
    )
    
    if test_api_endpoint "/register-device" "POST" "$device_data" "200"; then
        log_success "Device registration: Working"
        log_info "Registered device for user: $TEST_USER_ID"
    else
        log_error "Device registration: Failed"
        echo -e "   ${CYAN}Fix: Check server logs and API key configuration${NC}"
        return 1
    fi
}

# Test 3: Push notification
test_push_notification() {
    echo -e "\n${WHITE}=== Test 3: Push Notification ===${NC}"
    
    increment_check
    log_info "Testing push notification to dummy device..."
    
    if [ -z "$API_KEY" ]; then
        log_warning "Push notification: Skipped (no API key)"
        return 0
    fi
    
    local notification_data=$(cat <<EOF
{
    "title": "Test Push Notification",
    "message": "This is a test notification from NotifyLight setup verification",
    "users": ["$TEST_USER_ID"],
    "type": "push",
    "data": {
        "test": true,
        "source": "setup-verify"
    }
}
EOF
    )
    
    if test_api_endpoint "/notify" "POST" "$notification_data" "200"; then
        log_success "Push notification: Working"
        log_info "Sent push notification to user: $TEST_USER_ID"
    else
        log_error "Push notification: Failed"
        echo -e "   ${CYAN}Fix: Check notification payload format and push service configuration${NC}"
        return 1
    fi
}

# Test 4: In-app message
test_in_app_message() {
    echo -e "\n${WHITE}=== Test 4: In-App Message ===${NC}"
    
    increment_check
    log_info "Testing in-app message creation..."
    
    if [ -z "$API_KEY" ]; then
        log_warning "In-app message: Skipped (no API key)"
        return 0
    fi
    
    local message_data=$(cat <<EOF
{
    "title": "Test In-App Message",
    "message": "This is a test in-app message from NotifyLight setup verification",
    "users": ["$TEST_USER_ID"],
    "type": "in-app",
    "actions": [
        {
            "id": "test-action",
            "title": "Test Action",
            "style": "primary"
        }
    ]
}
EOF
    )
    
    if test_api_endpoint "/notify" "POST" "$message_data" "200"; then
        log_success "In-app message: Working"
        log_info "Created in-app message for user: $TEST_USER_ID"
    else
        log_error "In-app message: Failed"
        echo -e "   ${CYAN}Fix: Check message payload format and database connectivity${NC}"
        return 1
    fi
}

# Test 5: Message retrieval
test_message_retrieval() {
    echo -e "\n${WHITE}=== Test 5: Message Retrieval ===${NC}"
    
    increment_check
    log_info "Testing message retrieval for user..."
    
    if [ -z "$API_KEY" ]; then
        log_warning "Message retrieval: Skipped (no API key)"
        return 0
    fi
    
    if test_api_endpoint "/messages/$TEST_USER_ID" "GET" "" "200"; then
        log_success "Message retrieval: Working"
        
        # Try to parse message count if jq is available
        if command -v jq &> /dev/null; then
            local messages_response=$(curl -s -H "X-API-Key:$API_KEY" "$API_URL/messages/$TEST_USER_ID" 2>/dev/null || echo "{}")
            local message_count=$(echo "$messages_response" | jq -r '.count // 0' 2>/dev/null || echo "0")
            log_info "Found $message_count messages for user: $TEST_USER_ID"
        fi
    else
        log_error "Message retrieval: Failed"
        echo -e "   ${CYAN}Fix: Check user ID format and database connectivity${NC}"
        return 1
    fi
}

# Generate summary report
generate_summary() {
    echo -e "\n${WHITE}=== Verification Summary ===${NC}"
    
    local success_rate=0
    if [ "$TOTAL_CHECKS" -gt 0 ]; then
        success_rate=$(( (PASSED_CHECKS * 100) / TOTAL_CHECKS ))
    fi
    
    echo -e "${CYAN}Results:${NC}"
    echo -e "  Total Tests: $TOTAL_CHECKS"
    echo -e "  ${GREEN}Passed: $PASSED_CHECKS${NC}"
    echo -e "  ${YELLOW}Warnings: $WARNING_CHECKS${NC}"
    echo -e "  ${RED}Failed: $FAILED_CHECKS${NC}"
    echo -e "  Success Rate: ${success_rate}%"
    echo ""
    
    if [ "$FAILED_CHECKS" -eq 0 ]; then
        echo -e "${SUCCESS} ${GREEN}All tests passed! NotifyLight backend is working correctly.${NC}"
        echo ""
        echo -e "${CYAN}Next Steps:${NC}"
        echo -e "  1. Integrate NotifyLight SDK into your mobile app"
        echo -e "  2. Configure push notification certificates (APNs/FCM)"
        echo -e "  3. Test with real devices"
        echo -e "  4. Read the integration guide: QUICKSTART.md"
        echo ""
        echo -e "${CYAN}Test Your Setup:${NC}"
        echo -e "  Send a notification:"
        echo -e "    curl -X POST $API_URL/notify \\"
        echo -e "      -H 'Content-Type: application/json' \\"
        echo -e "      -H 'X-API-Key: YOUR_API_KEY' \\"
        echo -e "      -d '{\"title\":\"Hello\",\"message\":\"World!\",\"users\":[\"your-user-id\"]}'"
    else
        echo -e "${FAILURE} ${RED}Some tests failed. Please address the issues above.${NC}"
        echo ""
        echo -e "${CYAN}Common Fixes:${NC}"
        echo -e "  1. Ensure the server is running: docker-compose up -d"
        echo -e "  2. Check API key configuration in .env file"
        echo -e "  3. Verify database connectivity"
        echo -e "  4. Check server logs: docker-compose logs -f"
    fi
}

# Usage information
show_usage() {
    echo "NotifyLight Setup Verification Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -v, --verbose           Enable verbose output"
    echo "  --api-url URL           API server URL (default: http://localhost:3000)"
    echo "  --api-key KEY           API key for authentication"
    echo ""
    echo "Environment Variables:"
    echo "  NOTIFYLIGHT_API_URL     API server URL"
    echo "  NOTIFYLIGHT_API_KEY     API key for authentication"
    echo ""
    echo "Examples:"
    echo "  $0                      # Basic verification"
    echo "  $0 -v                   # Verbose output"
    echo "  $0 --api-key mykey      # Use specific API key"
    echo "  $0 --api-url http://localhost:8000  # Custom API URL"
    echo ""
    echo "Prerequisites:"
    echo "  - curl (required for API testing)"
    echo "  - jq (optional, for JSON parsing)"
    echo ""
    echo "This script tests:"
    echo "  1. Health check (basic server response)"
    echo "  2. Device registration with dummy device"
    echo "  3. Push notification to dummy device"
    echo "  4. In-app message creation"
    echo "  5. Message retrieval for user"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --api-url)
            API_URL="$2"
            shift 2
            ;;
        --api-key)
            API_KEY="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Main execution
main() {
    # Header
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║               NotifyLight Setup Verification v2.0               ║"
    echo "║                                                                  ║"
    echo "║  Tests the full notification flow without mobile app required   ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    log_info "Starting NotifyLight backend verification..."
    log_info "API URL: $API_URL"
    echo ""
    
    # Check prerequisites first
    if ! check_prerequisites; then
        log_error "Prerequisites check failed. Please install required tools."
        exit 1
    fi
    
    # Load API key
    load_api_key
    
    # Generate unique test data
    generate_test_data
    
    # Run all tests
    test_health_check
    test_device_registration
    test_push_notification
    test_in_app_message
    test_message_retrieval
    
    # Generate summary
    generate_summary
    
    # Exit with appropriate code
    if [ "$FAILED_CHECKS" -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"