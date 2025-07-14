#!/bin/bash

# NotifyLight Push Notification Tester
# A script to test various notification scenarios with the NotifyLight API

set -e

# Configuration
API_URL="${NOTIFYLIGHT_API_URL:-http://localhost:3000}"
API_KEY="${NOTIFYLIGHT_API_KEY:-test-api-key-123}"
USER_ID="${NOTIFYLIGHT_USER_ID:-test-user}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check dependencies
check_dependencies() {
    if ! command -v curl &> /dev/null; then
        log_error "curl is required but not installed"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_warning "jq is not installed - JSON responses will not be formatted"
        JQ_AVAILABLE=false
    else
        JQ_AVAILABLE=true
    fi
}

# Format JSON output
format_json() {
    if [ "$JQ_AVAILABLE" = true ]; then
        echo "$1" | jq '.'
    else
        echo "$1"
    fi
}

# Test server health
test_health() {
    log_info "Testing server health..."
    
    response=$(curl -s -w "\n%{http_code}" "$API_URL/health" || echo "000")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "200" ]; then
        log_success "Server is healthy"
        format_json "$body"
    else
        log_error "Server health check failed (HTTP $http_code)"
        echo "$body"
        return 1
    fi
}

# Validate API key
validate_api_key() {
    log_info "Validating API key..."
    
    response=$(curl -s -w "\n%{http_code}" \
        -H "X-API-Key: $API_KEY" \
        "$API_URL/validate" || echo "000")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "200" ]; then
        log_success "API key is valid"
        format_json "$body"
    else
        log_error "API key validation failed (HTTP $http_code)"
        echo "$body"
        return 1
    fi
}

# Send basic push notification
send_push_notification() {
    local title="${1:-Test Notification}"
    local message="${2:-This is a test notification from push-tester.sh}"
    local users="${3:-[\"$USER_ID\"]}"
    
    log_info "Sending push notification..."
    log_info "Title: $title"
    log_info "Message: $message"
    log_info "Users: $users"
    
    response=$(curl -s -w "\n%{http_code}" \
        -X POST \
        -H "Content-Type: application/json" \
        -H "X-API-Key: $API_KEY" \
        -d "{
            \"title\": \"$title\",
            \"message\": \"$message\",
            \"users\": $users,
            \"type\": \"push\"
        }" \
        "$API_URL/notify" || echo "000")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "200" ]; then
        log_success "Push notification sent successfully"
        format_json "$body"
    else
        log_error "Failed to send push notification (HTTP $http_code)"
        echo "$body"
        return 1
    fi
}

# Send in-app message
send_in_app_message() {
    local title="${1:-Test In-App Message}"
    local message="${2:-This is a test in-app message with actions}"
    local users="${3:-[\"$USER_ID\"]}"
    
    log_info "Sending in-app message..."
    log_info "Title: $title"
    log_info "Message: $message"
    log_info "Users: $users"
    
    response=$(curl -s -w "\n%{http_code}" \
        -X POST \
        -H "Content-Type: application/json" \
        -H "X-API-Key: $API_KEY" \
        -d "{
            \"title\": \"$title\",
            \"message\": \"$message\",
            \"users\": $users,
            \"type\": \"in-app\",
            \"actions\": [
                {\"id\": \"ok\", \"title\": \"OK\", \"style\": \"primary\"},
                {\"id\": \"later\", \"title\": \"Maybe Later\", \"style\": \"secondary\"}
            ],
            \"data\": {
                \"test_id\": \"push-tester-$(date +%s)\",
                \"source\": \"push-tester.sh\"
            }
        }" \
        "$API_URL/notify" || echo "000")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "200" ]; then
        log_success "In-app message sent successfully"
        format_json "$body"
    else
        log_error "Failed to send in-app message (HTTP $http_code)"
        echo "$body"
        return 1
    fi
}

# Create test messages
create_test_messages() {
    local user_id="${1:-$USER_ID}"
    local count="${2:-3}"
    
    log_info "Creating $count test messages for user: $user_id"
    
    response=$(curl -s -w "\n%{http_code}" \
        -X POST \
        -H "Content-Type: application/json" \
        -H "X-API-Key: $API_KEY" \
        -d "{
            \"userId\": \"$user_id\",
            \"count\": $count
        }" \
        "$API_URL/test/create-messages" || echo "000")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "200" ]; then
        log_success "Test messages created successfully"
        format_json "$body"
    else
        log_error "Failed to create test messages (HTTP $http_code)"
        echo "$body"
        return 1
    fi
}

