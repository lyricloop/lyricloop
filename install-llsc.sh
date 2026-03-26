#!/usr/bin/env bash

set -e

APP_NAME="llsc"
REPO="lyricloop/lyricloop" ## binaries will be released on public repo
INSTALL_DIR="/usr/local/bin"
VERSION=v0.1.3
SERVICE_FILE="/etc/systemd/system/${APP_NAME}.service"
ENV_FILE="/etc/${APP_NAME}.env"

echo "Installing $APP_NAME..."

# Temp dir
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

echo "Fetching latest release..."

# Get latest release download URL (assumes naming like: llsc-x86_64-linux)
DOWNLOAD_URL="https://github.com/$REPO/releases/latest/download/$VERSION/$APP_NAME"

echo "🔗 Downloading from: $DOWNLOAD_URL"
curl -L "$DOWNLOAD_URL" -o "$APP_NAME"

chmod +x "$APP_NAME"

echo "Installing binary to $INSTALL_DIR"
sudo mv "$APP_NAME" "$INSTALL_DIR/$APP_NAME"

# Create env file if not exists
if [ ! -f "$ENV_FILE" ]; then
  echo "Creating env file at $ENV_FILE"
  sudo tee "$ENV_FILE" > /dev/null <<EOF
SQLITE_DATABASE_URL=
MONGODB_URI=
MONGODB_DATABASE=
ENABLED_PLUGINS=
EOF
else
  echo "Env file already exists, skipping"
fi

# Create systemd service
echo "Creating systemd service"

sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=$APP_NAME service
After=network.target

[Service]
ExecStart=$INSTALL_DIR/$APP_NAME
EnvironmentFile=$ENV_FILE
Restart=always
RestartSec=5

# Security (optional but good)
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

echo "Installation complete!"
echo ""
echo "Update env [IMPORTANT!]:"
echo "  sudo vim $ENV_FILE"
echo ""
echo "Start service:"
echo "  sudo systemctl start $APP_NAME"
echo ""
echo "View logs:"
echo "  journalctl -u $APP_NAME -f"
