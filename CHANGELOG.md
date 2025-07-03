# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-07-03

### Added
- **Enhanced 1Password Integration**:
  - Automated setup script (`setup-1password.sh`) for creating 1Password items
  - Advanced import script (`import-1password-items.sh`) for existing items
  - Comprehensive testing script (`test-1password-setup.sh`) for verification
  - **1Password Native Password Generation**:
    - Uses 1Password's built-in `--generate-password` option
    - MISP admin passwords: 20 characters with letters and digits (memorable)
    - Database passwords: 32 characters with letters, digits, and symbols (secure)
    - Automatic temporary item creation and cleanup
  - **Multiple Password Generation Options**:
    - 1Password native generation (recommended)
    - Manual generation with regeneration capability
    - Manual password entry
  - **Cross-vault Operations**: Support for different environments (dev, staging, prod)
  - **Batch Operations**: Non-interactive mode for automation
  - **Environment Testing**: Comprehensive verification of setup
- **Microsoft-Graph-SMTP-Relay Integration**:
  - Automated Docker image building from source
  - Automatic repository cloning and updates
  - Local image building to avoid GHCR authentication issues
  - Integration with setup script for seamless Office365 configuration
- **Improved User Experience**:
  - Interactive prompts with sensible defaults
  - Non-interactive mode support for CI/CD
  - Colored output for better readability
  - Comprehensive error handling and validation
  - Password regeneration capability (type 'regenerate' for new passwords)
- **Enhanced Documentation**:
  - Comprehensive 1Password setup guide (`1PASSWORD_SETUP.md`)
  - Quick reference guide (`custom/config/1password-setup.md`)
  - Password generation examples and best practices
  - Troubleshooting guide with common issues and solutions
  - Security best practices and recommendations

### Changed
- **1Password Item Categories**: Fixed Office365 item category from "api-credential" to "API Credential"
- **Password Generation**: Replaced custom password generation with 1Password's native capabilities
- **Setup Process**: Streamlined setup with automated item creation and verification
- **Error Handling**: Improved error messages and fallback mechanisms

### Technical Improvements
- **Temporary Item Management**: Automatic creation and cleanup of temporary password items
- **JSON Parsing**: Improved handling of 1Password CLI output
- **Terminal Detection**: Better handling of interactive vs non-interactive environments
- **Vault Management**: Automatic vault creation if it doesn't exist
- **Field Validation**: Comprehensive checking of required fields and values

## [1.0.0] - 2025-01-02

### Added
- Initial release of dshield-misp container stack
- Complete MISP (Malware Information Sharing Platform) stack with:
  - MISP web application
  - MariaDB database
  - Redis cache
  - MISP modules
  - MISP workers
  - Modular email relay system
- **Email Relay Options**:
  - Classic SMTP relay (username/password authentication)
  - Office365 Graph SMTP relay (OAuth2 via Microsoft Graph API)
  - Uses [Microsoft Graph SMTP Relay](https://github.com/ggpwnkthx/Microsoft-Graph-SMTP-Relay) project
- **1Password Integration**:
  - Secure credential management using 1Password CLI
  - Automatic environment variable loading
  - Fallback to default values if 1Password items not found
  - Supports all sensitive configuration (MISP, database, email relay)
- **Setup and Configuration**:
  - Interactive setup script (`setup.sh`) for easy configuration
  - Support for both local `.env` files and 1Password integration
  - Comprehensive documentation for all features
  - Custom config and script directories for extensions
- **Documentation**:
  - Detailed README with quick start guide
  - Email relay configuration guide
  - 1Password integration setup instructions
  - Manual configuration options
- **Security Features**:
  - `.gitignore` to exclude sensitive files
  - Environment variable fallbacks
  - Secure credential management options
- **Integration Ready**:
  - Framework prepared for dshield-siem (Elastic) integration
  - Framework prepared for dshield-mcp (agentic search) integration
  - Modular design for easy extension

### Technical Details
- Based on official MISP Docker stack
- Docker Compose v3.6 configuration
- Environment variable driven configuration
- Modular service architecture
- Production-ready with proper restart policies

### Dependencies
- Docker and Docker Compose
- 1Password CLI (optional, for credential management)
- Microsoft Graph API access (for Office365 relay option) 