# Get user messages
get_user_messages() {
    local user_id="${1:-$USER_ID}"
    
    log_info "Fetching messages for user: $user_id"
    
    response=$(curl -s -w "\n%{http_code}" \
        -H "X-API-Key: $API_KEY" \
        "$API_URL/messages/$user_id" || echo "000")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "200" ]; then
        log_success "Messages retrieved successfully"
        format_json "$body"
    else
        log_error "Failed to retrieve messages (HTTP $http_code)"
        echo "$body"
        return 1
    fi
}

# Get server stats
get_server_stats() {
    log_info "Fetching server statistics..."
    
    response=$(curl -s -w "\n%{http_code}" \
        -H "X-API-Key: $API_KEY" \
        "$API_URL/stats" || echo "000")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "200" ]; then
        log_success "Server statistics retrieved"
        format_json "$body"
    else
        log_error "Failed to retrieve server statistics (HTTP $http_code)"
        echo "$body"
        return 1
    fi
}

# Clear test data
clear_test_data() {
    log_info "Clearing all test data..."
    
    response=$(curl -s -w "\n%{http_code}" \
        -X POST \
        -H "X-API-Key: $API_KEY" \
        "$API_URL/test/clear" || echo "000")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "200" ]; then
        log_success "Test data cleared successfully"
        format_json "$body"
    else
        log_error "Failed to clear test data (HTTP $http_code)"
        echo "$body"
        return 1
    fi
}

# Run comprehensive test suite
run_test_suite() {
    log_info "Starting comprehensive test suite..."
    echo "=================================="
    
    # Test server health
    if ! test_health; then
        log_error "Health check failed - aborting test suite"
        return 1
    fi
    
    echo ""
    
    # Validate API key
    if ! validate_api_key; then
        log_error "API key validation failed - aborting test suite"
        return 1
    fi
    
    echo ""
    
    # Clear existing test data
    clear_test_data
    echo ""
    
    # Send basic push notification
    send_push_notification "Test Suite Push" "Testing basic push notification functionality"
    echo ""
    
    # Send in-app message
    send_in_app_message "Test Suite Message" "Testing in-app message with actions"
    echo ""
    
    # Create test messages
    create_test_messages "$USER_ID" 5
    echo ""
    
    # Get user messages
    get_user_messages "$USER_ID"
    echo ""
    
    # Get server stats
    get_server_stats
    echo ""
    
    log_success "Test suite completed successfully!"
}

# Show usage information
show_usage() {
    echo "NotifyLight Push Notification Tester"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  health                          Test server health"
    echo "  validate                        Validate API key"
    echo "  push [title] [message] [users]  Send push notification"
    echo "  message [title] [msg] [users]   Send in-app message"
    echo "  create [user_id] [count]        Create test messages"
    echo "  get [user_id]                   Get user messages"
    echo "  stats                           Get server statistics"
    echo "  clear                           Clear test data"
    echo "  suite                           Run full test suite"
    echo "  help                            Show this help"
    echo ""
    echo "Environment Variables:"
    echo "  NOTIFYLIGHT_API_URL             API server URL (default: http://localhost:3000)"
    echo "  NOTIFYLIGHT_API_KEY             API key (default: test-api-key-123)"
    echo "  NOTIFYLIGHT_USER_ID             User ID for tests (default: test-user)"
    echo ""
    echo "Examples:"
    echo "  $0 health"
    echo "  $0 push \"Hello\" \"World\" '[\"user1\", \"user2\"]'"
    echo "  $0 message \"Update\" \"New features available\""
    echo "  $0 create test-user 5"
    echo "  $0 suite"
}

# Main script logic
main() {
    check_dependencies
    
    case "${1:-help}" in
        "health")
            test_health
            ;;
        "validate")
            validate_api_key
            ;;
        "push")
            send_push_notification "$2" "$3" "$4"
            ;;
        "message")
            send_in_app_message "$2" "$3" "$4"
            ;;
        "create")
            create_test_messages "$2" "$3"
            ;;
        "get")
            get_user_messages "$2"
            ;;
        "stats")
            get_server_stats
            ;;
        "clear")
            clear_test_data
            ;;
        "suite")
            run_test_suite
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            log_error "Unknown command: $1"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Print header
echo "🚀 NotifyLight Push Notification Tester"
echo "API URL: $API_URL"
echo "API Key: ${API_KEY:0:8}..."
echo "User ID: $USER_ID"
echo ""

# Run main function with all arguments
main "$@"