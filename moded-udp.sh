#!/bin/bash

# Script: optimized-udp-boost.sh
# Purpose: Install and optimize UDP server for AMD64 with UDP boost
# Author: Your Name
# Based on: Esimfreegb's script

# clear screen
clear

# Define variables
INSTALL_DIR="/root/udp"
BINARY_NAME="udp-custom"
BINARY_URL="https://raw.githubusercontent.com/chiddy80/UDP-MODED-PROXY/main/udp-custom"
BINARY_PATH="$INSTALL_DIR/$BINARY_NAME"
CONFIG_DIR="/etc/udp"
CONFIG_FILE="$CONFIG_DIR/config.json"
SERVICE_FILE="/etc/systemd/system/udp-boost.service"
EDNS_CONFIG="/etc/udp/edns.conf"
SLOWDNS_CONFIG="/etc/udp/slowdns.conf"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Help function
display_help() {
  clear
  echo -e "${BLUE}=== UDP Boost Installation Script ===${NC}"
  echo "Install and optimize UDP server for AMD64 with UDP boost."
  echo "Optimized for: UDP + BBR + EDNS + Buffer Tuning"
  echo ""
  echo -e "${GREEN}Optimization Layers:${NC}"
  echo "  1. Download and install UDP binary from GitHub"
  echo "  2. UDP Socket Buffer Tuning"
  echo "  3. BBR Congestion Control"
  echo "  4. Network Stack Optimization"
  echo "  5. EDNS (Extension Mechanisms for DNS)"
  echo "  6. System-wide UDP optimizations"
  echo ""
  echo "Usage: $0 [OPTION]"
  echo
  echo "Options:"
  echo "  -h, --help     Display this help and exit"
  echo "  -i, --install  Full installation with all optimizations"
  echo "  -d, --download Download binary only"
  echo "  -b, --boost    Apply UDP boost optimizations only"
  echo "  -e, --edns     Configure EDNS settings"
  echo "  -t, --tune     Tune system for UDP performance"
  echo "  -m, --monitor  Monitor UDP performance"
  echo "  -r, --remove   Remove installation"
  echo ""
  echo "Examples:"
  echo "  $0 --install    Full installation with all optimizations"
  echo "  $0 --download   Download binary only"
  echo "  $0 --boost      Apply UDP boost optimizations"
  echo ""
}

# Function to check architecture
check_architecture() {
  ARCH=$(uname -m)
  echo -e "${YELLOW}Detected architecture: $ARCH${NC}"
  
  if [[ "$ARCH" != "x86_64" && "$ARCH" != "amd64" ]]; then
    echo -e "${RED}Warning: This script is optimized for AMD64/x86_64${NC}"
    echo -e "${YELLOW}Your architecture is: $ARCH${NC}"
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      exit 1
    fi
  fi
}

# Function to download and install binary
download_binary() {
  echo -e "${BLUE}=== Downloading UDP Binary ===${NC}"
  
  # Create installation directory
  mkdir -p "$INSTALL_DIR"
  
  # Check if binary already exists
  if [[ -f "$BINARY_PATH" ]]; then
    echo -e "${YELLOW}Binary already exists at: $BINARY_PATH${NC}"
    echo -e "${YELLOW}Backing up old binary...${NC}"
    mv "$BINARY_PATH" "${BINARY_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
  fi
  
  echo -e "${BLUE}Downloading binary from GitHub...${NC}"
  echo -e "${YELLOW}URL: $BINARY_URL${NC}"
  
  # Download the binary
  if command -v wget &> /dev/null; then
    wget -O "$BINARY_PATH" "$BINARY_URL" --timeout=30 --tries=3
  elif command -v curl &> /dev/null; then
    curl -L -o "$BINARY_PATH" "$BINARY_URL" --connect-timeout 30 --retry 3
  else
    echo -e "${RED}Error: Neither wget nor curl found. Installing wget...${NC}"
    apt-get update && apt-get install -y wget
    wget -O "$BINARY_PATH" "$BINARY_URL" --timeout=30 --tries=3
  fi
  
  # Check if download was successful
  if [[ $? -eq 0 ]] && [[ -f "$BINARY_PATH" ]]; then
    echo -e "${GREEN}✓ Binary downloaded successfully${NC}"
    
    # Make binary executable
    chmod +x "$BINARY_PATH"
    
    # Set ownership
    chown root:root "$BINARY_PATH"
    
    # Check if binary is executable
    if [[ -x "$BINARY_PATH" ]]; then
      echo -e "${GREEN}✓ Binary is executable${NC}"
      
      # Test binary (optional)
      echo -e "${YELLOW}Testing binary version...${NC}"
      if "$BINARY_PATH" --version &>/dev/null || "$BINARY_PATH" -v &>/dev/null; then
        echo -e "${GREEN}✓ Binary test successful${NC}"
      else
        echo -e "${YELLOW}⚠ Could not get version info, but binary exists${NC}"
      fi
    else
      echo -e "${RED}✗ Failed to make binary executable${NC}"
      return 1
    fi
    
    # Get file info
    echo ""
    echo -e "${BLUE}Binary Information:${NC}"
    echo "Size: $(du -h "$BINARY_PATH" | cut -f1)"
    echo "Type: $(file "$BINARY_PATH" | cut -d: -f2-)"
    echo "Permissions: $(stat -c "%A %U %G" "$BINARY_PATH")"
    
    return 0
  else
    echo -e "${RED}✗ Failed to download binary${NC}"
    echo "Please check:"
    echo "1. Internet connection"
    echo "2. GitHub URL availability"
    echo "3. File permissions"
    return 1
  fi
}

