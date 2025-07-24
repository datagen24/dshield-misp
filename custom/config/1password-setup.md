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

### 3. dshield-misp-o365
Create a new item with the following fields:
- **client_id**: Azure AD app client ID
- **client_secret**: Azure AD app client secret
- **tenant_id**: Azure AD tenant ID
- **sender_email**: Email address to send from

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
