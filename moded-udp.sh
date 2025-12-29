cat > ultra-udp-optimizer.sh << 'EOF'
#!/bin/bash

# Script: ultra-udp-optimizer.sh
# Purpose: Extreme UDP optimization with packet loss prevention

clear
echo "================================================"
echo "    ULTRA UDP OPTIMIZER - MAX SPEED EDITION"
echo "================================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
INSTALL_DIR="/root/udp"
BINARY_NAME="udp-custom"
BINARY_URL="https://raw.githubusercontent.com/chiddy80/UDP-MODED-PROXY/main/udp-custom"
BINARY_PATH="$INSTALL_DIR/$BINARY_NAME"
CONFIG_DIR="/etc/udp"
CONFIG_FILE="$CONFIG_DIR/config.json"
SERVICE_FILE="/etc/systemd/system/udp-boost.service"
LOG_FILE="/var/log/udp-server.log"

# Function to check root
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${RED}Please run as root${NC}"
        exit 1
    fi
}

# Function to install binary
install_binary() {
    echo -e "${BLUE}[1] Installing/Updating UDP Binary...${NC}"
    
    mkdir -p "$INSTALL_DIR"
    
    if [ -f "$BINARY_PATH" ]; then
        echo -e "${YELLOW}Backing up existing binary...${NC}"
        mv "$BINARY_PATH" "${BINARY_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Download with multiple methods
    echo -e "${YELLOW}Downloading binary...${NC}"
    if command -v wget &> /dev/null; then
        wget -O "$BINARY_PATH" "$BINARY_URL" --timeout=30 --tries=5 --retry-connrefused
    elif command -v curl &> /dev/null; then
        curl -L -o "$BINARY_PATH" "$BINARY_URL" --connect-timeout 30 --retry 5
    else
        apt-get update && apt-get install -y wget
        wget -O "$BINARY_PATH" "$BINARY_URL" --timeout=30 --tries=5 --retry-connrefused
    fi
    
    if [ $? -eq 0 ] && [ -f "$BINARY_PATH" ]; then
        chmod +x "$BINARY_PATH"
        chown root:root "$BINARY_PATH"
        echo -e "${GREEN}✓ Binary installed${NC}"
    else
        echo -e "${RED}✗ Failed to download binary${NC}"
        exit 1
    fi
}

# Function for EXTREME kernel tuning
apply_extreme_tuning() {
    echo -e "${BLUE}[2] Applying EXTREME Kernel Tuning...${NC}"
    
    # Backup
    cp /etc/sysctl.conf /etc/sysctl.conf.backup.$(date +%Y%m%d)
    
    # Remove old UDP settings
    sed -i '/# UDP Optimizations/,/^$/d' /etc/sysctl.conf
    
    # Apply EXTREME optimizations
    cat >> /etc/sysctl.conf << 'TUNING'

# ====================================================
# EXTREME UDP OPTIMIZATIONS - MAX SPEED
# ====================================================

# ULTRA Buffer Sizes (1GB for extreme traffic)
net.core.rmem_max = 1073741824      # 1GB
net.core.wmem_max = 1073741824      # 1GB
net.core.rmem_default = 268435456   # 256MB
net.core.wmem_default = 268435456   # 256MB
net.core.optmem_max = 16777216      # 16MB

# UDP Memory EXTREME
net.ipv4.udp_mem = 2048000 16777216 1073741824
net.ipv4.udp_rmem_min = 65536
net.ipv4.udp_wmem_min = 65536

# TCP Memory (for mixed traffic)
net.ipv4.tcp_rmem = 4096 87380 1073741824
net.ipv4.tcp_wmem = 4096 65536 1073741824

# Network Core EXTREME
net.core.netdev_max_backlog = 500000
net.core.netdev_budget = 1200
net.core.netdev_budget_usecs = 16000
net.core.somaxconn = 131072
net.core.message_cost = 40
net.core.message_burst = 200

# IPv4 EXTREME Tuning
net.ipv4.tcp_max_syn_backlog = 131072
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_retries2 = 5

# Connection tracking (increase if using NAT)
net.netfilter.nf_conntrack_max = 4194304
net.netfilter.nf_conntrack_tcp_timeout_established = 86400
net.netfilter.nf_conntrack_udp_timeout = 180
net.netfilter.nf_conntrack_udp_timeout_stream = 180

# TIME_WAIT optimization
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_max_tw_buckets = 2000000

# Port range
net.ipv4.ip_local_port_range = 10000 65535

# Disable timestamps for performance
net.ipv4.tcp_timestamps = 0

# Increase ARP cache
net.ipv4.neigh.default.gc_thresh1 = 1024
net.ipv4.neigh.default.gc_thresh2 = 2048
net.ipv4.neigh.default.gc_thresh3 = 4096

# Packet forwarding (if using as router)
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1

# Disable slow start after idle
net.ipv4.tcp_slow_start_after_idle = 0

# Memory management
vm.swappiness = 1
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 5
vm.dirty_background_ratio = 1
vm.dirty_expire_centisecs = 100
vm.dirty_writeback_centisecs = 100

# EXTREME File handles
fs.file-max = 2097152
fs.nr_open = 2097152
TUNING

    # Apply settings
    sysctl -p
    echo -e "${GREEN}✓ EXTREME kernel tuning applied${NC}"
}

