# 1Password Integration Setup for dshield-misp

This document provides comprehensive instructions for setting up 1Password integration with the dshield-misp project. The setup includes automated scripts for creating and importing secrets.

## Prerequisites

1. **1Password CLI installed and authenticated**
   ```bash
   # macOS
   brew install 1password-cli
   
   # Linux
   # Download from: https://1password.com/downloads/command-line/
   
   # Windows
   # Download from: https://1password.com/downloads/command-line/
   ```

2. **1Password account with appropriate vault access**
   ```bash
   # Sign in to your 1Password account
   op signin
   ```

## Quick Start

### Option 1: Interactive Setup (Recommended for first-time users)
```bash
./setup-1password.sh
```

### Option 2: Create All Items at Once
```bash
./setup-1password.sh --all
```

### Option 3: Import Existing Items
```bash
./import-1password-items.sh
```

## Required 1Password Items

The dshield-misp project requires three main configuration items in 1Password:

### 1. dshield-misp-misp
**Category:** Login  
**Purpose:** MISP application configuration

| Field | Description | Example |
|-------|-------------|---------|
| `FQDN` | MISP fully qualified domain name | `misp.yourdomain.com` |
| `email` | MISP admin email address | `admin@yourdomain.com` |
| `password` | MISP admin password | `SecurePassword123!` |
| `org` | Organization name | `Your Organization` |
| `baseurl` | MISP base URL | `https://misp.yourdomain.com` |

### 2. dshield-misp-database
**Category:** Database  
**Purpose:** MySQL database configuration

| Field | Description | Example |
|-------|-------------|---------|
| `root_password` | MySQL root password | `SecureRootPass123!` |
| `database` | Database name | `misp` |
| `username` | Database username | `misp` |
| `password` | Database password | `SecureDBPass123!` |

### 3. dshield-misp-o365
**Category:** API Credential  
**Purpose:** Office365 Graph API configuration (optional)

| Field | Description | Example |
|-------|-------------|---------|
| `client_id` | Azure AD app client ID | `12345678-1234-1234-1234-123456789012` |
| `client_secret` | Azure AD app client secret | `SecretValue123!` |
| `tenant_id` | Azure AD tenant ID | `87654321-4321-4321-4321-210987654321` |
| `sender_email` | Email address to send from | `noreply@yourdomain.com` |

## Scripts Overview

### setup-1password.sh
Primary setup script for creating new 1Password items.

