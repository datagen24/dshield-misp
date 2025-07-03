#!/bin/bash

# 1Password Setup Script for dshield-misp
# This script helps set up all required secrets in 1Password for the dshield-misp project

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DEFAULT_VAULT="Private"
DEFAULT_MISP_FQDN="misp.local"
DEFAULT_MISP_EMAIL="admin@example.com"
DEFAULT_MISP_PASSWORD="admin"
DEFAULT_MISP_ORG="ORGNAME"
DEFAULT_MISP_BASEURL="https://misp.local"
DEFAULT_DB_NAME="misp"
DEFAULT_DB_USER="misp"
DEFAULT_DB_PASSWORD="misp"
DEFAULT_DB_ROOT_PASSWORD="misproot"

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
    if ! command -v op &> /dev/null; then
        print_error "1Password CLI is not installed. Please install it first:"
        echo "  macOS: brew install 1password-cli"
        echo "  Linux: https://1password.com/downloads/command-line/"
        echo "  Windows: https://1password.com/downloads/command-line/"
        exit 1
    fi

    if ! op account list &> /dev/null; then
        print_error "1Password CLI is not authenticated. Please run 'op signin' first."
        exit 1
    fi
}

# Function to get vault name
get_vault() {
    if [ -n "$1" ]; then
        VAULT="$1"
    else
        echo -n "Enter vault name (default: $DEFAULT_VAULT): " >&2
        if [ -t 0 ]; then
            read -r input_vault
        else
            input_vault="$DEFAULT_VAULT"
            echo "$DEFAULT_VAULT (non-interactive mode)" >&2
        fi
        VAULT="${input_vault:-$DEFAULT_VAULT}"
    fi
    
    # Check if vault exists, create if it doesn't
    if ! op vault list | grep -q "$VAULT"; then
        print_warning "Vault '$VAULT' does not exist. Creating it..."
        op vault create "$VAULT"
    fi
}

# Function to prompt for input with default value
prompt_input() {
    local prompt="$1"
    local default="$2"
    local secret="$3"
    local allow_regenerate="$4"
    
    # Ensure we're reading from the terminal
    if [ -t 0 ]; then
        while true; do
            if [ "$secret" = "true" ]; then
                echo -n "$prompt (default: $default): " >&2
                read -rs input_value
                echo >&2
            else
                echo -n "$prompt (default: $default): " >&2
                read -r input_value
            fi
            
            # Check if user wants to regenerate
            if [ "$allow_regenerate" = "true" ] && [ "$input_value" = "regenerate" ]; then
                if [[ "$prompt" == *"admin password"* ]]; then
                    default=$(generate_memorable_password)
                else
                    default=$(generate_secure_password)
                fi
                echo "New generated value: $default" >&2
                continue
            fi
            
            break
        done
    else
        # Non-interactive mode - use default
        input_value=""
    fi
    
    echo "${input_value:-$default}"
}

# Function to create MISP item
create_misp_item() {
    print_header "Creating MISP Configuration Item"
    
    local fqdn=$(prompt_input "Enter MISP FQDN" "$DEFAULT_MISP_FQDN")
    local email=$(prompt_input "Enter MISP admin email" "$DEFAULT_MISP_EMAIL")
    
    # Ask user if they want to use 1Password's built-in password generation
    echo "Password generation options:"
    echo "1) Use 1Password's built-in password generation (recommended)"
    echo "2) Generate memorable password manually"
    echo "3) Enter password manually"
    echo -n "Enter choice (1-3): " >&2
    if [ -t 0 ]; then
        read -r password_choice
    else
        password_choice="1"
        echo "1 (non-interactive mode)" >&2
    fi
    
    local password
    local org=$(prompt_input "Enter organization name" "$DEFAULT_MISP_ORG")
    local baseurl=$(prompt_input "Enter MISP base URL" "$DEFAULT_MISP_BASEURL")
    
    case $password_choice in
        1)
            # Use 1Password's built-in password generation
            print_status "Creating MISP item with 1Password-generated password..."
            
            # Create a temporary password item to generate the admin password
            local temp_password="temp_misp_$(date +%s)"
            op item create \
                --vault "$VAULT" \
                --title="$temp_password" \
                --category=password \
                --generate-password=20,letters,digits
            
            # Get the generated password
            password=$(op item get "$temp_password" --vault "$VAULT" --fields password)
            print_status "Generated password: $password"
            
            # Create the actual MISP item with the generated password
            op item create \
                --vault "$VAULT" \
                --category=login \
                --title="dshield-misp-misp" \
                FQDN="$fqdn" \
                email="$email" \
                password="$password" \
                org="$org" \
                baseurl="$baseurl"
            
            # Clean up temporary item
            op item delete "$temp_password" --vault "$VAULT" 2>/dev/null || true
            ;;
        2)
            # Generate memorable password manually
            local generated_password=$(generate_memorable_password)
            echo "Generated memorable password: $generated_password"
            echo "Type 'regenerate' to generate a new password"
            password=$(prompt_input "Enter MISP admin password (or press Enter to use generated)" "$generated_password" "true" "true")
            
            op item create \
                --vault "$VAULT" \
                --category=login \
                --title="dshield-misp-misp" \
                FQDN="$fqdn" \
                email="$email" \
                password="$password" \
                org="$org" \
                baseurl="$baseurl"
            ;;
        3)
            # Manual password entry
            password=$(prompt_input "Enter MISP admin password" "" "true")
            
            op item create \
                --vault "$VAULT" \
                --category=login \
                --title="dshield-misp-misp" \
                FQDN="$fqdn" \
                email="$email" \
                password="$password" \
                org="$org" \
                baseurl="$baseurl"
            ;;
        *)
            print_error "Invalid choice"
            return 1
            ;;
    esac
    
    print_status "Created MISP configuration item"
}

