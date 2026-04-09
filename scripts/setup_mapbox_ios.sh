#!/bin/bash
# Reads MAPBOX_SECRET_TOKEN from .env and configures ~/.netrc for iOS builds

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: .env file not found at $ENV_FILE"
  exit 1
fi

TOKEN=$(grep '^MAPBOX_SECRET_TOKEN=' "$ENV_FILE" | cut -d'=' -f2-)

if [ -z "$TOKEN" ]; then
  echo "Error: MAPBOX_SECRET_TOKEN not set in .env"
  exit 1
fi

# Remove existing Mapbox entry if present
if [ -f ~/.netrc ]; then
  sed -i '' '/machine api.mapbox.com/,+2d' ~/.netrc
fi

# Add new entry
cat >> ~/.netrc << EOF
machine api.mapbox.com
login mapbox
password $TOKEN
EOF

chmod 600 ~/.netrc
echo "~/.netrc configured for Mapbox iOS downloads"
