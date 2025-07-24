#!/bin/bash

# Test script for 1Password setup verification
# This script verifies that all required 1Password items are present and accessible

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Function to check if 1Password CLI is installed and authenticated
check_1password() {
    print_header "Checking 1Password CLI"
    
    if ! command -v op &> /dev/null; then
        print_error "1Password CLI is not installed"
        echo "Please install it first:"
        echo "  macOS: brew install 1password-cli"
        echo "  Linux: https://1password.com/downloads/command-line/"
        echo "  Windows: https://1password.com/downloads/command-line/"
        return 1
    fi
    
    print_status "1Password CLI is installed"
    
    if ! op account list &> /dev/null; then
        print_error "1Password CLI is not authenticated"
        echo "Please run 'op signin' first"
        return 1
    fi
    
    print_status "1Password CLI is authenticated"
    return 0
}

# Function to test item access
test_item() {
    local item_name="$1"
    local vault="$2"
    local description="$3"
    
    print_status "Testing access to: $item_name ($description)"
    
    if op item get "$item_name" --vault "$vault" &> /dev/null; then
        print_status "✓ $item_name is accessible"
        
        # Test field access
        local fields
        case "$item_name" in
            "dshield-misp-misp")
                fields=("FQDN" "email" "password" "org" "baseurl")
                ;;
            "dshield-misp-database")
                fields=("root_password" "database" "username" "password")
                ;;
            "dshield-misp-o365")
                fields=("client_id" "client_secret" "tenant_id" "sender_email")
                ;;
            *)
                print_warning "Unknown item type: $item_name"
                return 0
                ;;
        esac
        
        local missing_fields=()
        for field in "${fields[@]}"; do
            if ! op item get "$item_name" --vault "$vault" --fields "$field" &> /dev/null; then
                missing_fields+=("$field")
            fi
        done
        
        if [ ${#missing_fields[@]} -eq 0 ]; then
            print_status "✓ All required fields are present"
        else
            print_warning "Missing fields: ${missing_fields[*]}"
        fi
        
        return 0
    else
        print_error "✗ $item_name is not accessible"
        return 1
    fi
}

# Function to test environment loading
test_environment() {
    print_header "Testing Environment Loading"
    
    if [ ! -f "load-1password-env.sh" ]; then
        print_error "load-1password-env.sh not found in current directory"
        return 1
    fi
    
    print_status "Found load-1password-env.sh"
    
    # Source the script and test variables
    source load-1password-env.sh
    
    local required_vars=(
        "MISP_FQDN"
        "MISP_EMAIL"
        "MISP_PASSWORD"
        "MISP_ORG"
        "MISP_BASEURL"
        "MYSQL_ROOT_PASSWORD"
        "MYSQL_DATABASE"
        "MYSQL_USER"
        "MYSQL_PASSWORD"
    )
    
    local missing_vars=()
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -eq 0 ]; then
        print_status "✓ All required environment variables are set"
        
        # Show some non-sensitive values
        echo "  MISP_FQDN: $MISP_FQDN"
        echo "  MISP_EMAIL: $MISP_EMAIL"
        echo "  MISP_ORG: $MISP_ORG"
        echo "  MYSQL_DATABASE: $MYSQL_DATABASE"
        echo "  MYSQL_USER: $MYSQL_USER"
        
        return 0
    else
        print_warning "Missing environment variables: ${missing_vars[*]}"
        return 1
    fi
}

# Function to test docker-compose integration
test_docker_compose() {
    print_header "Testing Docker Compose Integration"
    
    if [ ! -f "docker-compose.yml" ]; then
        print_warning "docker-compose.yml not found in current directory"
        return 1
    fi
    
    print_status "Found docker-compose.yml"
    
    # Test if docker-compose can read the environment variables
    if command -v docker-compose &> /dev/null; then
        print_status "Docker Compose is available"
        
        # Test configuration without actually starting containers
        if docker-compose config &> /dev/null; then
            print_status "✓ Docker Compose configuration is valid"
            return 0
        else
            print_warning "Docker Compose configuration has issues"
            return 1
        fi
    else
        print_warning "Docker Compose is not installed"
        return 1
    fi
}

# Function to show vault information
show_vault_info() {
    print_header "Vault Information"
    
    local vaults
    vaults=$(op vault list --format=json 2>/dev/null || echo "[]")
    
    if [ "$vaults" != "[]" ]; then
        print_status "Available vaults:"
        echo "$vaults" | jq -r '.[] | "  - \(.name) (\(.item_count) items)"'
    else
        print_warning "No vaults found or accessible"
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -v, --vault VAULT     Specify vault name to test (default: Private)"
    echo "  -e, --env-only        Test environment loading only"
    echo "  -d, --docker-only     Test Docker Compose integration only"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run all tests"
    echo "  $0 --vault Work       # Test items in Work vault"
    echo "  $0 --env-only         # Test environment loading only"
}

# Main script logic
main() {
    print_header "1Password Setup Test for dshield-misp"
    
    # Parse command line arguments
    local vault="Private"
    local env_only=false
    local docker_only=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--vault)
                vault="$2"
                shift 2
                ;;
            -e|--env-only)
                env_only=true
                shift
                ;;
            -d|--docker-only)
                docker_only=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    print_status "Testing vault: $vault"
    
    # Check 1Password CLI
    if ! check_1password; then
        exit 1
    fi
    
    # Show vault information
    show_vault_info
    
    if [ "$env_only" = true ]; then
        test_environment
        exit $?
    fi
    
    if [ "$docker_only" = true ]; then
        test_docker_compose
        exit $?
    fi
    
    # Test all required items
    print_header "Testing Required Items"
    
    local items=(
        "dshield-misp-misp:MISP Configuration"
        "dshield-misp-database:Database Configuration"
        "dshield-misp-o365:Office365 Configuration"
    )
    
    local failed_tests=0
    
    for item_info in "${items[@]}"; do
        IFS=':' read -r item_name description <<< "$item_info"
        
        if ! test_item "$item_name" "$vault" "$description"; then
            ((failed_tests++))
        fi
    done
    
    # Test environment loading
    if ! test_environment; then
        ((failed_tests++))
    fi
    
    # Test Docker Compose integration
    if ! test_docker_compose; then
        ((failed_tests++))
    fi
    
    # Summary
    print_header "Test Summary"
    
    if [ $failed_tests -eq 0 ]; then
        print_status "✓ All tests passed! Your 1Password setup is working correctly."
        echo ""
        echo "You can now use:"
        echo "  source load-1password-env.sh && docker-compose up -d"
        exit 0
    else
        print_error "✗ $failed_tests test(s) failed. Please check the issues above."
        echo ""
        echo "Common solutions:"
        echo "  1. Run ./setup-1password.sh to create missing items"
        echo "  2. Run ./import-1password-items.sh to import existing items"
        echo "  3. Check your 1Password authentication: op signin"
        exit 1
    fi
}

# Run main function with all arguments
main "$@" 