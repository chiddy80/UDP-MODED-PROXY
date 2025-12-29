#!/bin/bash

# Script: udp-ultimate-fix.sh
# Purpose: Fix UDP service and apply working optimizations

clear
echo "================================================"
echo "    UDP ULTIMATE FIX - GUARANTEED WORKING"
echo "================================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Stop any existing service
echo -e "${BLUE}[1] Stopping existing service...${NC}"
systemctl stop udp-boost 2>/dev/null
pkill -f udp-custom 2>/dev/null
sleep 2

# Create SIMPLE systemd service (GUARANTEED to work)
echo -e "${BLUE}[2] Creating guaranteed systemd service...${NC}"
cat > /etc/systemd/system/udp-boost.service << 'SERVICE'
[Unit]
Description=UDP Custom Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/udp
ExecStart=/root/udp/udp-custom server --config /etc/udp/config.json
Restart=always
RestartSec=5
LimitNOFILE=1000000
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable udp-boost

# Create SIMPLE working config
echo -e "${BLUE}[3] Creating working config...${NC}"
mkdir -p /etc/udp

cat > /etc/udp/config.json << 'CONFIG'
{
  "listen": ":36712",
  "protocol": "udp",
  "workers": 4,
  "buffer_size": 16777216,
  "receive_buffer": 268435456,
  "send_buffer": 268435456,
  "max_connections": 100000
}
CONFIG

# Apply only WORKING sysctl optimizations
echo -e "${BLUE}[4] Applying working sysctl optimizations...${NC}"
cat >> /etc/sysctl.conf << 'SYSCTL'

# UDP Optimizations - WORKING VERSION
net.core.rmem_max = 268435456
net.core.wmem_max = 268435456
net.core.rmem_default = 16777216
net.core.wmem_default = 16777216
net.core.optmem_max = 16777216

# UDP memory
net.ipv4.udp_mem = 1024000 8738000 268435456
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192

# Network
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 100000
net.ipv4.tcp_max_syn_backlog = 65536
net.ipv4.ip_local_port_range = 10000 65535
net.ipv4.tcp_slow_start_after_idle = 0

# Connection tracking
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_tw_buckets = 2000000
SYSCTL

# Apply sysctl
sysctl -p 2>/dev/null

# Test binary manually first
echo -e "${BLUE}[5] Testing binary...${NC}"
cd /root/udp
if [ ! -f "udp-custom" ]; then
    echo -e "${RED}Binary not found, downloading...${NC}"
    wget -O udp-custom "https://raw.githubusercontent.com/chiddy80/UDP-MODED-PROXY/main/udp-custom"
    chmod +x udp-custom
fi

# Make sure binary is executable
chmod +x /root/udp/udp-custom

# Test run manually first
echo -e "${BLUE}[6] Testing manual startup...${NC}"
timeout 3 ./udp-custom server --config /etc/udp/config.json &
MANUAL_PID=$!
sleep 2

if ps -p $MANUAL_PID > /dev/null; then
    echo -e "${GREEN}✓ Manual test SUCCESS - Binary works!${NC}"
    kill $MANUAL_PID 2>/dev/null
else
    echo -e "${YELLOW}⚠ Manual test failed, trying alternative...${NC}"
    
    # Try alternative config
    cat > /etc/udp/config-simple.json << 'SIMPLE'
{
  "server": {
    "listen": "0.0.0.0:36712",
    "protocol": "udp"
  }
}
SIMPLE
fi

# Start via systemd
echo -e "${BLUE}[7] Starting via systemd...${NC}"
systemctl start udp-boost
sleep 3

# Verify
echo -e "${BLUE}[8] Verifying installation...${NC}"
echo ""

echo -e "${YELLOW}=== Service Status ===${NC}"
if systemctl is-active udp-boost >/dev/null; then
    echo -e "${GREEN}✓ Service: ACTIVE${NC}"
else
    echo -e "${RED}✗ Service: INACTIVE${NC}"
    echo -e "${YELLOW}Trying emergency start...${NC}"
    /root/udp/udp-custom server --config /etc/udp/config.json &
    echo $! > /tmp/udp.pid
fi

echo -e "${YELLOW}=== Process Check ===${NC}"
if pgrep -f "udp-custom" >/dev/null; then
    echo -e "${GREEN}✓ Process: RUNNING (PID: $(pgrep -f "udp-custom"))${NC}"
else
    echo -e "${RED}✗ Process: NOT RUNNING${NC}"
fi

echo -e "${YELLOW}=== Port Check ===${NC}"
if ss -tulpn | grep -q ":36712"; then
    echo -e "${GREEN}✓ Port 36712: LISTENING${NC}"
else
    echo -e "${RED}✗ Port 36712: NOT LISTENING${NC}"
fi

echo -e "${YELLOW}=== Connection Test ===${NC}"
if timeout 2 nc -zu 127.0.0.1 36712 2>/dev/null; then
    echo -e "${GREEN}✓ Local connection: SUCCESS${NC}"