# Function to install dependencies
install_dependencies() {
  echo -e "${BLUE}=== Installing Dependencies ===${NC}"
  
  apt-get update
  
  # Essential tools
  apt-get install -y \
    curl wget net-tools iproute2 \
    dnsutils resolvconf \
    iftop nethogs bmon \
    tuned-utils \
    jq \
    ipset conntrack \
    screen htop \
    ufw iptables-persistent
  
  # For monitoring
  apt-get install -y \
    iotop sysstat \
    ethtool tcpdump \
    bc stress-ng \
    netcat socat
  
  echo -e "${GREEN}✓ Dependencies installed${NC}"
}

# Function to apply UDP boost optimizations
apply_udp_boost() {
  echo -e "${BLUE}=== Applying UDP Boost Optimizations ===${NC}"
  
  # Backup current sysctl
  cp /etc/sysctl.conf /etc/sysctl.conf.backup.$(date +%Y%m%d)
  
  # Extreme UDP buffer tuning
  cat >> /etc/sysctl.conf << EOF

# ==============================================
# UDP Boost Optimizations - $(date)
# ==============================================

# Enable BBR congestion control
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# UDP Buffer sizes (EXTREME for high throughput)
net.core.rmem_max = 268435456      # 256MB
net.core.wmem_max = 268435456      # 256MB
net.core.rmem_default = 33554432   # 32MB
net.core.wmem_default = 33554432   # 32MB
net.core.optmem_max = 4194304      # 4MB

# UDP memory pressures
net.ipv4.udp_mem = 1024000 8738000 268435456
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384

# Socket buffer tuning
net.ipv4.tcp_rmem = 4096 87380 268435456
net.ipv4.tcp_wmem = 4096 65536 268435456

# Network core settings
net.core.netdev_max_backlog = 100000
net.core.netdev_budget = 600
net.core.netdev_budget_usecs = 8000
net.core.somaxconn = 65535

# IPv4 settings
net.ipv4.tcp_max_syn_backlog = 65536
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_retries2 = 8

# Reduce TIME_WAIT socket time
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0

# Increase local port range
net.ipv4.ip_local_port_range = 1024 65535

# Disable slow start after idle
net.ipv4.tcp_slow_start_after_idle = 0

# Increase connection tracking
net.netfilter.nf_conntrack_max = 2097152
net.netfilter.nf_conntrack_tcp_timeout_established = 86400

# Memory pressure adjustments
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
EOF

  # Apply sysctl
  sysctl -p
  
  echo -e "${GREEN}✓ UDP boost optimizations applied${NC}"
}

