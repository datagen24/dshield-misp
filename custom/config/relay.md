# Email Relay Configuration

This document describes the email relay options available in the dshield-misp stack.

## Available Options

### 1. Classic SMTP Relay (Default)
- Uses the `bytemark/smtp` container
- Supports traditional SMTP authentication (username/password)
- Suitable for most SMTP servers

### 2. Office365 Graph SMTP Relay
- Uses the [Microsoft Graph SMTP Relay](https://github.com/ggpwnkthx/Microsoft-Graph-SMTP-Relay) project
- OAuth2-based authentication via Microsoft Graph API
- No need for basic authentication or app passwords
- Ideal for Office365/Microsoft 365 environments

## Setup Instructions

### Using the Setup Script (Recommended)
```bash
./setup.sh
```
The script will prompt you to choose between classic SMTP and Office365 Graph relay.

### Manual Setup

#### Classic SMTP Relay
1. Create `docker-compose.override.yml`:
```yaml
version: '3.6'
services:
  misp-email-relay:
    image: bytemark/smtp
    environment:
      - RELAY_HOST=your_smtp_server.com
      - RELAY_PORT=587
      - RELAY_USERNAME=your_username
      - RELAY_PASSWORD=your_password
```

#### Office365 Graph Relay
1. Create `docker-compose.override.yml`:
```yaml
version: '3.6'
services:
  misp-email-relay:
    image: ghcr.io/ggpwnkthx/microsoft-graph-smtp-relay:latest
    environment:
      - CLIENT_ID=your_azure_app_client_id
      - CLIENT_SECRET=your_azure_app_client_secret
      - AUTHORITY=https://login.microsoftonline.com/your_tenant_id
      - SENDER_EMAIL=your_sender_email@yourdomain.com
      - PORT=25
    ports:
      - "25:25"
```

## Azure AD App Setup (Office365 Graph Relay)

1. Go to Azure Portal > Azure Active Directory > App registrations
2. Create a new registration
3. Note the Application (client) ID and Directory (tenant) ID
4. Go to Certificates & secrets > New client secret
5. Go to API permissions > Add permission > Microsoft Graph > Application permissions
6. Add "Mail.Send" permission
7. Grant admin consent for the permission

## Environment Variables

### Classic SMTP
- `SMTP_RELAY_HOST`: Your SMTP server hostname
- `SMTP_RELAY_PORT`: SMTP port (usually 587 or 465)
- `SMTP_RELAY_USERNAME`: SMTP username
- `SMTP_RELAY_PASSWORD`: SMTP password

### Office365 Graph
- `O365_CLIENT_ID`: Azure AD app client ID
- `O365_CLIENT_SECRET`: Azure AD app client secret
- `O365_TENANT_ID`: Azure AD tenant ID
- `O365_SENDER_EMAIL`: Email address to send from

## Testing

After setup, test the relay by sending a test email through MISP or using the test scripts provided in the Microsoft Graph SMTP Relay project.

## Troubleshooting

### Classic SMTP Issues
- Verify SMTP server credentials
- Check firewall/network connectivity
- Ensure SMTP server allows relay from your IP

### Office365 Graph Issues
- Verify Azure AD app permissions
- Check client secret hasn't expired
- Ensure Mail.Send permission is granted
- Verify sender email is authorized

## References
- [Microsoft Graph SMTP Relay](https://github.com/ggpwnkthx/Microsoft-Graph-SMTP-Relay)
- [MISP Docker](https://github.com/MISP/misp-docker) 