# Function for NIC hardware optimization
optimize_nic() {
    echo -e "${BLUE}[3] Optimizing Network Interface...${NC}"
    
    # Get all physical interfaces
    INTERFACES=$(ls /sys/class/net/ | grep -E '^eth|^enp|^ens')
    
    for IFACE in $INTERFACES; do
        echo -e "${YELLOW}Optimizing $IFACE...${NC}"
        
        # Enable ALL hardware offloading
        ethtool -K $IFACE rx on tx on sg on tso on gso on gro on lro on rxvlan on txvlan on ntuple on receive-hashing on 2>/dev/null || true
        
        # Increase ring buffers to MAX
        ethtool -G $IFACE rx 4096 tx 4096 2>/dev/null || true
        
        # Optimize interrupt coalescing
        ethtool -C $IFACE rx-usecs 8 rx-frames 32 tx-usecs 8 tx-frames 32 2>/dev/null || true
        
        # Set MTU to Jumbo frames if supported
        ip link set $IFACE mtu 9000 2>/dev/null || true
        
        # Enable multi-queue if available
        ethtool -L $IFACE combined 8 2>/dev/null || true
        
        # Set IRQ affinity for multi-core systems
        if [ -d "/proc/irq" ]; then
            IRQS=$(grep $IFACE /proc/interrupts | awk '{print $1}' | sed 's/://')
            CPU=0
            for IRQ in $IRQS; do
                echo $(printf "%x" $((1 << $CPU))) > /proc/irq/$IRQ/smp_affinity 2>/dev/null || true
                CPU=$(( (CPU + 1) % $(nproc) ))
            done
        fi
    done
    
    # Create persistent tuning
    cat > /etc/network/if-up.d/udp-ultra-tune << 'NICEOF'
#!/bin/bash
sleep 2
for IFACE in $(ls /sys/class/net/ | grep -E '^eth|^enp|^ens'); do
    ethtool -K $IFACE rx on tx on sg on tso on gso on gro on lro on rxvlan on txvlan on ntuple on receive-hashing on 2>/dev/null || true
    ethtool -G $IFACE rx 4096 tx 4096 2>/dev/null || true
    ethtool -C $IFACE rx-usecs 8 rx-frames 32 tx-usecs 8 tx-frames 32 2>/dev/null || true
    ip link set $IFACE mtu 9000 2>/dev/null || true
done
NICEOF
    
    chmod +x /etc/network/if-up.d/udp-ultra-tune
    echo -e "${GREEN}✓ Network interface optimized${NC}"
}