# Function to configure EDNS
configure_edns() {
  echo -e "${BLUE}=== Configuring EDNS (Extension Mechanisms for DNS) ===${NC}"
  
  # Create EDNS configuration
  mkdir -p "$CONFIG_DIR"
  
  cat > "$EDNS_CONFIG" << EOF
# EDNS Configuration for UDP Optimization
# Larger UDP payload support for DNS

options {
  edns-udp-size 4096;  # Increased UDP buffer for DNS
  max-udp-size 4096;   # Maximum UDP packet size
  edns yes;            # Enable EDNS
  dnssec-validation no; # Disable for performance (enable if needed)
  auth-nxdomain no;
  listen-on-v6 { any; };
  
  # Performance tuning
  recursor-query-timeout 10000;
  max-recursion-depth 30;
  max-cache-size 256M;
  max-cache-ttl 3600;
  minimal-responses yes;
};

# Forwarders for better DNS resolution
forwarders {
  8.8.8.8;
  8.8.4.4;
  1.1.1.1;
  1.0.0.1;
};
EOF

  # Install bind9 for DNS server if not present
  if ! command -v named &> /dev/null; then
    echo -e "${YELLOW}Installing bind9...${NC}"
    apt-get install -y bind9 bind9utils
  fi
  
  # Link configuration
  if [ -d "/etc/bind" ]; then
    cp "$EDNS_CONFIG" /etc/bind/named.conf.options
    systemctl restart bind9
    echo -e "${GREEN}✓ EDNS configured with bind9${NC}"
  fi
  
  echo -e "${GREEN}✓ EDNS configuration created at: $EDNS_CONFIG${NC}"
}

# Function to setup SlowDNS
setup_slowdns() {
  echo -e "${BLUE}=== Setting up SlowDNS Configuration ===${NC}"
  
  cat > "$SLOWDNS_CONFIG" << EOF
# SlowDNS Configuration
# For DNS-based UDP tunneling

[server]
# Server settings
listen = "0.0.0.0:53"
protocol = "udp"
timeout = 300
keepalive = 30

# Performance tuning
max_clients = 1000
buffer_size = 4096
workers = 2

# DNS settings
dns_server = "8.8.8.8:53"
dns_timeout = 5
enable_compression = true
enable_encryption = false

[logging]
level = "info"
file = "/var/log/slowdns.log"
max_size = 100
max_files = 3
EOF

  echo -e "${GREEN}✓ SlowDNS configuration created at: $SLOWDNS_CONFIG${NC}"
}

# Function to tune network interfaces
tune_network_interfaces() {
  echo -e "${BLUE}=== Tuning Network Interfaces ===${NC}"
  
  # Get active interfaces
  INTERFACES=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo)
  
  for IFACE in $INTERFACES; do
    echo -e "${YELLOW}Tuning interface: $IFACE${NC}"
    
    # Increase ring buffers
    ethtool -G $IFACE rx 4096 tx 4096 2>/dev/null || echo -e "${YELLOW}⚠ Could not set ring buffers for $IFACE${NC}"
    
    # Enable generic receive offload
    ethtool -K $IFACE gro on gso on tso on 2>/dev/null || echo -e "${YELLOW}⚠ Could not set offload for $IFACE${NC}"
    
    # Set interrupt coalescing
    ethtool -C $IFACE rx-usecs 50 rx-frames 32 tx-usecs 50 tx-frames 32 2>/dev/null || echo -e "${YELLOW}⚠ Could not set coalescing for $IFACE${NC}"
    
    # Enable hardware timestamping if available
    ethtool -T $IFACE 2>/dev/null | grep -q "hardware-transmit" && \
      ethtool -K $IFACE hw-tc-offload on 2>/dev/null || true
    
    # Set MTU to maximum if not set
    CURRENT_MTU=$(ip link show $IFACE | grep mtu | awk '{print $5}' 2>/dev/null || echo "1500")
    if [ "$CURRENT_MTU" -lt 9000 ]; then
      ip link set $IFACE mtu 9000 2>/dev/null || echo -e "${YELLOW}⚠ Could not set MTU for $IFACE${NC}"
    fi
  done
  
  # Create tuning script for persistence
  cat > /etc/network/if-up.d/udp-tune << 'EOF'
#!/bin/bash
# Tune network interfaces on startup

sleep 2  # Wait for interface to be fully up

