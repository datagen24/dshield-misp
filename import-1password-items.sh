#!/bin/bash

# 1Password Item Import Script for dshield-misp
# This script helps import existing 1Password items for the dshield-misp project

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
    if ! command -v op &> /dev/null; then
        print_error "1Password CLI is not installed. Please install it first."
        exit 1
    fi

    if ! op account list &> /dev/null; then
        print_error "1Password CLI is not authenticated. Please run 'op signin' first."
        exit 1
    fi
}

# Function to prompt for input
prompt_input() {
    local prompt="$1"
    local default="$2"
    
    echo -n "$prompt (default: $default): "
    read -r input_value
    echo "${input_value:-$default}"
}

# Function to import item from op:// URL
import_from_op_url() {
    local item_name="$1"
    local op_url="$2"
    local target_vault="$3"
    
    print_status "Importing $item_name from op:// URL..."
    
    # Parse op:// URL: op://vault/item/field
    if [[ "$op_url" =~ op://([^/]+)/([^/]+)/(.+) ]]; then
        local source_vault="${BASH_REMATCH[1]}"
        local source_item="${BASH_REMATCH[2]}"
        local field="${BASH_REMATCH[3]}"
        
        print_status "Source: vault=$source_vault, item=$source_item, field=$field"
        
        # Get the field value
        local field_value
        if [ "$field" = "password" ]; then
            field_value=$(op item get "$source_item" --vault "$source_vault" --fields password 2>/dev/null || echo "")
        else
            field_value=$(op item get "$source_item" --vault "$source_vault" --fields "$field" 2>/dev/null || echo "")
        fi
        
        if [ -n "$field_value" ]; then
            print_status "Successfully retrieved field value"
            return 0
        else
            print_error "Failed to retrieve field value from op:// URL"
            return 1
        fi
    else
        print_error "Invalid op:// URL format. Expected: op://vault/item/field"
        return 1
    fi
}

# Function to copy item from existing item
copy_from_existing_item() {
    local item_name="$1"
    local source_item="$2"
    local target_vault="$3"
    
    print_status "Copying $item_name from existing item: $source_item"
    
    # Get item details
    local item_json
    item_json=$(op item get "$source_item" --format=json 2>/dev/null || echo "")
    
    if [ -z "$item_json" ]; then
        print_error "Failed to retrieve item: $source_item"
        return 1
    fi
    
    # Extract fields and create new item
    local title=$(echo "$item_json" | jq -r '.title // empty')
    local category=$(echo "$item_json" | jq -r '.category // empty')
    
    # Build the op item create command
    local create_cmd="op item create --vault \"$target_vault\" --title \"$item_name\""
    
    if [ -n "$category" ]; then
        create_cmd="$create_cmd --category=$category"
    fi
    
    # Add fields
    local fields
    fields=$(echo "$item_json" | jq -r '.fields[]? | select(.id != "notesPlain") | "\(.id)=\(.value)"' 2>/dev/null || echo "")
    
    if [ -n "$fields" ]; then
        while IFS= read -r field; do
            if [ -n "$field" ] && [[ "$field" != "=" ]]; then
                create_cmd="$create_cmd $field"
            fi
        done <<< "$fields"
    fi
    
    # Execute the create command
    if eval "$create_cmd"; then
        print_status "Successfully copied item to: $item_name"
        return 0
    else
        print_error "Failed to copy item"
        return 1
    fi
}

# Function to import MISP configuration
import_misp_config() {
    local target_vault="$1"
    
    print_header "Importing MISP Configuration"
    
    echo "Choose import method:"
    echo "1) Copy from existing item"
    echo "2) Use op:// URL"
    echo "3) Manual entry"
    echo -n "Enter choice (1-3): "
    read -r choice
    
    case $choice in
        1)
            local source_item=$(prompt_input "Enter source item name" "")
            if [ -n "$source_item" ]; then
                copy_from_existing_item "dshield-misp-misp" "$source_item" "$target_vault"
            fi
            ;;
        2)
            local op_url=$(prompt_input "Enter op:// URL" "")
            if [ -n "$op_url" ]; then
                import_from_op_url "dshield-misp-misp" "$op_url" "$target_vault"
            fi
            ;;
        3)
            print_warning "Manual entry not implemented in this script. Use setup-1password.sh instead."
            ;;
        *)
            print_error "Invalid choice"
            ;;
    esac
}