# Function to create ULTRA performance config
create_ultra_config() {
    echo -e "${BLUE}[4] Creating ULTRA Performance Config...${NC}"
    
    mkdir -p "$CONFIG_DIR"
    
    # Get CPU count for optimal workers
    CPU_COUNT=$(nproc)
    WORKERS=$((CPU_COUNT * 2))
    
    cat > "$CONFIG_FILE" << 'CONFIGEOF'
{
  "server": {
    "listen": [
      {
        "protocol": "udp",
        "address": "0.0.0.0",
        "port": 36712,
        "workers": WORKERS_PLACEHOLDER,
        "buffer_size": 16777216,
        "receive_buffer": 268435456,
        "send_buffer": 268435456,
        "timeout": 600,
        "read_buffer": 4194304,
        "write_buffer": 4194304
      }
    ],
    "max_connections": 100000,
    "connection_timeout": 600,
    "keepalive": 60,
    "reuse_port": true,
    "reuse_address": true,
    "tcp_fastopen": true,
    "tcp_nodelay": true,
    "tcp_keepalive": true,
    "tcp_keepalive_interval": 30,
    "enable_udp_gro": true,
    "enable_udp_gso": true,
    "enable_multi_core": true
  },
  "performance": {
    "io_threads": WORKERS_PLACEHOLDER,
    "worker_threads": WORKERS_PLACEHOLDER,
    "max_pending_packets": 500000,
    "packet_queue_size": 131072,
    "enable_batch_processing": true,
    "batch_size": 128,
    "enable_zero_copy": true,
    "enable_sendfile": true,
    "enable_splice": true,
    "buffer_pool_size": 1024,
    "buffer_pool_max_size": 4096,
    "enable_epoll_edge_trigger": true,
    "epoll_max_events": 65536
  },
  "tuning": {
    "congestion_control": "bbr",
    "enable_ecn": false,
    "enable_pacing": true,
    "pacing_rate": "10gbit",
    "initcwnd": 20,
    "initrwnd": 20,
    "tcp_notsent_lowat": 16384,
    "tcp_sack": true,
    "tcp_dsack": true,
    "tcp_fack": true
  },
  "optimization": {
    "enable_checksum_offload": true,
    "enable_scatter_gather": true,
    "enable_large_receive_offload": true,
    "enable_gso": true,
    "enable_gro": true,
    "enable_tso": true,
    "enable_ufo": true,
    "max_segment_size": 9000,
    "enable_mtu_discovery": true,
    "enable_path_mtu_discovery": true
  },
  "dns": {
    "enable_dns": false,
    "dns_server": "8.8.8.8:53",
    "dns_timeout": 3,
    "enable_edns": false,
    "edns_buffer_size": 4096,
    "dns_cache_size": 10000,
    "dns_cache_ttl": 300
  },
  "logging": {
    "level": "error",
    "file": "/var/log/udp-server.log",
    "max_size": 100,
    "max_files": 10,
    "enable_syslog": false,
    "log_connections": false,
    "log_packets": false
  },
  "security": {
    "rate_limit": 0,
    "connection_rate_limit": 0,
    "enable_firewall": false,
    "enable_blacklist": false,
    "max_packet_size": 65535,
    "min_packet_size": 20
  },
  "monitoring": {
    "enable_stats": true,
    "stats_interval": 60,
    "enable_connection_tracking": false,
    "enable_packet_counting": false
  }
}
CONFIGEOF
    
    # Replace placeholder with actual worker count
    sed -i "s/WORKERS_PLACEHOLDER/$WORKERS/g" "$CONFIG_FILE"
    
    echo -e "${GREEN}✓ ULTRA performance config created${NC}"
    echo -e "${YELLOW}Workers: $WORKERS (based on $CPU_COUNT CPU cores)${NC}"
}

# Function to fix systemd service
fix_systemd_service() {
    echo -e "${BLUE}[5] Creating Optimized Systemd Service...${NC}"
    
    # Stop any existing service
    systemctl stop udp-boost 2>/dev/null
    
    cat > "$SERVICE_FILE" << 'SERVICEEOF'
[Unit]
Description=ULTRA UDP Boost Server - Max Performance
After=network.target network-online.target
Wants=network-online.target
Conflicts=shutdown.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/udp
ExecStart=/root/udp/udp-custom server --config /etc/udp/config.json
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=1
StartLimitInterval=0
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
LimitMEMLOCK=infinity
TimeoutStopSec=10
KillMode=process
KillSignal=SIGTERM
SyslogIdentifier=udp-ultra

# EXTREME CPU and I/O priority
CPUSchedulingPolicy=rr
CPUSchedulingPriority=1
CPUSchedulingResetOnFork=true
IOSchedulingClass=realtime
IOSchedulingPriority=0

# Memory management
MemoryAccounting=yes
MemoryHigh=90%
MemoryMax=95%
MemorySwapMax=0

# CPU management
CPUAccounting=yes
CPUQuota=100%
CPUWeight=1000

# I/O management
IOAccounting=yes
IOWeight=1000

# Security (minimal for performance)
NoNewPrivileges=yes
PrivateTmp=yes
PrivateDevices=no
ProtectSystem=strict
ProtectHome=yes
ProtectKernelTunables=no
ProtectKernelModules=no
ProtectControlGroups=no

[Install]
WantedBy=multi-user.target
SERVICEEOF

    systemctl daemon-reload
    systemctl enable udp-boost
    
    echo -e "${GREEN}✓ Systemd service optimized${NC}"
}