# Function to create database item
create_database_item() {
    print_header "Creating Database Configuration Item"
    
    local database=$(prompt_input "Enter database name" "$DEFAULT_DB_NAME")
    local generated_username=$(generate_random_username)
    local username=$(prompt_input "Enter database username (or press Enter to use generated)" "$generated_username")
    
    # Ask user if they want to use 1Password's built-in password generation
    echo "Password generation options:"
    echo "1) Use 1Password's built-in password generation (recommended)"
    echo "2) Generate passwords manually"
    echo "3) Enter passwords manually"
    echo -n "Enter choice (1-3): " >&2
    if [ -t 0 ]; then
        read -r password_choice
    else
        password_choice="1"
        echo "1 (non-interactive mode)" >&2
    fi
    
    case $password_choice in
        1)
            # Use 1Password's built-in password generation
            print_status "Creating database item with 1Password-generated passwords..."
            
            # Create a temporary password item to generate the database password
            local temp_db_password="temp_db_$(date +%s)"
            op item create \
                --vault "$VAULT" \
                --title="$temp_db_password" \
                --category=password \
                --generate-password=32,letters,digits,symbols
            
            # Get the generated database password
            local password=$(op item get "$temp_db_password" --vault "$VAULT" --fields password)
            print_status "Generated database password: $password"
            
            # Create a temporary password item to generate the root password
            local temp_root_password="temp_root_$(date +%s)"
            op item create \
                --vault "$VAULT" \
                --title="$temp_root_password" \
                --category=password \
                --generate-password=32,letters,digits,symbols
            
            # Get the generated root password
            local root_password=$(op item get "$temp_root_password" --vault "$VAULT" --fields password)
            print_status "Generated root password: $root_password"
            
            # Create the actual database item with the generated passwords
            op item create \
                --vault "$VAULT" \
                --category=database \
                --title="dshield-misp-database" \
                database="$database" \
                username="$username" \
                password="$password" \
                root_password="$root_password"
            
            # Clean up temporary items
            op item delete "$temp_db_password" --vault "$VAULT" 2>/dev/null || true
            op item delete "$temp_root_password" --vault "$VAULT" 2>/dev/null || true
            ;;
        2)
            # Generate passwords manually
            local generated_root_password=$(generate_secure_password)
            local generated_db_password=$(generate_secure_password)
            
            echo "Generated secure passwords:"
            echo "  Root password: $generated_root_password"
            echo "  Database password: $generated_db_password"
            echo ""
            echo "Type 'regenerate' to generate new passwords"
            
            local root_password=$(prompt_input "Enter MySQL root password (or press Enter to use generated)" "$generated_root_password" "true" "true")
            local password=$(prompt_input "Enter database password (or press Enter to use generated)" "$generated_db_password" "true" "true")
            
            op item create \
                --vault "$VAULT" \
                --category=database \
                --title="dshield-misp-database" \
                root_password="$root_password" \
                database="$database" \
                username="$username" \
                password="$password"
            ;;
        3)
            # Manual password entry
            local root_password=$(prompt_input "Enter MySQL root password" "" "true")
            local password=$(prompt_input "Enter database password" "" "true")
            
            op item create \
                --vault "$VAULT" \
                --category=database \
                --title="dshield-misp-database" \
                root_password="$root_password" \
                database="$database" \
                username="$username" \
                password="$password"
            ;;
        *)
            print_error "Invalid choice"
            return 1
            ;;
    esac
    
    print_status "Created database configuration item"
}