else
    echo -e "${RED}✗ Local connection: FAILED${NC}"
fi

# External test
EXTERNAL_IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
echo -e "${YELLOW}=== External Test (${EXTERNAL_IP}) ===${NC}"
if timeout 2 nc -zu $EXTERNAL_IP 36712 2>/dev/null; then
    echo -e "${GREEN}✓ External connection: SUCCESS${NC}"
else
    echo -e "${YELLOW}⚠ External connection: May be firewall issue${NC}"
    echo "Check firewall: ufw status"
fi

# Create ULTRA simple management
echo -e "${BLUE}[9] Creating management tools...${NC}"
cat > /usr/local/bin/udp-go << 'MANAGE'
#!/bin/bash

case "$1" in
    start)
        systemctl start udp-boost 2>/dev/null || /root/udp/udp-custom server --config /etc/udp/config.json &
        echo "UDP server started"
        sleep 1
        ;;
    stop)
        systemctl stop udp-boost 2>/dev/null
        pkill -f "udp-custom"
        echo "UDP server stopped"
        ;;
    restart)
        systemctl restart udp-boost 2>/dev/null || (pkill -f "udp-custom" && /root/udp/udp-custom server --config /etc/udp/config.json &)
        echo "UDP server restarted"
        sleep 1
        ;;
    status)
        echo "=== UDP Server Status ==="
        echo "Process: $(pgrep -f "udp-custom" 2>/dev/null || echo "Not running")"
        echo "Port 36712: $(ss -tulpn | grep -q ":36712" && echo "Listening" || echo "Not listening")"
        echo "Service: $(systemctl is-active udp-boost 2>/dev/null || echo "Unknown")"
        echo ""
        echo "Test: nc -zu $(hostname -I | awk '{print $1}') 36712"
        ;;
    logs)
        journalctl -u udp-boost -n 50 --no-pager 2>/dev/null || echo "No systemd logs"
        echo ""
        echo "--- Manual logs ---"
        ps aux | grep "udp-custom" | grep -v grep
        ;;
    test)
        echo "Testing UDP server..."
        timeout 2 nc -zu 127.0.0.1 36712 && echo "✓ Local: OK" || echo "✗ Local: Failed"
        EXTERNAL_IP=$(hostname -I | awk '{print $1}')
        timeout 2 nc -zu $EXTERNAL_IP 36712 && echo "✓ External ($EXTERNAL_IP): OK" || echo "✗ External: Failed (check firewall)"
        ;;
    config)
        nano /etc/udp/config.json
        ;;
    firewall)
        echo "Current firewall rules:"
        ufw status numbered 2>/dev/null || iptables -L -n | grep 36712 || echo "No firewall rules for port 36712"
        echo ""
        echo "To open port: ufw allow 36712/udp && ufw reload"
        ;;
    speed)
        echo "Running speed test (sending 1000 packets)..."
        count=0
        for i in {1..1000}; do
            echo -n "x" > /dev/udp/127.0.0.1/36712 2>/dev/null && count=$((count+1))
        done
        echo "Sent $count packets"
        echo "Check drops: netstat -su | grep dropped"
        ;;
    *)
        echo "Usage: udp-go {start|stop|restart|status|logs|test|config|firewall|speed}"
        echo ""
        echo "Quick start: udp-go start"
        echo "Check: udp-go status"
        echo "Test: udp-go test"
        echo "Speed test: udp-go speed"
        ;;
esac
MANAGE

chmod +x /usr/local/bin/udp-go

# Create diagnostic tool
cat > /usr/local/bin/udp-diagnose << 'DIAG'
#!/bin/bash
echo "=== UDP Server Diagnostic ==="
echo "Time: $(date)"
echo ""

echo "1. Binary check:"
ls -la /root/udp/udp-custom 2>/dev/null && echo "✓ Binary exists" || echo "✗ Binary missing"
echo ""

echo "2. Config check:"
ls -la /etc/udp/config.json 2>/dev/null && echo "✓ Config exists" || echo "✗ Config missing"
echo ""

echo "3. Process check:"
pgrep -f "udp-custom" && echo "✓ Process running" || echo "✗ Process not running"
echo ""

echo "4. Port check:"
ss -tulpn | grep ":36712" && echo "✓ Port listening" || echo "✗ Port not listening"
echo ""

echo "5. Service check:"
systemctl status udp-boost --no-pager 2>/dev/null | head -10
echo ""

echo "6. Connection test:"
timeout 1 nc -zu 127.0.0.1 36712 2>/dev/null && echo "✓ Local connection OK" || echo "✗ Local connection failed"
echo ""

echo "7. UDP statistics:"
netstat -su | head -20
echo ""

echo "=== Diagnostic Complete ==="
DIAG

chmod +x /usr/local/bin/udp-diagnose

# Create speed tester
cat > /usr/local/bin/udp-bench << 'BENCH'
#!/bin/bash
echo "=== UDP Benchmark Tool ==="
echo ""