for IFACE in $(ip -o link show | awk -F': ' '{print $2}' | grep -v lo); do
    # Ethtool settings
    ethtool -G $IFACE rx 4096 tx 4096 2>/dev/null || true
    ethtool -K $IFACE gro on gso on tso on 2>/dev/null || true
    ethtool -C $IFACE rx-usecs 50 rx-frames 32 tx-usecs 50 tx-frames 32 2>/dev/null || true
    
    # MTU
    ip link set $IFACE mtu 9000 2>/dev/null || true
    
    echo "Tuned interface: $IFACE"
done
EOF
  
  chmod +x /etc/network/if-up.d/udp-tune
  echo -e "${GREEN}✓ Network interfaces tuned and persistence configured${NC}"
}

# Function to create UDP server config
create_udp_config() {
  echo -e "${BLUE}=== Creating UDP Server Configuration ===${NC}"
  
  mkdir -p "$CONFIG_DIR"
  
  cat > "$CONFIG_FILE" << EOF
{
  "server": {
    "listen": [
      {
        "protocol": "udp",
        "address": "0.0.0.0",
        "port": 36712,
        "workers": 2,
        "buffer_size": 4194304,
        "receive_buffer": 33554432,
        "send_buffer": 33554432,
        "timeout": 300
      }
    ],
    "max_connections": 10000,
    "connection_timeout": 300,
    "keepalive": 30,
    "reuse_port": true,
    "reuse_address": true,
    "tcp_fastopen": true,
    "tcp_nodelay": true
  },
  
  "performance": {
    "io_threads": 4,
    "worker_threads": 4,
    "max_pending_packets": 100000,
    "packet_queue_size": 65536,
    "enable_batch_processing": true,
    "batch_size": 64,
    "enable_zero_copy": true
  },
  
  "tuning": {
    "congestion_control": "bbr",
    "enable_ecn": true,
    "enable_pacing": true,
    "pacing_rate": "1gbit"
  },
  
  "dns": {
    "enable_dns": true,
    "dns_server": "8.8.8.8:53",
    "dns_timeout": 5,
    "enable_edns": true,
    "edns_buffer_size": 4096
  },
  
  "logging": {
    "level": "info",
    "file": "/var/log/udp-server.log",
    "max_size": 100,
    "max_files": 5,
    "enable_syslog": true
  }
}
EOF
  
  # Create sample startup script
  cat > "$INSTALL_DIR/start.sh" << 'EOF'
#!/bin/bash
# UDP Server startup script

echo "Starting UDP Custom Server..."
echo "Binary: $(which udp-custom)"
echo "Config: /etc/udp/config.json"
echo ""

# Check if binary exists
if [ ! -f "/root/udp/udp-custom" ]; then
    echo "Error: Binary not found at /root/udp/udp-custom"
    exit 1
fi

# Check if config exists
if [ ! -f "/etc/udp/config.json" ]; then
    echo "Error: Config not found at /etc/udp/config.json"
    exit 1
fi

# Start server
cd /root/udp
./udp-custom server --config /etc/udp/config.json
EOF
  
  chmod +x "$INSTALL_DIR/start.sh"
  
  echo -e "${GREEN}✓ UDP server configuration created${NC}"
  echo "Config: $CONFIG_FILE"
  echo "Start script: $INSTALL_DIR/start.sh"
}

# Function to create systemd service
create_udp_service() {
  echo -e "${BLUE}=== Creating Systemd Service ===${NC}"
  
  cat > "$SERVICE_FILE" << EOF
[Unit]
Description=UDP Boost Server with BBR Tuning
After=network.target network-online.target nss-lookup.target
Wants=network-online.target
Requires=bind9.service

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$BINARY_PATH server --config $CONFIG_FILE
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=3
LimitNOFILE=1000000
LimitNPROC=1000000
LimitCORE=infinity
TimeoutStopSec=10
KillMode=process
KillSignal=SIGTERM
SyslogIdentifier=udp-boost
StandardOutput=syslog
StandardError=syslog

# CPU and I/O priority
CPUSchedulingPolicy=rr
CPUSchedulingPriority=1

# Security
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
PrivateDevices=yes
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes
MemoryDenyWriteExecute=yes

[Install]
WantedBy=multi-user.target
EOF
  
  systemctl daemon-reload
  systemctl enable udp-boost.service
  
  echo -e "${GREEN}✓ Systemd service created${NC}"
  echo ""
  echo -e "${YELLOW}Service Management Commands:${NC}"
  echo "  systemctl start udp-boost      # Start service"
  echo "  systemctl stop udp-boost       # Stop service"
  echo "  systemctl restart udp-boost    # Restart service"
  echo "  systemctl status udp-boost     # Check status"
  echo "  journalctl -u udp-boost -f     # View logs"
}