# Function for CPU performance tuning
optimize_cpu() {
    echo -e "${BLUE}[6] Tuning CPU Performance...${NC}"
    
    # Install performance tools
    apt-get install -y cpufrequtils linux-tools-common
    
    # Set CPU governor to performance
    if command -v cpupower &> /dev/null; then
        cpupower frequency-set -g performance
        echo -e "${GREEN}✓ CPU governor set to performance${NC}"
    fi
    
    # Disable CPU frequency scaling
    for governor in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo "performance" > $governor 2>/dev/null || true
    done
    
    # Disable CPU idle states
    for state in /sys/devices/system/cpu/cpu*/cpuidle/state*/disable; do
        echo 1 > $state 2>/dev/null || true
    done
    
    echo -e "${GREEN}✓ CPU performance tuned${NC}"
}

# Function to disable power saving
disable_power_saving() {
    echo -e "${BLUE}[7] Disabling Power Saving Features...${NC}"
    
    # Disable NIC power saving
    for IFACE in $(ls /sys/class/net/ | grep -E '^eth|^enp|^ens'); do
        ethtool -s $IFACE wol d 2>/dev/null || true
    done
    
    # Disable USB autosuspend
    echo "0" > /sys/module/usbcore/parameters/autosuspend 2>/dev/null || true
    
    # Disable runtime power management
    echo "on" > /sys/bus/pci/devices/*/power/control 2>/dev/null || true
    
    echo -e "${GREEN}✓ Power saving disabled${NC}"
}

# Function to create monitoring tools
create_monitoring() {
    echo -e "${BLUE}[8] Creating Performance Monitoring...${NC}"
    
    # Real-time UDP monitor
    cat > /usr/local/bin/udp-monitor << 'MONEOF'
#!/bin/bash

echo "========================================"
echo "    ULTRA UDP PERFORMANCE MONITOR"
echo "    Time: $(date)"
echo "========================================"
echo ""

# System info
echo "=== SYSTEM ==="
echo "Uptime: $(uptime -p)"
echo "Load: $(cat /proc/loadavg)"
echo "CPU: $(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage "%"}')"
echo ""

# UDP Statistics
echo "=== UDP STATISTICS ==="
echo "Packets:"
netstat -su | grep -A 20 "Udp:" | head -30
echo ""

# Interface stats
echo "=== INTERFACE STATISTICS ==="
for IFACE in $(ls /sys/class/net/ | grep -E '^eth|^enp|^ens'); do
    echo "$IFACE:"
    cat /sys/class/net/$IFACE/statistics/rx_packets 2>/dev/null | xargs echo "  RX Packets:"
    cat /sys/class/net/$IFACE/statistics/tx_packets 2>/dev/null | xargs echo "  TX Packets:"
    cat /sys/class/net/$IFACE/statistics/rx_dropped 2>/dev/null | xargs echo "  RX Dropped:"
    cat /sys/class/net/$IFACE/statistics/tx_dropped 2>/dev/null | xargs echo "  TX Dropped:"
    echo ""
done

# Service status
echo "=== SERVICE ==="
systemctl status udp-boost --no-pager | head -15
echo ""

# Buffer info
echo "=== BUFFERS ==="
echo "rmem_max: $(cat /proc/sys/net/core/rmem_max 2>/dev/null)"
echo "wmem_max: $(cat /proc/sys/net/core/wmem_max 2>/dev/null)"
echo "udp_mem: $(cat /proc/sys/net/ipv4/udp_mem 2>/dev/null)"
echo ""

# Connection count
echo "=== CONNECTIONS ==="
ss -u -a | wc -l | xargs echo "Total UDP sockets:"
MONEOF
    
    chmod +x /usr/local/bin/udp-monitor
    
    # Packet loss test script
    cat > /usr/local/bin/udp-speedtest << 'SPEEDEOF'
#!/bin/bash
echo "UDP Speed Test - Sending 10,000 packets"
echo "========================================"
timeout 10 bash -c '
packets_sent=0
for i in {1..10000}; do
    echo -n "X" > /dev/udp/127.0.0.1/36712 2>/dev/null
    packets_sent=$((packets_sent + 1))
done
echo "Packets sent: $packets_sent"
'
echo "Check dropped packets with: netstat -su | grep dropped"
SPEEDEOF
    
    chmod +x /usr/local/bin/udp-speedtest
    
    echo -e "${GREEN}✓ Monitoring tools installed${NC}"
}

# Function to apply IRQ optimizations
optimize_irq() {
    echo -e "${BLUE}[9] Optimizing IRQ Affinity...${NC}"
    
    # Set IRQ affinity to spread across CPUs
    CPU_COUNT=$(nproc)
    
    # Network IRQs
    for IRQ in $(grep -E 'eth|enp|ens' /proc/interrupts | awk '{print $1}' | sed 's/://'); do
        # Round-robin assignment
        CPU=$(( (IRQ % CPU_COUNT) ))
        MASK=$(printf "%x" $((1 << CPU)))
        echo $MASK > /proc/irq/$IRQ/smp_affinity 2>/dev/null || true
    done
    
    # Also set /proc/irq/default_smp_affinity to use all CPUs
    ALL_CPUS_MASK=$(printf "%x" $(( (1 << CPU_COUNT) - 1 )))
    echo $ALL_CPUS_MASK > /proc/irq/default_smp_affinity 2>/dev/null || true
    
    echo -e "${GREEN}✓ IRQ affinity optimized${NC}"
}

# Function to start and verify
start_and_verify() {
    echo -e "${BLUE}[10] Starting Service & Verification...${NC}"
    
    # Start service
    systemctl start udp-boost
    sleep 3
    
    echo -e "${YELLOW}=== Verification ===${NC}"
    
    # Check service
    echo -n "Service status: "
    systemctl is-active udp-boost && echo -e "${GREEN}ACTIVE${NC}" || echo -e "${RED}INACTIVE${NC}"
    
    # Check port
    echo -n "Port 36712: "
    ss -tulpn | grep -q ":36712" && echo -e "${GREEN}LISTENING${NC}" || echo -e "${RED}NOT LISTENING${NC}"
    
    # Check process
    echo -n "Process: "
    pgrep -f "udp-custom" &>/dev/null && echo -e "${GREEN}RUNNING${NC}" || echo -e "${RED}NOT FOUND${NC}"
    
    # Test connection
    echo -n "Local test: "
    timeout 1 nc -zu 127.0.0.1 36712 2>/dev/null && echo -e "${GREEN}PASS${NC}" || echo -e "${RED}FAIL${NC}"
    
    # Show config summary
    echo ""
    echo -e "${YELLOW}=== Configuration Summary ===${NC}"
    echo "Workers: $(grep -o '"workers":[0-9]*' $CONFIG_FILE | cut -d: -f2)"
    echo "Buffer size: $(grep -o '"buffer_size":[0-9]*' $CONFIG_FILE | cut -d: -f2) bytes"
    echo "Max connections: $(grep -o '"max_connections":[0-9]*' $CONFIG_FILE | cut -d: -f2)"
    echo ""
    
    # Show optimization summary
    echo -e "${YELLOW}=== Optimizations Applied ===${NC}"
    echo "✓ 1GB UDP buffers"
    echo "✓ Multi-core processing ($CPU_COUNT cores)"
    echo "✓ NIC hardware offloading"
    echo "✓ Jumbo frames (MTU 9000)"
    echo "✓ CPU performance governor"
    echo "✓ IRQ affinity balancing"
    echo "✓ No power saving"
    echo "✓ Real-time priority"
}

# Main execution
main() {
    check_root
    
    echo -e "${BLUE}Starting ULTRA UDP Optimization...${NC}"
    echo ""
    
    # Run all optimizations
    install_binary
    echo ""
    
    apply_extreme_tuning
    echo ""
    
    optimize_nic
    echo ""
    
    create_ultra_config
    echo ""
    
    fix_systemd_service
    echo ""
    
    optimize_cpu
    echo ""
    
    disable_power_saving
    echo ""
    
    optimize_irq
    echo ""
    
    create_monitoring
    echo ""
    
    start_and_verify
    echo ""
    
    # Final message
    echo "================================================"
    echo -e "${GREEN}   ULTRA UDP OPTIMIZATION COMPLETE!   ${NC}"
    echo "================================================"
    echo ""
    echo -e "${YELLOW}Management Commands:${NC}"
    echo "  systemctl start udp-boost     # Start"
    echo "  systemctl stop udp-boost      # Stop"
    echo "  systemctl status udp-boost    # Status"
    echo "  journalctl -u udp-boost -f    # Live logs"
    echo "  udp-monitor                   # Performance"
    echo "  udp-speedtest                 # Speed test"
    echo ""
    echo -e "${YELLOW}Test UDP Speed:${NC}"
    echo "  udp-speedtest"
    echo "  netstat -su | grep -i drop    # Check drops"
    echo ""
    echo -e "${YELLOW}Config Location:${NC}"
    echo "  $CONFIG_FILE"
    echo ""
    echo -e "${YELLOW}Server Address:${NC}"
    echo "  udp://167.172.43.102:36712"
    echo ""
}

# Run main
main
EOF

# Make it executable
chmod +x ultra-udp-optimizer.sh

# Run the optimizer
./ultra-udp-optimizer.sh
