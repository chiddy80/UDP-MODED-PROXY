#!/bin/bash
# ============================================================
#   PROFESSIONAL UDP BOOST SCRIPT
#   Zero-drop QUIC-grade UDP tunnel for VPS
# ============================================================

set -e

UDP_DIR="/root/udp"
BIN="udp-custom"
BIN_URL="https://raw.githubusercontent.com/chiddy80/UDP-MODED-PROXY/main/udp-custom"
CONF_DIR="/etc/udp"
CONF="$CONF_DIR/config.json"
SERVICE="/etc/systemd/system/udp.service"
PORT=36712

echo "=== UDP BOOST INSTALLER ==="

# Must be root
if [ "$EUID" -ne 0 ]; then
  echo "Run as root"
  exit 1
fi

# Remove broken DNS services
systemctl stop bind9 systemd-resolved 2>/dev/null || true
systemctl disable bind9 systemd-resolved 2>/dev/null || true
apt purge -y bind9 systemd-resolved 2>/dev/null || true

# Install tools
apt update
apt install -y curl wget iproute2 ethtool net-tools ufw jq

# Download binary
mkdir -p $UDP_DIR
cd $UDP_DIR
rm -f $BIN
curl -fsSL "$BIN_URL" -o $BIN
chmod +x $BIN

# Kernel tuning (SAFE + FAST)
cat > /etc/sysctl.d/99-udp.conf << EOF
net.core.rmem_max=67108864
net.core.wmem_max=67108864
net.core.rmem_default=16777216
net.core.wmem_default=16777216
net.ipv4.udp_mem=65536 131072 262144
net.core.netdev_max_backlog=250000
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_low_latency=1
EOF

sysctl --system

# NIC tuning (safe for VPS)
IFACE=$(ip route get 1.1.1.1 | awk '{print $5}')
ethtool -K $IFACE gro on gso on tso on 2>/dev/null || true
ethtool -G $IFACE rx 4096 tx 4096 2>/dev/null || true
ip link set $IFACE mtu 1500

# Create UDP config
mkdir -p $CONF_DIR

cat > $CONF << EOF
{
  "server": {
    "listen": [
      {
        "protocol": "udp",
        "address": "0.0.0.0",
        "port": $PORT,
        "workers": 4,
        "receive_buffer": 33554432,
        "send_buffer": 33554432,
        "timeout": 300
      }
    ]
  },
  "performance": {
    "io_threads": 4,
    "enable_batch_processing": true,
    "batch_size": 64
  },
  "dns": {
    "enable_dns": true,
    "enable_edns": true,
    "edns_buffer_size": 1232,
    "dns_server": "8.8.8.8:53"
  }
}
EOF

# Systemd service (NO sandbox — UDP needs kernel)
cat > $SERVICE << EOF
[Unit]
Description=UDP Custom Proxy
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$UDP_DIR
ExecStart=$UDP_DIR/$BIN server --config $CONF
Restart=always
RestartSec=1
LimitNOFILE=1000000

# No sandboxing
NoNewPrivileges=false
PrivateTmp=false
ProtectSystem=off
ProtectKernelTunables=off

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable udp
systemctl restart udp

# Firewall
ufw allow $PORT/udp
ufw allow 22/tcp
ufw --force enable

echo ""
echo "========================================"
echo " UDP BOOST IS LIVE "
echo "========================================"
echo " Port: $PORT/udp"
echo ""
echo " Commands:"
echo "   systemctl status udp"
echo "   journalctl -u udp -f"
echo "   ss -lunp | grep $PORT"
echo ""
