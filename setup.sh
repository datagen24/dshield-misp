#!/bin/bash

# dshield-misp Setup Script
# Allows users to choose between classic SMTP and Office365 Graph SMTP relay
# Includes 1Password integration for secure credential management

set -e

echo "=== dshield-misp Setup Script ==="
echo "This script will configure your MISP stack with your chosen email relay option."
echo

# Function to create docker-compose override for Office365 Graph relay
create_o365_compose() {
    cat > docker-compose.override.yml << 'EOF'
version: '3.6'

services:
  misp-email-relay:
    image: microsoft-graph-smtp-relay:latest
    container_name: misp-email-relay
    environment:
      - CLIENT_ID=${O365_CLIENT_ID}
      - CLIENT_SECRET=${O365_CLIENT_SECRET}
      - AUTHORITY=https://login.microsoftonline.com/${O365_TENANT_ID}
      - SENDER_EMAIL=${O365_SENDER_EMAIL}
      - PORT=25
    ports:
      - "25:25"
    restart: unless-stopped
EOF
}

# Function to create docker-compose override for classic SMTP
create_classic_compose() {
    cat > docker-compose.override.yml << 'EOF'
version: '3.6'

services:
  misp-email-relay:
    image: bytemark/smtp
    container_name: misp-email-relay
    environment:
      - RELAY_HOST=${SMTP_RELAY_HOST}
      - RELAY_PORT=${SMTP_RELAY_PORT}
      - RELAY_USERNAME=${SMTP_RELAY_USERNAME}
      - RELAY_PASSWORD=${SMTP_RELAY_PASSWORD}
    restart: unless-stopped
EOF
}

# Function to create environment file template
create_env_template() {
    local relay_type=$1
    
    cat > .env.template << EOF
# MISP Configuration
MISP_FQDN=misp.local
MISP_EMAIL=admin@example.com
MISP_PASSWORD=admin
MISP_ORG=ORGNAME
MISP_BASEURL=https://misp.local

# Database Configuration
MYSQL_ROOT_PASSWORD=misproot
MYSQL_DATABASE=misp
MYSQL_USER=misp
MYSQL_PASSWORD=misp

EOF

    if [ "$relay_type" = "o365" ]; then
        cat >> .env.template << 'EOF'
# Office365 Graph SMTP Relay Configuration
O365_CLIENT_ID=your_client_id_here
O365_CLIENT_SECRET=your_client_secret_here
O365_TENANT_ID=your_tenant_id_here
O365_SENDER_EMAIL=your_sender_email@yourdomain.com
EOF
    else
        cat >> .env.template << 'EOF'
# Classic SMTP Relay Configuration
SMTP_RELAY_HOST=smtp.example.com
SMTP_RELAY_PORT=587
SMTP_RELAY_USERNAME=your_username
SMTP_RELAY_PASSWORD=your_password
EOF
    fi
}