# Function to generate memorable password using 1Password CLI
generate_memorable_password() {
    # Create a temporary item with a memorable password (20 chars, letters and digits)
    local temp_title="temp_memorable_$(date +%s)"
    local password
    
    # Use 1Password's built-in password generation
    password=$(op item create \
        --vault "$VAULT" \
        --title="$temp_title" \
        --category=password \
        --generate-password=20,letters,digits 2>/dev/null | op item get "$temp_title" --vault "$VAULT" --fields password 2>/dev/null || echo "")
    
    # Clean up the temporary item
    op item delete "$temp_title" --vault "$VAULT" 2>/dev/null || true
    
    # If generation failed, fall back to a simple memorable pattern
    if [ -z "$password" ]; then
        local words=("Dragon" "Forest" "Ocean" "Mountain" "Castle" "River" "Sunset" "Garden")
        local word1="${words[$((RANDOM % ${#words[@]}))]}"
        local word2="${words[$((RANDOM % ${#words[@]}))]}"
        password="${word1}${word2}$((RANDOM % 100))"
    fi
    
    echo "$password"
}

# Function to generate secure password using 1Password CLI
generate_secure_password() {
    # Create a temporary item with a secure password (32 chars, letters, digits, symbols)
    local temp_title="temp_secure_$(date +%s)"
    local password
    
    # Use 1Password's built-in password generation
    password=$(op item create \
        --vault "$VAULT" \
        --title="$temp_title" \
        --category=password \
        --generate-password=32,letters,digits,symbols 2>/dev/null | op item get "$temp_title" --vault "$VAULT" --fields password 2>/dev/null || echo "")
    
    # Clean up the temporary item
    op item delete "$temp_title" --vault "$VAULT" 2>/dev/null || true
    
    # If generation failed, fall back to a simple secure pattern
    if [ -z "$password" ]; then
        password=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-32)
    fi
    
    echo "$password"
}