# Function to setup firewall
setup_firewall() {
  echo -e "${BLUE}=== Setting up Firewall ===${NC}"
  
  # Check if UFW is available
  if command -v ufw &> /dev/null; then
    echo -e "${YELLOW}Configuring UFW firewall...${NC}"
    
    # Enable UFW if not enabled
    if ! ufw status | grep -q "Status: active"; then
      ufw --force enable
    fi
    
    # Allow SSH
    ufw allow 22/tcp comment 'SSH'
    
    # Allow UDP port
    ufw allow 36712/udp comment 'UDP Boost Server'
    
    # Allow DNS if using
    ufw allow 53/udp comment 'DNS'
    ufw allow 53/tcp comment 'DNS TCP'
    
    # Reload UFW
    ufw reload
    
    echo -e "${GREEN}✓ Firewall configured${NC}"
    echo "Open ports:"
    ufw status numbered | grep -E "(36712|53|22)"
  else
    echo -e "${YELLOW}UFW not installed. Using iptables...${NC}"
    
    # Basic iptables rules
    iptables -A INPUT -p udp --dport 36712 -j ACCEPT
    iptables -A INPUT -p udp --dport 53 -j ACCEPT
    iptables -A INPUT -p tcp --dport 53 -j ACCEPT
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    
    # Save iptables rules if iptables-persistent is installed
    if command -v netfilter-persistent &> /dev/null; then
      netfilter-persistent save
    fi
    
    echo -e "${GREEN}✓ Basic iptables rules added${NC}"
  fi
}

# Function to install performance monitoring
install_monitoring() {
  echo -e "${BLUE}=== Installing Performance Monitoring ===${NC}"
  
  # Create monitoring script
  cat > /usr/local/bin/udp-monitor << 'EOF'
#!/bin/bash

echo "========================================"
echo "    UDP Performance Monitor"
echo "    Time: $(date)"
echo "========================================"
echo ""

# System information
echo "=== System Information ==="
echo "Uptime: $(uptime -p)"
echo "Load: $(cat /proc/loadavg)"
echo ""

# Network statistics
echo "=== Network Statistics ==="
echo "UDP Statistics:"
netstat -su | grep -E "(packets|receive|send|errors|drops)" | head -10
echo ""

echo "Interface Statistics:"
ip -s link show | grep -A2 -E "^[0-9]+:" | head -20
echo ""

# Connection information
echo "=== Connection Information ==="
echo "UDP Connections:"
ss -u -a -p | head -20
echo ""

echo "Active Connections:"
ss -tunap | head -20
echo ""

# Buffer information
echo "=== Buffer Information ==="
echo "Socket Buffers:"
echo "rmem_max: $(cat /proc/sys/net/core/rmem_max)"
echo "wmem_max: $(cat /proc/sys/net/core/wmem_max)"
echo "rmem_default: $(cat /proc/sys/net/core/rmem_default)"
echo "wmem_default: $(cat /proc/sys/net/core/wmem_default)"
echo ""

# Service status
echo "=== Service Status ==="
systemctl status udp-boost --no-pager | head -20
echo ""

echo "========================================"
echo "    Monitor Complete"
echo "========================================"
EOF
  
  chmod +x /usr/local/bin/udp-monitor
  
  # Create log rotation
  cat > /etc/logrotate.d/udp-server << EOF
/var/log/udp-server.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
    postrotate
        systemctl reload udp-boost > /dev/null 2>&1 || true
    endscript
}
EOF
  
  echo -e "${GREEN}✓ Monitoring tools installed${NC}"
  echo -e "${YELLOW}Run 'udp-monitor' to check system status${NC}"
}

