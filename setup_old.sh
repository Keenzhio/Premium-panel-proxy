#!/bin/bash

# ==========================================
# AUTO INSTALLER FOR PREMIUM PANEL (MULTI-PROTOCOL)
# Supports: VMess, VLess, Trojan, Socks5, HTTP
# ==========================================

# Warna
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${BLUE}[1/5] Updating System & Installing Dependencies...${NC}"
apt update && apt upgrade -y
apt install -y redis-server jq curl uuid-runtime unzip socat git

echo -e "${BLUE}[2/5] Installing Xray Core (Latest)...${NC}"
# Install Xray Official
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

echo -e "${BLUE}[3/5] Configuring Xray JSON (Multi-Protocol)...${NC}"
# Membuat config.json yang kompatibel dengan Logic Panel.sh
# Port Default: VMess=8080, VLess=2082, Trojan=2087, Socks=1080, HTTP=8081
cat > /etc/xray/config.json << ENDOFFILE
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "tag": "vmess",
      "port": 8080,
      "protocol": "vmess",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vmess"
        }
      }
    },
    {
      "tag": "vless",
      "port": 2082,
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vless"
        }
      }
    },
    {
      "tag": "trojan",
      "port": 2087,
      "protocol": "trojan",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "tcp",
        "security": "none"
      }
    },
    {
      "tag": "socks",
      "port": 1080,
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "udp": true
      }
    },
    {
      "tag": "http",
      "port": 8081,
      "protocol": "http",
      "settings": {}
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "tag": "blocked",
      "settings": {}
    }
  ]
}
ENDOFFILE

echo -e "${BLUE}[4/5] Preparing Database & Environment...${NC}"
# Enable Services
systemctl enable redis-server
systemctl restart redis-server
systemctl enable xray
systemctl restart xray

# Buat dummy menu command
touch /usr/bin/menu
chmod +x /usr/bin/menu

echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}       INSTALLATION COMPLETED!               ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo -e "Langkah Selanjutnya:"
echo -e "1. Edit file menu: nano /usr/bin/menu"
echo -e "2. Paste kode 'panel.sh' ke dalamnya."
echo -e "3. Simpan & Exit."
echo -e "4. Ketik 'menu' untuk masuk ke dashboard."