# Function to create 1Password integration script
create_1password_script() {
    local relay_type=$1
    
    cat > load-1password-env.sh << 'EOF'
#!/bin/bash

# Load environment variables from 1Password
# Make sure you have 1Password CLI installed and authenticated

# MISP Configuration
export MISP_FQDN=$(op item get "dshield-misp-misp" --fields FQDN 2>/dev/null || echo "misp.local")
export MISP_EMAIL=$(op item get "dshield-misp-misp" --fields email 2>/dev/null || echo "admin@example.com")
export MISP_PASSWORD=$(op item get "dshield-misp-misp" --fields password 2>/dev/null || echo "admin")
export MISP_ORG=$(op item get "dshield-misp-misp" --fields org 2>/dev/null || echo "ORGNAME")
export MISP_BASEURL=$(op item get "dshield-misp-misp" --fields baseurl 2>/dev/null || echo "https://misp.local")

# Database Configuration
export MYSQL_ROOT_PASSWORD=$(op item get "dshield-misp-database" --fields root_password 2>/dev/null || echo "misproot")
export MYSQL_DATABASE=$(op item get "dshield-misp-database" --fields database 2>/dev/null || echo "misp")
export MYSQL_USER=$(op item get "dshield-misp-database" --fields username 2>/dev/null || echo "misp")
export MYSQL_PASSWORD=$(op item get "dshield-misp-database" --fields password 2>/dev/null || echo "misp")

EOF

    if [ "$relay_type" = "o365" ]; then
        cat >> load-1password-env.sh << 'EOF'
# Office365 Graph SMTP Relay Configuration
export O365_CLIENT_ID=$(op item get "dshield-misp-o365" --fields client_id 2>/dev/null || echo "")
export O365_CLIENT_SECRET=$(op item get "dshield-misp-o365" --fields client_secret 2>/dev/null || echo "")
export O365_TENANT_ID=$(op item get "dshield-misp-o365" --fields tenant_id 2>/dev/null || echo "")
export O365_SENDER_EMAIL=$(op item get "dshield-misp-o365" --fields sender_email 2>/dev/null || echo "")
EOF
    else
        cat >> load-1password-env.sh << 'EOF'
# Classic SMTP Relay Configuration
export SMTP_RELAY_HOST=$(op item get "dshield-misp-smtp" --fields host 2>/dev/null || echo "smtp.example.com")
export SMTP_RELAY_PORT=$(op item get "dshield-misp-smtp" --fields port 2>/dev/null || echo "587")
export SMTP_RELAY_USERNAME=$(op item get "dshield-misp-smtp" --fields username 2>/dev/null || echo "")
export SMTP_RELAY_PASSWORD=$(op item get "dshield-misp-smtp" --fields password 2>/dev/null || echo "")
EOF
    fi

    chmod +x load-1password-env.sh
}

# Function to build Microsoft-Graph-SMTP-Relay Docker image
build_microsoft_graph_relay() {
    echo "Building Microsoft-Graph-SMTP-Relay Docker image..."
    
    # Check if the repository already exists
    if [ -d "Microsoft-Graph-SMTP-Relay" ]; then
        echo "Microsoft-Graph-SMTP-Relay repository already exists. Updating..."
        cd Microsoft-Graph-SMTP-Relay
        git pull origin main
        cd ..
    else
        echo "Cloning Microsoft-Graph-SMTP-Relay repository..."
        git clone https://github.com/ggpwnkthx/Microsoft-Graph-SMTP-Relay.git
    fi
    
    # Build the Docker image
    echo "Building Docker image..."
    cd Microsoft-Graph-SMTP-Relay
    docker build -t microsoft-graph-smtp-relay:latest .
    
    if [ $? -eq 0 ]; then
        echo "✅ Microsoft-Graph-SMTP-Relay image built successfully"
    else
        echo "❌ Failed to build Microsoft-Graph-SMTP-Relay image"
        echo "Please check the build logs above for errors"
        exit 1
    fi
    
    cd ..
}

