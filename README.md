# dshield-misp: Custom MISP Container Stack

This project provides a full-featured, modular MISP (Malware Information Sharing Platform) container stack, designed for integration with the dshield-siem (Elastic-powered) and dshield-mcp projects.

## Features
- Complete MISP stack: web, DB, workers, modules, Redis, and email relay
- Modular email relay: easily swap between default SMTP relay and custom Office365 Graph-to-SMTP proxy
- **1Password integration** for secure credential management
- Ready for integration with dshield-siem and agentic search via dshield-mcp
- Custom config and script directories for easy extension

## Quick Start
1. Clone this repo
2. Run the setup script to configure your email relay:
   ```sh
   ./setup.sh
   ```
3. Choose your credential management method:
   ```sh
   # Option A: Local environment file
   cp .env.template .env
   # Edit .env with your actual values
   
   # Option B: 1Password integration (recommended)
   # See custom/config/1password-setup.md for setup instructions
   ```
4. Start the stack:
   ```sh
   # With local .env file
   docker-compose up -d
   
   # With 1Password integration
   source load-1password-env.sh && docker-compose up -d
   ```

## Email Relay Options

### Classic SMTP Relay
- Traditional username/password authentication
- Works with most SMTP servers
- Default option in the setup script

### Office365 Graph SMTP Relay
- OAuth2-based authentication via Microsoft Graph API
- No need for basic authentication or app passwords
- Uses the [Microsoft Graph SMTP Relay](https://github.com/ggpwnkthx/Microsoft-Graph-SMTP-Relay) project
- Ideal for Office365/Microsoft 365 environments

The setup script (`./setup.sh`) will prompt you to choose between these options and generate the appropriate configuration files.

## Credential Management

### 1Password Integration (Recommended)
- Secure credential storage using 1Password CLI
- Automatic environment variable loading
- Fallback to default values if 1Password items not found
- Supports all sensitive configuration (MISP, database, email relay)

### Local Environment File
- Traditional `.env` file approach
- Suitable for development or when 1Password is not available
- Remember to add `.env` to `.gitignore`

## Manual Configuration
If you prefer manual setup:
1. Copy and edit `docker-compose.yml` as needed
2. Create `docker-compose.override.yml` for your email relay choice
3. Place custom configs in `./custom/config` and scripts in `./custom/scripts`
4. Set up your environment variables (local or 1Password)

## Integration Plans
- **dshield-siem**: MISP will enhance threat intel data, with connectors/scripts to be added in `custom/scripts`.
- **dshield-mcp**: Agentic search and automation features will be integrated here.

## Documentation
- [Email Relay Configuration](custom/config/relay.md) - Detailed setup instructions for both relay options
- [1Password Integration Setup](custom/config/1password-setup.md) - Secure credential management
- [Microsoft Graph SMTP Relay](https://github.com/ggpwnkthx/Microsoft-Graph-SMTP-Relay) - Office365 relay project documentation

## Next Steps
- Wire up MISP to dshield-siem (Elastic)
- Add agentic search integration
- Document custom relay options

---
Reference: [MISP Docker](https://github.com/MISP/misp-docker) 