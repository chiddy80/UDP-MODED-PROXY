#!/bin/bash

# Script: moded-udp.sh
# Purpose: Install UDP Custom binary for ARM64 with optimization
# Credit: Esimfreegb
# Author: Esimfreegb

# clear screen
clear

# Define variables
INSTALL_DIR="/root/udp"
BINARY_NAME="udp-custom"
BINARY_URL="https://raw.githubusercontent.com/chiddy80/UDP-MODED-PROXY/main/moded-udp-arm64"
BINARY_PATH="$INSTALL_DIR/$BINARY_NAME"
CONFIG_DIR="/etc/udp"
CONFIG_FILE="$CONFIG_DIR/config.json"
SERVICE_FILE="/etc/systemd/system/udp-custom.service"

# Help function
display_help() {
  clear
  echo "Install UDP Custom binary for ARM64 with optimization."
  echo "Author: voltsshx"
  echo "Credit: ePro Dev. Team"
  echo ""
  echo "Cycle: UDP → QUIC → BBR → VPS → Internet"
  echo "This setup optimizes UDP traffic with QUIC protocol and BBR congestion control."
  echo ""
  echo "Usage: $0 [OPTION]"
  echo
  echo "Options:"
  echo "  -h, --help     Display this help and exit"
  echo "  -i, --install  Install UDP Custom with optimization"
  echo "  -c, --config   Generate optimized configuration only"
  echo "  -s, --service  Create systemd service only"
  echo "  -o, --optimize Apply system optimizations (BBR, sysctl)"
  echo ""
  echo "Examples:"
  echo "  $0 --install    Full installation with optimizations"
  echo "  $0 --config     Generate config only"
  echo ""
  echo "Run binary manually:"
  echo "  $BINARY_PATH server --config $CONFIG_FILE"
  echo ""
}

# Function to apply system optimizations
apply_optimizations() {
  echo "Applying system optimizations..."
  
  # Enable BBR congestion control
  echo "Enabling BBR congestion control..."
  echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
  echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
  
  # UDP buffer optimizations
  echo "Optimizing UDP buffer sizes..."
  echo "net.core.rmem_max=134217728" >> /etc/sysctl.conf
  echo "net.core.wmem_max=134217728" >> /etc/sysctl.conf
  echo "net.core.rmem_default=16777216" >> /etc/sysctl.conf
  echo "net.core.wmem_default=16777216" >> /etc/sysctl.conf
  echo "net.ipv4.udp_mem=1024000 8738000 134217728" >> /etc/sysctl.conf
  echo "net.ipv4.udp_rmem_min=8192" >> /etc/sysctl.conf
  echo "net.ipv4.udp_wmem_min=8192" >> /etc/sysctl.conf
  
  # General network optimizations
  echo "Applying general network optimizations..."
  echo "net.ipv4.tcp_rmem=8192 87380 134217728" >> /etc/sysctl.conf
  echo "net.ipv4.tcp_wmem=8192 65536 134217728" >> /etc/sysctl.conf
  echo "net.ipv4.tcp_mtu_probing=1" >> /etc/sysctl.conf
  echo "net.ipv4.tcp_slow_start_after_idle=0" >> /etc/sysctl.conf
  
  # Apply sysctl changes
  sysctl -p
  
  echo "System optimizations applied successfully!"
}