# Function to create 1Password setup instructions
create_1password_instructions() {
    local relay_type=$1
    
    cat > custom/config/1password-setup.md << 'EOF'
# 1Password Integration Setup

This document provides a quick reference for 1Password integration with dshield-misp.

## Quick Start

For comprehensive setup instructions, see the main documentation: [1PASSWORD_SETUP.md](../1PASSWORD_SETUP.md)

### Automated Setup (Recommended)
```bash
# Interactive setup for first-time users
./setup-1password.sh

# Create all items at once
./setup-1password.sh --all

# Import existing items
./import-1password-items.sh
```

## Required 1Password Items

### 1. dshield-misp-misp
Create a new item with the following fields:
- **FQDN**: Your MISP FQDN (e.g., misp.yourdomain.com)
- **email**: MISP admin email
- **password**: MISP admin password
- **org**: Your organization name
- **baseurl**: MISP base URL (e.g., https://misp.yourdomain.com)

### 2. dshield-misp-database
Create a new item with the following fields:
- **root_password**: MySQL root password
- **database**: Database name (usually "misp")
- **username**: Database username (usually "misp")
- **password**: Database password

EOF

    if [ "$relay_type" = "o365" ]; then
        cat >> custom/config/1password-setup.md << 'EOF'
### 3. dshield-misp-o365
Create a new item with the following fields:
- **client_id**: Azure AD app client ID
- **client_secret**: Azure AD app client secret
- **tenant_id**: Azure AD tenant ID
- **sender_email**: Email address to send from

EOF
    else
        cat >> custom/config/1password-setup.md << 'EOF'
### 3. dshield-misp-smtp
Create a new item with the following fields:
- **host**: SMTP server hostname
- **port**: SMTP port (usually 587)
- **username**: SMTP username
- **password**: SMTP password

EOF
    fi

    cat >> custom/config/1password-setup.md << 'EOF'
## Usage

### Option 1: Source the script before running docker-compose
```bash
source load-1password-env.sh
docker-compose up -d
```

### Option 2: Use the script directly
```bash
./load-1password-env.sh && docker-compose up -d
```

### Option 3: Create a wrapper script
```bash
#!/bin/bash
source load-1password-env.sh
docker-compose "$@"
```

## Security Notes
- The load-1password-env.sh script will fall back to default values if 1Password items are not found
- Consider using 1Password's session management for additional security
- Regularly rotate credentials stored in 1Password

## Advanced Features

The setup scripts support:
- **Interactive creation** with sensible defaults
- **Import from existing items** using op:// URLs
- **Cross-vault operations** for different environments
- **Batch operations** for automation
- **Environment testing** to verify setup

For detailed instructions, see [1PASSWORD_SETUP.md](../1PASSWORD_SETUP.md).
EOF
}

# Main setup logic
echo "Choose your email relay option:"
echo "1) Classic SMTP Relay (username/password)"
echo "2) Office365 Graph SMTP Relay (OAuth2)"
echo
read -p "Enter your choice (1 or 2): " choice

case $choice in
    1)
        echo "Setting up Classic SMTP Relay..."
        create_classic_compose
        create_env_template "classic"
        create_1password_script "classic"
        create_1password_instructions "classic"
        echo "✓ Classic SMTP relay configured"
        echo "  - Edit .env.template with your SMTP server details"
        echo "  - Copy .env.template to .env and update values"
        echo "  - Or set up 1Password integration (see custom/config/1password-setup.md)"
        ;;
    2)
        echo "Setting up Office365 Graph SMTP Relay..."
        
        # Build the Microsoft-Graph-SMTP-Relay Docker image
        build_microsoft_graph_relay
        
        create_o365_compose
        create_env_template "o365"
        create_1password_script "o365"
        create_1password_instructions "o365"
        echo "✓ Office365 Graph relay configured"
        echo "  - Microsoft-Graph-SMTP-Relay Docker image built locally"
        echo "  - Edit .env.template with your Azure AD app details"
        echo "  - Copy .env.template to .env and update values"
        echo "  - Or set up 1Password integration (see custom/config/1password-setup.md)"
        echo "  - Ensure your Azure AD app has Mail.Send permission"
        ;;
    *)
        echo "Invalid choice. Please run the script again."
        exit 1
        ;;
esac

echo
echo "=== Setup Complete ==="
echo "Next steps:"
echo "1. Choose credential management:"
echo "   a) Local .env file: cp .env.template .env && edit .env"
echo "   b) 1Password integration: see custom/config/1password-setup.md"
echo "2. Start the stack: docker-compose up -d"
echo
echo "For Office365 setup, see: https://github.com/ggpwnkthx/Microsoft-Graph-SMTP-Relay"
echo "For MISP configuration, see: https://github.com/MISP/misp-docker" 