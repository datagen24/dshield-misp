# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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