#!/bin/bash

# ==========================================
#  AUTO INSTALLER PREMIUM PANEL (FINAL)
#  - Auto Install Xray & Redis
#  - Auto Config Domain & Database
#  - Auto Download Panel Menu
# ==========================================

# --- KONFIGURASI SUMBER FILE (ISI DENGAN LINK GITHUB KAMU) ---
# Pastikan link ini mengarah ke file panel.sh versi "RAW"
# Contoh: https://raw.githubusercontent.com/username/repo/main/panel.sh
LINK_PANEL_SH="https://raw.githubusercontent.com/Keenzhio/Premium-panel-proxy/main/panel.sh"

# Warna
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${BLUE}=====================================================${NC}"
echo -e "           INSTALLER SCRIPT PREMIUM V3.0             "
echo -e "${BLUE}=====================================================${NC}"
echo ""

# 1. INPUT DOMAIN DI AWAL
echo -e "${GREEN}[1/6] Konfigurasi Awal...${NC}"
read -p "Masukkan Domain/Subdomain VPS (contoh: sg.vip.com): " domain_input
if [[ -z "$domain_input" ]]; then
    echo -e "${RED}Domain tidak boleh kosong!${NC}"
    exit 1
fi

# 2. UPDATE & INSTALL DEPENDENCIES
echo -e "${GREEN}[2/6] Mengupdate System & Install Tools...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt update && apt upgrade -y
apt install -y redis-server jq curl uuid-runtime unzip socat git nano net-tools

# Set Timezone ke WIB (Jakarta) agar expired date akurat
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# 3. INSTALL XRAY CORE
echo -e "${GREEN}[3/6] Menginstall Xray Core Terbaru...${NC}"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# 4. KONFIGURASI DATABASE (REDIS)
echo -e "${GREEN}[4/6] Menyimpan Konfigurasi ke Database...${NC}"
systemctl enable --now redis-server
# Simpan Domain ke Redis agar terbaca oleh Panel.sh
redis-cli HSET "system:config" "domain" "$domain_input"
# Simpan Port Default
redis-cli HSET "system:config" "socks_port" "1080"
redis-cli HSET "system:config" "http_port" "8081"
redis-cli HSET "system:config" "port_vmess" "8080"
redis-cli HSET "system:config" "port_vless" "2082"
redis-cli HSET "system:config" "port_trojan" "2087"

# 5. BUAT CONFIG XRAY JSON
echo -e "${GREEN}[5/6] Membuat Config Xray Multi-Protocol...${NC}"
cat > /etc/xray/config.json << ENDOFFILE
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "tag": "vmess",
      "port": 8080,
      "protocol": "vmess",
      "settings": { "clients": [] },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "/vmess" } }
    },
    {
      "tag": "vless",
      "port": 2082,
      "protocol": "vless",
      "settings": { "clients": [], "decryption": "none" },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "/vless" } }
    },
    {
      "tag": "trojan",
      "port": 2087,
      "protocol": "trojan",
      "settings": { "clients": [] },
      "streamSettings": { "network": "tcp", "security": "none" }
    },
    {
      "tag": "socks",
      "port": 1080,
      "protocol": "socks",
      "settings": { "auth": "noauth", "udp": true }
    },
    {
      "tag": "http",
      "port": 8081,
      "protocol": "http",
      "settings": {}
    }
  ],
  "outbounds": [
    { "protocol": "freedom", "settings": {} },
    { "protocol": "blackhole", "tag": "blocked", "settings": {} }
  ]
}
ENDOFFILE

# 6. DOWNLOAD & PASANG PANEL MENU
echo -e "${GREEN}[6/6] Mendownload Panel Menu...${NC}"

# Cek apakah user sudah mengganti link github di atas
if [[ "$LINK_PANEL_SH" == *"username/repo"* ]]; then
    echo -e "${RED}[WARNING] Link GitHub belum diganti!${NC}"
    echo "Membuat file menu kosong. Silahkan paste manual nanti."
    touch /usr/bin/menu
else
    # Download file panel.sh dan simpan sebagai 'menu' di /usr/bin
    wget -qO /usr/bin/menu "$LINK_PANEL_SH"
fi

# Berikan izin eksekusi
chmod +x /usr/bin/menu

# Restart Semua Service
systemctl restart redis-server
systemctl restart xray

echo -e "${BLUE}=============================================${NC}"
echo -e "${GREEN}       INSTALLATION SUCCEEDED!               ${NC}"
echo -e "${BLUE}=============================================${NC}"
echo -e " Domain    : $domain_input"
echo -e " Database  : Redis (Active)"
echo -e " Xray Core : Installed"
echo -e ""
echo -e " Cara menggunakan:"
echo -e " Ketik perintah: ${GREEN}menu${NC}"