# Function to generate random username (2 words)
generate_random_username() {
    local words=(
        "admin" "user" "misp" "db" "data" "app" "web" "api" "service" "system"
        "manager" "operator" "controller" "handler" "processor" "executor" "runner"
        "worker" "agent" "client" "server" "host" "node" "instance" "session"
    )
    
    local username=""
    for i in {1..2}; do
        local random_index=$((RANDOM % ${#words[@]}))
        local word="${words[$random_index]}"
        
        if [ $i -eq 1 ]; then
            username="$word"
        else
            username="${username}_${word}"
        fi
    done
    
    echo "$username"
}

# Function to create Office365 item
create_o365_item() {
    print_header "Creating Office365 Configuration Item"
    
    echo "Office365 Graph API configuration (leave empty to skip):"
    local client_id=$(prompt_input "Enter Azure AD client ID" "")
    local client_secret=$(prompt_input "Enter Azure AD client secret" "" "true")
    local tenant_id=$(prompt_input "Enter Azure AD tenant ID" "")
    local sender_email=$(prompt_input "Enter sender email address" "")
    
    if [ -n "$client_id" ] && [ -n "$client_secret" ] && [ -n "$tenant_id" ] && [ -n "$sender_email" ]; then
        op item create \
            --vault "$VAULT" \
            --category="API Credential" \
            --title="dshield-misp-o365" \
            client_id="$client_id" \
            client_secret="$client_secret" \
            tenant_id="$tenant_id" \
            sender_email="$sender_email"
        
        print_status "Created Office365 configuration item"
    else
        print_warning "Skipping Office365 configuration (incomplete information)"
    fi
}

# Function to import existing items using op:// URLs
import_existing_items() {
    print_header "Importing Existing Items"
    
    print_status "For advanced import functionality, use the dedicated import script:"
    echo "  ./import-1password-items.sh"
    echo ""
    echo "This script supports:"
    echo "  - Copying from existing 1Password items"
    echo "  - Importing using op:// URLs"
    echo "  - Batch import operations"
    echo ""
    
    if command -v ./import-1password-items.sh &> /dev/null; then
        echo -n "Would you like to run the import script now? (y/N): "
        read -r run_import
        if [[ "$run_import" =~ ^[Yy]$ ]]; then
            ./import-1password-items.sh
        fi
    else
        print_warning "Import script not found. Please run: ./import-1password-items.sh"
    fi
}

# Function to verify items exist
verify_items() {
    print_header "Verifying Created Items"
    
    local items=("dshield-misp-misp" "dshield-misp-database" "dshield-misp-o365")
    local missing_items=()
    
    for item in "${items[@]}"; do
        if op item get "$item" --vault "$VAULT" &> /dev/null; then
            print_status "✓ Found item: $item"
        else
            print_warning "✗ Missing item: $item"
            missing_items+=("$item")
        fi
    done
    
    if [ ${#missing_items[@]} -eq 0 ]; then
        print_status "All required items are present!"
    else
        print_warning "Missing items: ${missing_items[*]}"
        echo "You can run this script again to create missing items."
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -v, --vault VAULT     Specify vault name (default: $DEFAULT_VAULT)"
    echo "  -i, --import          Import existing items using op:// URLs"
    echo "  -c, --create          Create new items (interactive)"
    echo "  -a, --all             Create all items (interactive)"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --all                    # Create all items interactively"
    echo "  $0 --vault Work --create    # Create items in Work vault"
    echo "  $0 --import                 # Import existing items"
}

# Function to test the load-1password-env.sh script
test_environment() {
    print_header "Testing Environment Loading"
    
    if [ -f "load-1password-env.sh" ]; then
        print_status "Testing load-1password-env.sh script..."
        
        # Source the script and check if variables are loaded
        source load-1password-env.sh
        
        local vars=("MISP_FQDN" "MISP_EMAIL" "MYSQL_DATABASE" "MYSQL_USER")
        local all_good=true
        
        for var in "${vars[@]}"; do
            if [ -n "${!var}" ]; then
                print_status "✓ $var is set"
            else
                print_warning "✗ $var is not set"
                all_good=false
            fi
        done
        
        if [ "$all_good" = true ]; then
            print_status "Environment loading test passed!"
        else
            print_warning "Some environment variables are not set correctly."
        fi
    else
        print_error "load-1password-env.sh not found in current directory"
    fi
}

# Main script logic
main() {
    print_header "1Password Setup for dshield-misp"
    
    # Check 1Password CLI
    check_1password
    
    # Parse command line arguments
    local vault=""
    local import_mode=false
    local create_mode=false
    local all_mode=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--vault)
                vault="$2"
                shift 2
                ;;
            -i|--import)
                import_mode=true
                shift
                ;;
            -c|--create)
                create_mode=true
                shift
                ;;
            -a|--all)
                all_mode=true
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
    
    # Get vault name
    get_vault "$vault"
    print_status "Using vault: $VAULT"
    
    # Determine mode
    if [ "$all_mode" = true ]; then
        create_misp_item
        create_database_item
        create_o365_item
    elif [ "$create_mode" = true ]; then
        echo "Which item would you like to create?"
        echo "1) MISP configuration"
        echo "2) Database configuration"
        echo "3) Office365 configuration"
        echo "4) All items"
        echo -n "Enter choice (1-4): " >&2
        if [ -t 0 ]; then
            read -r choice
        else
            choice="4"  # Default to all items in non-interactive mode
            echo "4 (non-interactive mode)" >&2
        fi
        
        case $choice in
            1) create_misp_item ;;
            2) create_database_item ;;
            3) create_o365_item ;;
            4) create_misp_item; create_database_item; create_o365_item ;;
            *) print_error "Invalid choice" && exit 1 ;;
        esac
    elif [ "$import_mode" = true ]; then
        import_existing_items
    else
        # Interactive mode
        echo "Choose setup mode:"
        echo "1) Create new items (interactive)"
        echo "2) Import existing items (op:// URLs)"
        echo "3) Create all items (interactive)"
        echo -n "Enter choice (1-3): " >&2
        if [ -t 0 ]; then
            read -r choice
        else
            choice="3"  # Default to create all in non-interactive mode
            echo "3 (non-interactive mode)" >&2
        fi
        
        case $choice in
            1) create_mode=true; main --create ;;
            2) import_existing_items ;;
            3) main --all ;;
            *) print_error "Invalid choice" && exit 1 ;;
        esac
    fi
    
    # Verify items
    verify_items
    
    # Test environment loading
    test_environment
    
    print_header "Setup Complete!"
    echo "You can now use the following commands:"
    echo "  source load-1password-env.sh && docker-compose up -d"
    echo "  ./load-1password-env.sh && docker-compose up -d"
}

# Run main function with all arguments
main "$@" 