# Function to import database configuration
import_database_config() {
    local target_vault="$1"
    
    print_header "Importing Database Configuration"
    
    echo "Choose import method:"
    echo "1) Copy from existing item"
    echo "2) Use op:// URL"
    echo "3) Manual entry"
    echo -n "Enter choice (1-3): "
    read -r choice
    
    case $choice in
        1)
            local source_item=$(prompt_input "Enter source item name" "")
            if [ -n "$source_item" ]; then
                copy_from_existing_item "dshield-misp-database" "$source_item" "$target_vault"
            fi
            ;;
        2)
            local op_url=$(prompt_input "Enter op:// URL" "")
            if [ -n "$op_url" ]; then
                import_from_op_url "dshield-misp-database" "$op_url" "$target_vault"
            fi
            ;;
        3)
            print_warning "Manual entry not implemented in this script. Use setup-1password.sh instead."
            ;;
        *)
            print_error "Invalid choice"
            ;;
    esac
}

# Function to import Office365 configuration
import_o365_config() {
    local target_vault="$1"
    
    print_header "Importing Office365 Configuration"
    
    echo "Choose import method:"
    echo "1) Copy from existing item"
    echo "2) Use op:// URL"
    echo "3) Manual entry"
    echo -n "Enter choice (1-3): "
    read -r choice
    
    case $choice in
        1)
            local source_item=$(prompt_input "Enter source item name" "")
            if [ -n "$source_item" ]; then
                copy_from_existing_item "dshield-misp-o365" "$source_item" "$target_vault"
            fi
            ;;
        2)
            local op_url=$(prompt_input "Enter op:// URL" "")
            if [ -n "$op_url" ]; then
                import_from_op_url "dshield-misp-o365" "$op_url" "$target_vault"
            fi
            ;;
        3)
            print_warning "Manual entry not implemented in this script. Use setup-1password.sh instead."
            ;;
        *)
            print_error "Invalid choice"
            ;;
    esac
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -v, --vault VAULT     Specify target vault name (default: Private)"
    echo "  -m, --misp            Import MISP configuration only"
    echo "  -d, --database        Import database configuration only"
    echo "  -o, --o365            Import Office365 configuration only"
    echo "  -a, --all             Import all configurations"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --all                    # Import all items interactively"
    echo "  $0 --vault Work --misp      # Import MISP config to Work vault"
    echo "  $0 --database               # Import database config only"
}

# Main script logic
main() {
    print_header "1Password Item Import for dshield-misp"
    
    # Check 1Password CLI
    check_1password
    
    # Parse command line arguments
    local target_vault="Private"
    local import_misp=false
    local import_database=false
    local import_o365=false
    local import_all=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--vault)
                target_vault="$2"
                shift 2
                ;;
            -m|--misp)
                import_misp=true
                shift
                ;;
            -d|--database)
                import_database=true
                shift
                ;;
            -o|--o365)
                import_o365=true
                shift
                ;;
            -a|--all)
                import_all=true
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
    
    print_status "Target vault: $target_vault"
    
    # Check if vault exists
    if ! op vault list | grep -q "$target_vault"; then
        print_warning "Vault '$target_vault' does not exist. Creating it..."
        op vault create "$target_vault"
    fi
    
    # Determine what to import
    if [ "$import_all" = true ]; then
        import_misp_config "$target_vault"
        import_database_config "$target_vault"
        import_o365_config "$target_vault"
    elif [ "$import_misp" = true ]; then
        import_misp_config "$target_vault"
    elif [ "$import_database" = true ]; then
        import_database_config "$target_vault"
    elif [ "$import_o365" = true ]; then
        import_o365_config "$target_vault"
    else
        # Interactive mode
        echo "Which configuration would you like to import?"
        echo "1) MISP configuration"
        echo "2) Database configuration"
        echo "3) Office365 configuration"
        echo "4) All configurations"
        echo -n "Enter choice (1-4): "
        read -r choice
        
        case $choice in
            1) import_misp_config "$target_vault" ;;
            2) import_database_config "$target_vault" ;;
            3) import_o365_config "$target_vault" ;;
            4) import_misp_config "$target_vault"; import_database_config "$target_vault"; import_o365_config "$target_vault" ;;
            *) print_error "Invalid choice" && exit 1 ;;
        esac
    fi
    
    print_header "Import Complete!"
    echo "You can now use the following commands:"
    echo "  source load-1password-env.sh && docker-compose up -d"
    echo "  ./load-1password-env.sh && docker-compose up -d"
}

# Run main function with all arguments
main "$@" 