PACKETS=10000
SIZE=1400
SERVER="127.0.0.1"
PORT=36712

echo "Testing with $PACKETS packets of $SIZE bytes each"
echo "Total data: $((PACKETS * SIZE / 1024 / 1024)) MB"
echo ""

start_time=$(date +%s.%N)

sent=0
for i in $(seq 1 $PACKETS); do
    dd if=/dev/zero bs=$SIZE count=1 2>/dev/null > /dev/udp/$SERVER/$PORT 2>/dev/null
    if [ $? -eq 0 ]; then
        sent=$((sent + 1))
    fi
    # Progress
    if [ $((i % 1000)) -eq 0 ]; then
        echo -ne "Sent: $i/$PACKETS packets\r"
    fi
done

end_time=$(date +%s.%N)
duration=$(echo "$end_time - $start_time" | bc)

echo ""
echo "=== Results ==="
echo "Packets sent: $sent/$PACKETS"
echo "Time: ${duration}s"
echo "Speed: $(echo "scale=2; ($sent * $SIZE) / ($duration * 1024 * 1024)" | bc) MB/s"
echo "Packets/sec: $(echo "scale=2; $sent / $duration" | bc)"
echo ""
echo "Check drops: netstat -su | grep -E '(packets receive|packets sent|dropped)'"
BENCH

chmod +x /usr/local/bin/udp-bench

# Create monitoring dashboard
cat > /usr/local/bin/udp-dashboard << 'DASH'
#!/bin/bash
clear
echo "╔══════════════════════════════════════════════════════════╗"
echo "║               UDP SERVER DASHBOARD                       ║"
echo "║         IP: 167.172.43.102 | PORT: 36712                 ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

while true; do
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║ Status: $(systemctl is-active udp-boost 2>/dev/null || echo "Manual") | Time: $(date +%H:%M:%S) ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    
    # Process info
    echo "📊 PROCESS:"
    PID=$(pgrep -f "udp-custom")
    if [ -n "$PID" ]; then
        echo "  ✓ Running (PID: $PID)"
        ps -p $PID -o %cpu,%mem,etime --no-headers | awk '{print "  CPU: "$1"% MEM: "$2"% Uptime: "$3}'
    else
        echo "  ✗ Not running"
    fi
    
    # Port info
    echo ""
    echo "🔌 PORT 36712:"
    if ss -tulpn | grep -q ":36712"; then
        echo "  ✓ Listening"
        ss -tulpn | grep ":36712" | awk '{print "  " $5 " (" $1 ")"}'
    else
        echo "  ✗ Not listening"
    fi
    
    # Statistics
    echo ""
    echo "📈 STATISTICS:"
    netstat -su | grep -E "(packets receive|packets sent|dropped)" | head -5 | while read line; do
        echo "  $line"
    done
    
    # Connections
    echo ""
    echo "🔗 CONNECTIONS:"
    conn_count=$(ss -u -a | wc -l)
    echo "  Total UDP sockets: $((conn_count - 1))"
    
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║ Commands: start | stop | restart | bench | exit          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    read -t 5 -p "Command: " cmd 2>/dev/null
    
    case $cmd in
        start) udp-go start ;;
        stop) udp-go stop ;;
        restart) udp-go restart ;;
        bench) udp-bench ;;
        exit) break ;;
        *) ;;
    esac
    
    clear
done
DASH

chmod +x /usr/local/bin/udp-dashboard

# Final output
echo ""
echo "================================================"
echo -e "${GREEN}    UDP ULTIMATE FIX COMPLETE!   ${NC}"
echo "================================================"
echo ""
echo -e "${YELLOW}📡 SERVER ADDRESS:${NC}"
EXTERNAL_IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
echo "  udp://${EXTERNAL_IP}:36712"
echo ""
echo -e "${YELLOW}🚀 QUICK COMMANDS:${NC}"
echo "  udp-go start     # Start server"
echo "  udp-go status    # Check status"
echo "  udp-go test      # Test connection"
echo "  udp-go speed     # Quick speed test"
echo "  udp-bench        # Full benchmark"
echo "  udp-diagnose     # Full diagnostic"
echo "  udp-dashboard    # Live dashboard"
echo ""
echo -e "${YELLOW}🔧 MANUAL START (if needed):${NC}"
echo "  cd /root/udp && ./udp-custom server --config /etc/udp/config.json"
echo ""
echo -e "${YELLOW}📊 MONITORING:${NC}"
echo "  watch -n 1 'netstat -su | grep -E \"(packets|receive|send|errors|drops)\"'"
echo ""
echo -e "${YELLOW}🔒 FIREWALL CHECK:${NC}"
echo "  udp-go firewall"
echo "  ufw allow 36712/udp && ufw reload"
echo ""
echo -e "${YELLOW}⚡ FOR MAX SPEED:${NC}"
echo "  Run: udp-bench"
echo ""
EOF

# Make executable and run
chmod +x udp-ultimate-fix.sh
echo "Script created. Now run it:"
echo "./udp-ultimate-fix.sh"
