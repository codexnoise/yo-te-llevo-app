#!/bin/bash
# Generates GoogleService-Info.plist from .env variables
# This script is executed as an Xcode Build Phase before "Run Script"

set -e

ENV_FILE="${SRCROOT}/../.env"
OUTPUT_FILE="${SRCROOT}/Runner/GoogleService-Info.plist"

if [ ! -f "$ENV_FILE" ]; then
  echo "error: .env file not found at $ENV_FILE"
  echo "error: Copy .env.example to .env and fill in your Firebase values."
  exit 1
fi

# Read .env variables
get_env_value() {
  local key=$1
  grep -E "^${key}=" "$ENV_FILE" | head -1 | cut -d'=' -f2- | tr -d '[:space:]'
}

API_KEY=$(get_env_value "FIREBASE_IOS_API_KEY")
GCM_SENDER_ID=$(get_env_value "FIREBASE_MESSAGING_SENDER_ID")
BUNDLE_ID=$(get_env_value "FIREBASE_IOS_BUNDLE_ID")
PROJECT_ID=$(get_env_value "FIREBASE_PROJECT_ID")
STORAGE_BUCKET=$(get_env_value "FIREBASE_STORAGE_BUCKET")
GOOGLE_APP_ID=$(get_env_value "FIREBASE_IOS_APP_ID")

if [ -z "$API_KEY" ] || [ -z "$GOOGLE_APP_ID" ]; then
  echo "error: Firebase iOS environment variables are missing in .env"
  exit 1
fi

cat > "$OUTPUT_FILE" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>API_KEY</key>
	<string>${API_KEY}</string>
	<key>GCM_SENDER_ID</key>
	<string>${GCM_SENDER_ID}</string>
	<key>PLIST_VERSION</key>
	<string>1</string>
	<key>BUNDLE_ID</key>
	<string>${BUNDLE_ID}</string>
	<key>PROJECT_ID</key>
	<string>${PROJECT_ID}</string>
	<key>STORAGE_BUCKET</key>
	<string>${STORAGE_BUCKET}</string>
	<key>IS_ADS_ENABLED</key>
	<false></false>
	<key>IS_ANALYTICS_ENABLED</key>
	<false></false>
	<key>IS_APPINVITE_ENABLED</key>
	<true></true>
	<key>IS_GCM_ENABLED</key>
	<true></true>
	<key>IS_SIGNIN_ENABLED</key>
	<true></true>
	<key>GOOGLE_APP_ID</key>
	<string>${GOOGLE_APP_ID}</string>
</dict>
</plist>
PLIST

echo "Generated GoogleService-Info.plist from .env"