**Features:**
- Interactive item creation with sensible defaults
- Vault management (create if doesn't exist)
- Environment testing
- Comprehensive error handling

**Usage:**
```bash
# Interactive mode
./setup-1password.sh

# Create all items at once
./setup-1password.sh --all

# Create specific vault
./setup-1password.sh --vault Work --all

# Create specific item type
./setup-1password.sh --create

# Show help
./setup-1password.sh --help
```

### import-1password-items.sh
Advanced import script for existing 1Password items.

**Features:**
- Copy from existing 1Password items
- Import using op:// URLs
- Batch import operations
- Cross-vault operations

**Usage:**
```bash
# Interactive import
./import-1password-items.sh

# Import all configurations
./import-1password-items.sh --all

# Import specific configuration
./import-1password-items.sh --misp
./import-1password-items.sh --database
./import-1password-items.sh --o365

# Import to specific vault
./import-1password-items.sh --vault Work --all

# Show help
./import-1password-items.sh --help
```

## Import Methods

### Method 1: Copy from Existing Items
If you already have similar items in 1Password, you can copy them:

```bash
./import-1password-items.sh --misp
# Choose option 1: Copy from existing item
# Enter the name of your existing MISP item
```

### Method 2: Using op:// URLs
For advanced users who have op:// URLs for their existing items:

```bash
./import-1password-items.sh --misp
# Choose option 2: Use op:// URL
# Enter: op://vault/item/field
```

**op:// URL Format:**
- `op://vault/item/field` - References a specific field in an item
- Example: `op://Private/MyMISPConfig/password`

### Method 3: Manual Creation
For complete control over the setup process:

```bash
./setup-1password.sh --create
# Choose which item to create and enter values manually
```

## Environment Integration

Once your 1Password items are set up, you can use them with the dshield-misp project:

### Option 1: Source the environment script
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

## Password Generation Features

The setup script provides multiple password generation options:

### **1Password Native Generation (Recommended)**
- Uses 1Password's built-in `--generate-password` option
- **MISP Admin Passwords**: 20 characters with letters and digits (memorable)
- **Database Passwords**: 32 characters with letters, digits, and symbols (secure)
- Automatically creates temporary password items and cleans them up
- Provides the highest security and consistency with 1Password ecosystem

### **Manual Generation with Regeneration**
- Custom password generators with fallback mechanisms
- Type `regenerate` to generate new passwords
- **Memorable Passwords**: Word-based patterns for admin accounts
- **Secure Passwords**: Cryptographically secure random passwords for databases

### **Manual Entry**
- Complete control over password selection
- Useful for existing passwords or specific requirements

### **Password Generation Examples**
```bash
# 1Password native generation
op item create --title="temp" --category=password --generate-password=20,letters,digits
op item create --title="temp" --category=password --generate-password=32,letters,digits,symbols

# Retrieve generated passwords
op item get "temp" --fields password
```

## Security Best Practices

1. **Use Strong Passwords**
   - Generate unique, strong passwords for each service
   - Use 1Password's built-in password generator feature
   - Prefer 1Password native generation for maximum security

2. **Vault Organization**
   - Consider using separate vaults for different environments (dev, staging, prod)
   - Use appropriate vault permissions

3. **Regular Rotation**
   - Regularly rotate credentials stored in 1Password
   - Use 1Password's password history feature

4. **Session Management**
   - Use 1Password's session management for additional security
   - Sign out when not actively using the CLI

5. **Backup and Recovery**
   - Ensure your 1Password account has proper backup and recovery procedures
   - Consider using 1Password's emergency kit

## Troubleshooting

### Common Issues

**1. 1Password CLI not found**
```bash
# Install 1Password CLI
# macOS
brew install 1password-cli

# Linux
# Download from 1Password website
```

**2. Authentication failed**
```bash
# Sign in to 1Password
op signin
```

**3. Vault not found**
```bash
# List available vaults
op vault list

# Create new vault if needed
op vault create "VaultName"
```

**4. Item already exists**
```bash
# Delete existing item (if needed)
op item delete "item-name" --vault "vault-name"

# Or use import script to copy from existing item
./import-1password-items.sh
```

**5. Environment variables not loading**
```bash
# Test the environment script
source load-1password-env.sh
echo $MISP_FQDN

# Check if items exist
op item get "dshield-misp-misp" --vault "your-vault"
```

### Debug Mode

Enable debug output for troubleshooting:
```bash
# Add debug flag to see detailed output
OP_DEBUG=1 ./setup-1password.sh
```

## Advanced Configuration

### Custom Vault Names
You can use custom vault names for different environments:

```bash
# Development environment
./setup-1password.sh --vault Dev --all

# Production environment
./setup-1password.sh --vault Prod --all
```

### Batch Operations
For automation, you can use non-interactive mode:

```bash
# Create items with default values
echo -e "Private\nmisp.local\nadmin@example.com\nadmin\nORGNAME\nhttps://misp.local" | ./setup-1password.sh --all
```

### Integration with CI/CD
For continuous integration, you can use 1Password's service account tokens:

```bash
# Set service account token
export OP_SERVICE_ACCOUNT_TOKEN="your-service-account-token"

# Run setup script
./setup-1password.sh --all
```

## Support

If you encounter issues with the 1Password setup:

1. Check the troubleshooting section above
2. Verify your 1Password CLI installation and authentication
3. Ensure you have appropriate permissions for the vault
4. Review the 1Password CLI documentation: https://developer.1password.com/docs/cli/

## Contributing

To contribute to the 1Password setup scripts:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This setup is part of the dshield-misp project and follows the same license terms. 