# Function to verify installation
verify_installation() {
  echo -e "${BLUE}=== Verifying Installation ===${NC}"
  
  echo -e "${YELLOW}Checking files...${NC}"
  
  # Check binary
  if [[ -f "$BINARY_PATH" ]] && [[ -x "$BINARY_PATH" ]]; then
    echo -e "${GREEN}✓ Binary exists and is executable${NC}"
  else
    echo -e "${RED}✗ Binary missing or not executable${NC}"
  fi
  
  # Check config
  if [[ -f "$CONFIG_FILE" ]]; then
    echo -e "${GREEN}✓ Config file exists${NC}"
  else
    echo -e "${RED}✗ Config file missing${NC}"
  fi
  
  # Check service
  if [[ -f "$SERVICE_FILE" ]]; then
    echo -e "${GREEN}✓ Service file exists${NC}"
  else
    echo -e "${RED}✗ Service file missing${NC}"
  fi
  
  # Check sysctl settings
  echo -e "${YELLOW}Checking sysctl settings...${NC}"
  sysctl net.core.rmem_max | grep -q "268435456" && echo -e "${GREEN}✓ UDP buffers tuned${NC}" || echo -e "${RED}✗ UDP buffers not tuned${NC}"
  sysctl net.ipv4.tcp_congestion_control | grep -q "bbr" && echo -e "${GREEN}✓ BBR enabled${NC}" || echo -e "${RED}✗ BBR not enabled${NC}"
  
  echo ""
  echo -e "${YELLOW}Quick Test Commands:${NC}"
  echo "  Test binary: $BINARY_PATH --version"
  echo "  Check service: systemctl status udp-boost"
  echo "  Monitor: udp-monitor"
}

# Function to remove installation
remove_installation() {
  echo -e "${RED}=== Removing UDP Boost Installation ===${NC}"
  
  read -p "Are you sure you want to remove UDP Boost? (y/n): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Removal cancelled."
    return
  fi
  
  # Stop and disable service
  systemctl stop udp-boost.service 2>/dev/null || true
  systemctl disable udp-boost.service 2>/dev/null || true
  rm -f "$SERVICE_FILE"
  systemctl daemon-reload
  
  # Remove files
  rm -rf "$INSTALL_DIR" 2>/dev/null || true
  rm -rf "$CONFIG_DIR" 2>/dev/null || true
  rm -f /usr/local/bin/udp-monitor 2>/dev/null || true
  
  echo -e "${GREEN}✓ UDP Boost removed${NC}"
}

# Full installation function
full_installation() {
  echo -e "${BLUE}=== UDP Boost Full Installation ===${NC}"
  echo -e "${YELLOW}Optimizing for: AMD64 UDP Server with BBR Tuning${NC}"
  echo ""
  
  # Check root
  if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root${NC}"
    exit 1
  fi
  
  # Check architecture
  check_architecture
  
  # Install dependencies
  install_dependencies
  
  # Download binary
  download_binary
  if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to download binary. Installation aborted.${NC}"
    exit 1
  fi
  
  # Apply UDP boost
  apply_udp_boost
  
  # Tune network interfaces
  tune_network_interfaces
  
  # Configure EDNS
  configure_edns
  
  # Setup SlowDNS config
  setup_slowdns
  
  # Create UDP config
  create_udp_config
  
  # Create service
  create_udp_service
  
  # Setup firewall
  setup_firewall
  
  # Install monitoring
  install_monitoring
  
  # Verify installation
  verify_installation
  
  # Summary
  echo ""
  echo -e "${GREEN}=== Installation Complete ===${NC}"
  echo ""
  echo -e "${YELLOW}Optimizations applied:${NC}"
  echo "  ✓ Downloaded and installed UDP binary from GitHub"
  echo "  ✓ UDP Buffer Tuning (up to 256MB)"
  echo "  ✓ BBR Congestion Control"
  echo "  ✓ Network Interface Tuning"
  echo "  ✓ EDNS Configuration"
  echo "  ✓ SlowDNS Setup"
  echo "  ✓ Systemd Service with security"
  echo "  ✓ Firewall configuration"
  echo "  ✓ Performance Monitoring"
  echo ""
  echo -e "${YELLOW}Files created:${NC}"
  echo "  Binary:      $BINARY_PATH"
  echo "  Config:      $CONFIG_FILE"
  echo "  EDNS Config: $EDNS_CONFIG"
  echo "  SlowDNS:     $SLOWDNS_CONFIG"
  echo "  Service:     $SERVICE_FILE"
  echo ""
  echo -e "${YELLOW}Next steps:${NC}"
  echo "1. Start service: systemctl start udp-boost"
  echo "2. Check logs: journalctl -u udp-boost -f"
  echo "3. Monitor: udp-monitor"
  echo "4. Test connection: nc -zu $(hostname -I | awk '{print $1}') 36712"
  echo ""
  echo -e "${YELLOW}Manual start:${NC}"
  echo "  $BINARY_PATH server --config $CONFIG_FILE"
  echo ""
}

