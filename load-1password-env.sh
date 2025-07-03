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

# Office365 Graph SMTP Relay Configuration
export O365_CLIENT_ID=$(op item get "dshield-misp-o365" --fields client_id 2>/dev/null || echo "")
export O365_CLIENT_SECRET=$(op item get "dshield-misp-o365" --fields client_secret 2>/dev/null || echo "")
export O365_TENANT_ID=$(op item get "dshield-misp-o365" --fields tenant_id 2>/dev/null || echo "")
export O365_SENDER_EMAIL=$(op item get "dshield-misp-o365" --fields sender_email 2>/dev/null || echo "")
