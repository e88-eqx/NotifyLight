#!/bin/bash

# NotifyLight Setup Verification Script
# Bulletproof verification that catches common setup issues
# Version: 1.0.0

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
CLOCK="⏱️"
GEAR="⚙️"
DATABASE="💾"
NETWORK="🌐"
SHIELD="🛡️"

# Configuration
API_URL="${NOTIFYLIGHT_API_URL:-http://localhost:3000}"
API_KEY=""
VERBOSE=false
CHECK_PERFORMANCE=false
CHECK_PUSH_DELIVERY=false
OUTPUT_FILE=""

# Global variables for metrics
START_TIME=$(date +%s)
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# Test results storage
declare -A TEST_RESULTS
declare -A PERFORMANCE_METRICS

# Helper functions
log_header() {
    echo -e "\n${WHITE}=== $1 ===${NC}"
}

log_info() {
    echo -e "${INFO} ${BLUE}$1${NC}"
}

log_success() {
    echo -e "${SUCCESS} ${GREEN}$1${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
    TEST_RESULTS["$2"]="PASSED"
}

log_warning() {
    echo -e "${WARNING} ${YELLOW}$1${NC}"
    WARNING_CHECKS=$((WARNING_CHECKS + 1))
    TEST_RESULTS["$2"]="WARNING"
}

log_error() {
    echo -e "${FAILURE} ${RED}$1${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    TEST_RESULTS["$2"]="FAILED"
}

log_fix() {
    echo -e "   ${GEAR} ${CYAN}Fix: $1${NC}"
}

increment_check() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
}

# Utility functions
check_command() {
    if command -v "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

get_response_time() {
    local url="$1"
    local start_time=$(date +%s%3N)
    local response=$(curl -s -w "\n%{http_code}" "$url" 2>/dev/null || echo "000")
    local end_time=$(date +%s%3N)
    local response_time=$((end_time - start_time))
    
    echo "$response_time"
}

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
    
    local start_time=$(date +%s%3N)
    local response
    if [ -n "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X "$method" $headers -d "$data" "$url" 2>/dev/null || echo -e "\n000")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" $headers "$url" 2>/dev/null || echo -e "\n000")
    fi
    local end_time=$(date +%s%3N)
    
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | head -n -1)
    local response_time=$((end_time - start_time))
    
    PERFORMANCE_METRICS["${endpoint}_response_time"]="$response_time"
    
    if [ "$http_code" = "$expected_status" ]; then
        return 0
    else
        return 1
    fi
}