# Function to generate optimized config
generate_config() {
  echo "Generating optimized configuration for UDP → QUIC → BBR cycle..."
  
  # Create config directory
  mkdir -p "$CONFIG_DIR"
  
  # Generate config file
  cat > "$CONFIG_FILE" << EOF
{
  "listen": ":36712",
  "protocol": "quic",
  "cert": "",
  "key": "",
  "congestion_control": "bbr",
  "alpn": ["h3"],
  "max_streams": 100,
  "max_connections": 1000,
  "send_buffer": 16777216,
  "receive_buffer": 16777216,
  "disable_mtu_discovery": false,
  "timeout": 300,
  "log_level": "info",
  "obfs": "plain",
  "auth": {
    "mode": "none",
    "config": {}
  },
  "server_settings": {
    "max_idle_timeout": 30000000000,
    "max_udp_payload_size": 1472,
    "enable_statistics": true,
    "statistics_interval": 60
  },
  "client_settings": {
    "fast_open": true,
    "multipath": false,
    "keep_alive": true,
    "keep_alive_interval": 30
  }
}
EOF
  
  echo "Configuration generated at: $CONFIG_FILE"
  echo ""
  echo "Edit the config file to customize:"
  echo "1. Change 'listen' port (default: 36712)"
  echo "2. Add TLS cert/key for QUIC security (optional)"
  echo "3. Adjust buffer sizes based on your VPS memory"
}

# Function to create systemd service
create_service() {
  echo "Creating systemd service..."
  
  cat > "$SERVICE_FILE" << EOF
[Unit]
Description=UDP Custom Server with QUIC+BBR
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$BINARY_PATH server --config $CONFIG_FILE
Restart=on-failure
RestartSec=5
LimitNOFILE=infinity
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=udp-custom

# Security hardening
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=$CONFIG_DIR $INSTALL_DIR

[Install]
WantedBy=multi-user.target
EOF
  
  # Reload systemd and enable service
  systemctl daemon-reload
  systemctl enable udp-custom.service
  
  echo "Systemd service created and enabled."
  echo "Commands to manage the service:"
  echo "  systemctl start udp-custom    # Start service"
  echo "  systemctl stop udp-custom     # Stop service"
  echo "  systemctl status udp-custom   # Check status"
  echo "  journalctl -u udp-custom -f   # View logs"
}

# Function to install binary
install_binary() {
  echo "Installing $BINARY_NAME for ARM64..."
  
  # Ensure the installation directory exists
  mkdir -p "$INSTALL_DIR"
  
  # Download the binary
  curl -sSL -o "$BINARY_PATH" "$BINARY_URL"
  
  # Make it executable
  chmod +x "$BINARY_PATH"
  
  # Check if installation was successful
  if [ $? -eq 0 ]; then
    echo "✓ $BINARY_NAME installed successfully in $INSTALL_DIR"
    return 0
  else
    echo "✗ Failed to install $BINARY_NAME"
    return 1
  fi
}

# Function for full installation
full_installation() {
  echo "=== Full Installation: UDP → QUIC → BBR Optimization ==="
  echo ""
  
  # Check if running as root
  if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
  fi
  
  # Install binary
  install_binary
  if [ $? -ne 0 ]; then
    exit 1
  fi
  
  # Apply system optimizations
  echo ""
  apply_optimizations
  
  # Generate config
  echo ""
  generate_config
  
  # Create service
  echo ""
  create_service
  
  # Summary
  echo ""
  echo "=== Installation Complete ==="
  echo ""
  echo "UDP Custom installed with optimization cycle:"
  echo "  UDP → QUIC → BBR → VPS → Internet"
  echo ""
  echo "Files:"
  echo "  Binary:      $BINARY_PATH"
  echo "  Config:      $CONFIG_FILE"
  echo "  Service:     $SERVICE_FILE"
  echo ""
  echo "Next steps:"
  echo "1. Edit config if needed: nano $CONFIG_FILE"
  echo "2. Start service: systemctl start udp-custom"
  echo "3. Check status: systemctl status udp-custom"
  echo "4. Open firewall port (default: 36712/UDP)"
  echo ""
  echo "To test manually:"
  echo "  $BINARY_PATH server --config $CONFIG_FILE"
}

# Main script logic
case "$1" in
  -h|--help)
    display_help
    ;;
  -i|--install)
    full_installation
    ;;
  -c|--config)
    generate_config
    ;;
  -s|--service)
    create_service
    ;;
  -o|--optimize)
    apply_optimizations
    ;;
  *)
    if [ $# -eq 0 ]; then
      # No arguments, run full installation
      full_installation
    else
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
    fi
    ;;
esac