# Monitor function
monitor_udp() {
  echo -e "${BLUE}=== UDP Performance Monitoring ===${NC}"
  echo ""
  
  # Real-time monitoring with watch
  if command -v watch &> /dev/null; then
    echo -e "${YELLOW}Starting real-time UDP monitoring (Ctrl+C to stop)...${NC}"
    echo ""
    watch -n 2 "echo 'UDP Stats:'; netstat -su | grep -E '(packets|receive|send|errors|drops)' | head -10; echo ''; echo 'Active UDP Connections:'; ss -u -a -p | head -15"
  else
    echo -e "${YELLOW}Install 'watch' for real-time monitoring: apt-get install watch${NC}"
    echo ""
    udp-monitor
  fi
}

# Main script logic
case "$1" in
  -h|--help)
    display_help
    ;;
  -i|--install)
    full_installation
    ;;
  -d|--download)
    check_architecture
    download_binary
    ;;
  -b|--boost)
    apply_udp_boost
    tune_network_interfaces
    ;;
  -e|--edns)
    configure_edns
    setup_slowdns
    ;;
  -t|--tune)
    apply_udp_boost
    tune_network_interfaces
    create_udp_config
    ;;
  -m|--monitor)
    monitor_udp
    ;;
  -r|--remove)
    remove_installation
    ;;
  *)
    if [ $# -eq 0 ]; then
      full_installation
    else
      echo -e "${RED}Unknown option: $1${NC}"
      echo -e "${YELLOW}Use --help for usage information${NC}"
      exit 1
    fi
    ;;
esac
```

Key Features Added:

1. Binary Download Function:

```bash
# Downloads binary from your GitHub URL
BINARY_URL="https://raw.githubusercontent.com/chiddy80/UDP-MODED-PROXY/main/udp-custom"

# Downloads with retry and timeout
wget -O "$BINARY_PATH" "$BINARY_URL" --timeout=30 --tries=3
```

2. Automatic Permission Setting:

```bash
# Makes binary executable
chmod +x "$BINARY_PATH"

# Sets proper ownership
chown root:root "$BINARY_PATH"

# Tests if binary is working
"$BINARY_PATH" --version &>/dev/null
```

3. Architecture Detection:

```bash
# Checks if system is AMD64
ARCH=$(uname -m)
if [[ "$ARCH" != "x86_64" && "$ARCH" != "amd64" ]]; then
    echo "Warning: This script is optimized for AMD64/x86_64"
fi
```

4. Installation Methods:

```bash
# Full installation (recommended)
./optimized-udp-boost.sh --install

# Download binary only
./optimized-udp-boost.sh --download

# Apply optimizations only
./optimized-udp-boost.sh --boost

# Remove installation
./optimized-udp-boost.sh --remove
```

5. What Gets Installed:

1. Binary: Downloaded from GitHub to /root/udp/udp-custom
2. Config: /etc/udp/config.json (optimized for UDP)
3. Service: /etc/systemd/system/udp-boost.service
4. EDNS Config: /etc/udp/edns.conf
5. SlowDNS Config: /etc/udp/slowdns.conf
6. Monitoring: /usr/local/bin/udp-monitor

6. Verification:

The script automatically:

· Downloads and makes binary executable
· Tests binary functionality
· Applies all optimizations
· Creates startup scripts
· Sets up firewall rules
· Installs monitoring tools

7. Usage Examples:

```bash
# 1. Full automated installation
chmod +x optimized-udp-boost.sh
./optimized-udp-boost.sh --install

# 2. Just download and test binary
./optimized-udp-boost.sh --download

# 3. Monitor after installation
./optimized-udp-boost.sh --monitor

# 4. Check service status
systemctl status udp-boost

# 5. View logs in real-time
journalctl -u udp-boost -f
```