# Dependency checks
check_dependencies() {
    log_header "Dependency Checks ${GEAR}"
    
    # Check Docker
    increment_check
    if check_command docker; then
        local docker_version=$(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
        log_success "Docker: Running ($docker_version)" "docker"
    else
        log_error "Docker: Not installed or not in PATH" "docker"
        log_fix "Install Docker Desktop: https://www.docker.com/products/docker-desktop/"
    fi
    
    # Check Docker Compose
    increment_check
    if check_command docker-compose; then
        local compose_version=$(docker-compose --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
        log_success "Docker Compose: Available ($compose_version)" "docker_compose"
    else
        log_error "Docker Compose: Not installed" "docker_compose"
        log_fix "Install Docker Compose: https://docs.docker.com/compose/install/"
    fi
    
    # Check curl
    increment_check
    if check_command curl; then
        local curl_version=$(curl --version | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
        log_success "curl: Available ($curl_version)" "curl"
    else
        log_error "curl: Not installed" "curl"
        log_fix "Install curl: apt-get install curl (Ubuntu) or brew install curl (macOS)"
    fi
    
    # Check jq (optional but recommended)
    increment_check
    if check_command jq; then
        local jq_version=$(jq --version | grep -oE '[0-9]+\.[0-9]+' | head -n1)
        log_success "jq: Available ($jq_version) - JSON parsing enabled" "jq"
    else
        log_warning "jq: Not installed - JSON output will not be formatted" "jq"
        log_fix "Install jq: apt-get install jq (Ubuntu) or brew install jq (macOS)"
    fi
    
    # Check Node.js (for SDK development)
    increment_check
    if check_command node; then
        local node_version=$(node --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
        local major_version=$(echo "$node_version" | cut -d. -f1)
        if [ "$major_version" -ge 16 ]; then
            log_success "Node.js: Available ($node_version)" "nodejs"
        else
            log_warning "Node.js: Version $node_version (recommend 16+)" "nodejs"
            log_fix "Update Node.js: https://nodejs.org/ or use nvm"
        fi
    else
        log_warning "Node.js: Not installed (needed for SDK development)" "nodejs"
        log_fix "Install Node.js: https://nodejs.org/"
    fi
}

# Docker service checks
check_docker_services() {
    log_header "Docker Services ${ROCKET}"
    
    # Check if Docker daemon is running
    increment_check
    if docker info &> /dev/null; then
        log_success "Docker Daemon: Running" "docker_daemon"
    else
        log_error "Docker Daemon: Not running" "docker_daemon"
        log_fix "Start Docker Desktop or run: sudo systemctl start docker"
        return 1
    fi
    
    # Check for NotifyLight containers
    increment_check
    local containers=$(docker ps --filter "name=notifylight" --format "table {{.Names}}\t{{.Status}}" 2>/dev/null || echo "")
    if [ -n "$containers" ] && [ "$containers" != "NAMES	STATUS" ]; then
        log_success "NotifyLight Containers: Running" "containers"
        if [ "$VERBOSE" = true ]; then
            echo "$containers"
        fi
    else
        log_warning "NotifyLight Containers: Not found or not running" "containers"
        log_fix "Run: docker-compose up -d"
    fi
    
    # Check container health
    increment_check
    local unhealthy=$(docker ps --filter "health=unhealthy" --filter "name=notifylight" --format "{{.Names}}" 2>/dev/null || echo "")
    if [ -z "$unhealthy" ]; then
        log_success "Container Health: All healthy" "container_health"
    else
        log_error "Container Health: Unhealthy containers found: $unhealthy" "container_health"
        log_fix "Check logs: docker-compose logs $unhealthy"
    fi
}

# API server checks
check_api_server() {
    log_header "API Server ${NETWORK}"
    
    # Basic connectivity
    increment_check
    local response_time=$(get_response_time "$API_URL")
    if [ "$response_time" -gt 0 ] && [ "$response_time" -lt 10000 ]; then
        log_success "API Server: Responding (${response_time}ms)" "api_connectivity"
    else
        log_error "API Server: Not responding or timeout" "api_connectivity"
        log_fix "Check if server is running: docker-compose ps"
        log_fix "Check logs: docker-compose logs -f"
        return 1
    fi
    
    # Health endpoint
    increment_check
    if test_api_endpoint "/health"; then
        log_success "Health Endpoint: Available" "health_endpoint"
    else
        log_error "Health Endpoint: Failed" "health_endpoint"
        log_fix "Verify server configuration and restart: docker-compose restart"
    fi
    
    # Try to detect API key from .env
    if [ -z "$API_KEY" ] && [ -f ".env" ]; then
        API_KEY=$(grep "^API_KEY=" .env | cut -d= -f2 | tr -d '"' || echo "")
    fi
    
    # API key validation
    increment_check
    if [ -n "$API_KEY" ]; then
        if test_api_endpoint "/validate"; then
            log_success "API Key: Valid (${API_KEY:0:8}...)" "api_key"
        else
            log_error "API Key: Invalid or expired" "api_key"
            log_fix "Check API_KEY in .env file"
            log_fix "Generate new key: openssl rand -hex 32"
        fi
    else
        log_warning "API Key: Not provided (some tests will be skipped)" "api_key"
        log_fix "Set API_KEY environment variable or add to .env file"
    fi
}

# Database checks
check_database() {
    log_header "Database ${DATABASE}"
    
    if [ -n "$API_KEY" ]; then
        # Database connectivity (via stats endpoint)
        increment_check
        if test_api_endpoint "/stats"; then
            log_success "Database: Connected" "database_connection"
            
            # Extract database stats if jq is available
            if check_command jq; then
                local stats_response=$(curl -s -H "X-API-Key:$API_KEY" "$API_URL/stats" 2>/dev/null || echo "{}")
                local device_count=$(echo "$stats_response" | jq -r '.stats.devices // 0' 2>/dev/null || echo "0")
                local message_count=$(echo "$stats_response" | jq -r '.stats.messages // 0' 2>/dev/null || echo "0")
                local notification_count=$(echo "$stats_response" | jq -r '.stats.notifications // 0' 2>/dev/null || echo "0")
                
                log_info "Database Stats: $device_count devices, $message_count messages, $notification_count notifications"
            fi
        else
            log_error "Database: Connection failed" "database_connection"
            log_fix "Check database configuration in docker-compose.yml"
        fi
        
        # Database file check (for SQLite)
        increment_check
        if [ -f "data/notifylight.db" ] || [ -f "./data/notifylight.db" ]; then
            local db_size=$(du -h data/notifylight.db 2>/dev/null | cut -f1 || echo "unknown")
            log_success "Database File: Found (${db_size})" "database_file"
        else
            log_warning "Database File: Not found (may use in-memory)" "database_file"
            log_fix "Check if persistent volume is mounted correctly"
        fi
    else
        log_warning "Database: Skipped (no API key)" "database_connection"
        log_warning "Database File: Skipped (no API key)" "database_file"
        increment_check
        increment_check
    fi
}

# Performance checks
check_performance() {
    if [ "$CHECK_PERFORMANCE" = false ]; then
        return 0
    fi
    
    log_header "Performance Metrics ${CLOCK}"
    
    if [ -n "$API_KEY" ]; then
        # Response time benchmarks
        log_info "Running performance benchmarks..."
        
        local endpoints=("/health" "/validate" "/stats")
        local total_time=0
        local test_count=0
        
        for endpoint in "${endpoints[@]}"; do
            increment_check
            local avg_time=0
            local iterations=5
            
            for ((i=1; i<=iterations; i++)); do
                local response_time=$(get_response_time "$API_URL$endpoint")
                avg_time=$((avg_time + response_time))
            done
            
            avg_time=$((avg_time / iterations))
            total_time=$((total_time + avg_time))
            test_count=$((test_count + 1))
            
            if [ "$avg_time" -lt 200 ]; then
                log_success "$endpoint: ${avg_time}ms average (excellent)" "perf_${endpoint//\//_}"
            elif [ "$avg_time" -lt 500 ]; then
                log_warning "$endpoint: ${avg_time}ms average (acceptable)" "perf_${endpoint//\//_}"
            else
                log_error "$endpoint: ${avg_time}ms average (too slow)" "perf_${endpoint//\//_}"
                log_fix "Check server resources and network connectivity"
            fi
        done
        
        local overall_avg=$((total_time / test_count))
        PERFORMANCE_METRICS["overall_response_time"]="$overall_avg"
        
        log_info "Overall Average Response Time: ${overall_avg}ms"
    else
        log_warning "Performance: Skipped (no API key)" "performance"
        increment_check
    fi
}

# Security checks
check_security() {
    log_header "Security Checks ${SHIELD}"
    
    # CORS configuration
    increment_check
    local cors_response=$(curl -s -H "Origin: http://localhost:3001" -H "Access-Control-Request-Method: POST" -H "Access-Control-Request-Headers: X-API-Key" -X OPTIONS "$API_URL/notify" 2>/dev/null || echo "")
    if echo "$cors_response" | grep -q "Access-Control-Allow-Origin"; then
        log_success "CORS: Configured correctly" "cors"
    else
        log_warning "CORS: May not be configured (check if frontend access needed)" "cors"
        log_fix "Configure CORS in server settings for frontend access"
    fi
    
    # Rate limiting test
    increment_check
    if [ -n "$API_KEY" ]; then
        log_info "Testing rate limiting (this may take a moment)..."
        local rate_limit_hit=false
        
        for ((i=1; i<=10; i++)); do
            local response=$(curl -s -w "%{http_code}" -H "X-API-Key:$API_KEY" "$API_URL/health" 2>/dev/null || echo "000")
            if [ "$response" = "429" ]; then
                rate_limit_hit=true
                break
            fi
            sleep 0.1
        done
        
        if [ "$rate_limit_hit" = true ]; then
            log_success "Rate Limiting: Working (429 response received)" "rate_limiting"
        else
            log_warning "Rate Limiting: Not detected (may be disabled)" "rate_limiting"
            log_fix "Consider enabling rate limiting for production use"
        fi
    else
        log_warning "Rate Limiting: Skipped (no API key)" "rate_limiting"
    fi
    
    # API key strength check
    increment_check
    if [ -n "$API_KEY" ]; then
        local key_length=${#API_KEY}
        if [ "$key_length" -ge 32 ]; then
            log_success "API Key Strength: Strong (${key_length} characters)" "api_key_strength"
        elif [ "$key_length" -ge 16 ]; then
            log_warning "API Key Strength: Moderate (${key_length} characters)" "api_key_strength"
            log_fix "Consider using a longer API key (32+ characters)"
        else
            log_error "API Key Strength: Weak (${key_length} characters)" "api_key_strength"
            log_fix "Generate a stronger API key: openssl rand -hex 32"
        fi
    else
        log_warning "API Key Strength: Cannot check (no key provided)" "api_key_strength"
    fi
}

# Push service validation
check_push_services() {
    log_header "Push Services Configuration ${ROCKET}"
    
    # Check for credential files
    increment_check
    local apns_configured=false
    local fcm_configured=false
    
    # APNs check
    if [ -f "credentials/apns-key.p8" ] || [ -f ".env" ] && grep -q "APNS_KEY_PATH" .env; then
        log_success "APNs: Credentials found" "apns_config"
        apns_configured=true
    else
        log_warning "APNs: No credentials found" "apns_config"
        log_fix "Add APNs credentials: see setup-certificates.md"
    fi
    
    # FCM check
    increment_check
    if [ -f "credentials/fcm-service-account.json" ] || [ -f ".env" ] && grep -q "FCM_SERVICE_ACCOUNT_PATH" .env; then
        log_success "FCM: Credentials found" "fcm_config"
        fcm_configured=true
    else
        log_warning "FCM: No credentials found" "fcm_config"
        log_fix "Add FCM credentials: see setup-certificates.md"
    fi
    
    # Mock mode check
    increment_check
    if [ -f ".env" ] && grep -q "ENABLE_MOCK_PUSH=true" .env; then
        log_warning "Push Services: Running in mock mode" "push_mode"
        log_fix "Disable mock mode and add real credentials for production"
    elif [ "$apns_configured" = true ] || [ "$fcm_configured" = true ]; then
        log_success "Push Services: Real credentials configured" "push_mode"
    else
        log_error "Push Services: No credentials configured" "push_mode"
        log_fix "Configure APNs/FCM credentials or enable mock mode for testing"
    fi
}

# Functional tests
run_functional_tests() {
    if [ -z "$API_KEY" ]; then
        log_warning "Functional Tests: Skipped (no API key)" "functional_tests"
        return 0
    fi
    
    log_header "Functional Tests ${GEAR}"
    
    # Device registration test
    increment_check
    local test_device_data='{"token":"test-verification-token","platform":"test","user_id":"verify-user"}'
    if test_api_endpoint "/register-device" "POST" "$test_device_data" "200"; then
        log_success "Device Registration: Working" "device_registration"
    else
        log_error "Device Registration: Failed" "device_registration"
        log_fix "Check server logs: docker-compose logs -f"
    fi
    
    # Notification sending test
    increment_check
    local test_notification='{"title":"Verification Test","message":"NotifyLight verification","users":["verify-user"],"type":"push"}'
    if test_api_endpoint "/notify" "POST" "$test_notification" "200"; then
        log_success "Notification Sending: Working" "notification_sending"
    else
        log_error "Notification Sending: Failed" "notification_sending"
        log_fix "Check notification payload format and server configuration"
    fi
    
    # Message retrieval test
    increment_check
    if test_api_endpoint "/messages/verify-user" "GET" "" "200"; then
        log_success "Message Retrieval: Working" "message_retrieval"
    else
        log_error "Message Retrieval: Failed" "message_retrieval"
        log_fix "Check user ID format and database connectivity"
    fi
}

# Generate test report
generate_report() {
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    
    log_header "Verification Report ${INFO}"
    
    echo -e "${WHITE}NotifyLight Setup Verification v1.0${NC}"
    echo -e "${WHITE}=$(printf '=%.0s' {1..50})${NC}"
    echo ""
    
    # Summary statistics
    echo -e "${CYAN}Summary:${NC}"
    echo -e "  Total Checks: $TOTAL_CHECKS"
    echo -e "  ${GREEN}Passed: $PASSED_CHECKS${NC}"
    echo -e "  ${YELLOW}Warnings: $WARNING_CHECKS${NC}"
    echo -e "  ${RED}Failed: $FAILED_CHECKS${NC}"
    echo -e "  Duration: ${duration}s"
    echo ""
    
    # Overall status
    if [ "$FAILED_CHECKS" -eq 0 ]; then
        if [ "$WARNING_CHECKS" -eq 0 ]; then
            echo -e "${SUCCESS} ${GREEN}All tests passed! NotifyLight is ready to use.${NC}"
        else
            echo -e "${WARNING} ${YELLOW}Setup complete with warnings. Review warnings above.${NC}"
        fi
    else
        echo -e "${FAILURE} ${RED}Setup has issues. Please fix the failed tests above.${NC}"
    fi
    echo ""
    
    # Performance metrics
    if [ ${#PERFORMANCE_METRICS[@]} -gt 0 ]; then
        echo -e "${CYAN}Performance Metrics:${NC}"
        for metric in "${!PERFORMANCE_METRICS[@]}"; do
            echo -e "  ${metric}: ${PERFORMANCE_METRICS[$metric]}ms"
        done
        echo ""
    fi
    
    # Next steps
    echo -e "${CYAN}Next Steps:${NC}"
    if [ "$FAILED_CHECKS" -eq 0 ]; then
        echo -e "  ${SUCCESS} Send your first notification: curl -X POST $API_URL/notify \\"
        echo -e "    -H 'Content-Type: application/json' \\"
        echo -e "    -H 'X-API-Key: YOUR_API_KEY' \\"
        echo -e "    -d '{\"title\":\"Test\",\"message\":\"Hello World!\",\"users\":[\"test-user\"]}'"
        echo -e "  ${SUCCESS} Read the full documentation: docs/README.md"
        echo -e "  ${SUCCESS} Try the quickstart guide: QUICKSTART.md"
    else
        echo -e "  ${FAILURE} Fix the failed tests listed above"
        echo -e "  ${FAILURE} Check troubleshooting guide: docs/TROUBLESHOOTING.md"
        echo -e "  ${FAILURE} Review server logs: docker-compose logs -f"
    fi
    echo ""
    
    # Save report to file if requested
    if [ -n "$OUTPUT_FILE" ]; then
        {
            echo "NotifyLight Setup Verification Report"
            echo "Generated: $(date)"
            echo "Duration: ${duration}s"
            echo ""
            echo "Summary:"
            echo "  Total: $TOTAL_CHECKS, Passed: $PASSED_CHECKS, Warnings: $WARNING_CHECKS, Failed: $FAILED_CHECKS"
            echo ""
            echo "Test Results:"
            for test in "${!TEST_RESULTS[@]}"; do
                echo "  $test: ${TEST_RESULTS[$test]}"
            done
            if [ ${#PERFORMANCE_METRICS[@]} -gt 0 ]; then
                echo ""
                echo "Performance Metrics:"
                for metric in "${!PERFORMANCE_METRICS[@]}"; do
                    echo "  $metric: ${PERFORMANCE_METRICS[$metric]}ms"
                done
            fi
        } > "$OUTPUT_FILE"
        
        log_info "Report saved to: $OUTPUT_FILE"
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
    echo "  -p, --performance       Include performance benchmarks"
    echo "  -d, --push-delivery     Test actual push delivery (requires credentials)"
    echo "  -o, --output FILE       Save report to file"
    echo "  --api-url URL           API server URL (default: http://localhost:3000)"
    echo "  --api-key KEY           API key for authentication"
    echo ""
    echo "Environment Variables:"
    echo "  NOTIFYLIGHT_API_URL     API server URL"
    echo "  NOTIFYLIGHT_API_KEY     API key for authentication"
    echo ""
    echo "Examples:"
    echo "  $0                      # Basic verification"
    echo "  $0 -v -p               # Verbose with performance tests"
    echo "  $0 --api-key mykey     # Use specific API key"
    echo "  $0 -o report.txt       # Save report to file"
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
        -p|--performance)
            CHECK_PERFORMANCE=true
            shift
            ;;
        -d|--push-delivery)
            CHECK_PUSH_DELIVERY=true
            shift
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
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
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║              NotifyLight Setup Verification v1.0             ║"
    echo "║                                                               ║"
    echo "║  Bulletproof verification for your NotifyLight installation  ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    log_info "Starting verification of NotifyLight installation..."
    log_info "API URL: $API_URL"
    if [ -n "$API_KEY" ]; then
        log_info "API Key: ${API_KEY:0:8}... (provided)"
    else
        log_info "API Key: Not provided (will try to detect from .env)"
    fi
    echo ""
    
    # Run all checks
    check_dependencies
    check_docker_services
    check_api_server
    check_database
    check_security
    check_push_services
    run_functional_tests
    check_performance
    
    # Generate final report
    generate_report
    
    # Exit with appropriate code
    if [ "$FAILED_CHECKS" -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"