#!/bin/bash

# ==========================================================
#  PREMIUM SCRIPT: BASH + REDIS (NoSQL) + XRAY LOGIC
#  Created for Ubuntu 22.04 LTS
# ==========================================================

# --- WARNA (ANSI COLORS) ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

# --- KONFIGURASI DATABASE (REDIS) ---
# Kita menggunakan 'redis-cli' untuk berkomunikasi dengan DB
DB_HOST="127.0.0.1"
DB_PORT="6379"

# Lokasi Config Xray (Sesuaikan jika path berbeda)
XRAY_CONFIG="/etc/xray/config.json"
DOMAIN="sg.domainkamu.com" # Ganti dengan domain aslimu

# --- FUNGSI DATABASE (CRUD REDIS) ---

cek_redis() {
    if ! redis-cli -h $DB_HOST -p $DB_PORT ping | grep -q "PONG"; then
        echo -e "${RED}[ERROR] Redis Database tidak berjalan!${NC}"
        echo -e "Silahkan install: apt install redis-server"
        exit 1
    fi
}

# Menyimpan User ke Redis (Key: vmess:username)
# Struktur Data di Redis Hash: 
# vmess:<user> -> field: uuid, exp, quota
db_add_vmess() {
    local user=$1
    local uuid=$2
    local exp=$3
    
    redis-cli -h $DB_HOST -p $DB_PORT HSET "vmess:$user" uuid "$uuid" exp "$exp" > /dev/null
    redis-cli -h $DB_HOST -p $DB_PORT SADD "users:vmess" "$user" > /dev/null
}

# Mengambil List User dari Redis
db_list_vmess() {
    redis-cli -h $DB_HOST -p $DB_PORT SMEMBERS "users:vmess"
}

# --- FUNGSI UTAMA VMESS ---

add_vmess() {
    clear
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "           TAMBAH PENGGUNA VMESS (DATABASE REDIS)   "
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    read -p "Username : " user
    
    # Cek apakah user sudah ada di Redis
    if redis-cli -h $DB_HOST -p $DB_PORT EXISTS "vmess:$user" | grep -q "1"; then
        echo -e "${RED}[ERROR] User $user sudah ada di database!${NC}"
        read -n 1 -s -r -p "Tekan sembarang tombol untuk kembali..."
        return
    fi

    read -p "Expired (hari) : " masaaktif
    
    # Logic
    uuid=$(uuidgen)
    exp=$(date -d "+${masaaktif} days" +"%Y-%m-%d")
    
    # 1. Simpan ke Database NoSQL (Redis)
    echo -e "${YELLOW}[DB] Menyimpan data ke Redis...${NC}"
    db_add_vmess "$user" "$uuid" "$exp"
    
    # 2. Update Config Xray (Simulasi manipulasi JSON)
    # Di script production, ini akan menggunakan 'jq' untuk inject ke config.json
    echo -e "${YELLOW}[CFG] Sinkronisasi Database ke Xray Config...${NC}"
    # Contoh command manipulasi file asli (dikomentari agar aman saat testing):
    # jq --arg u "$user" --arg id "$uuid" '.inbounds[0].settings.clients += [{"id": $id, "email": $u}]' $XRAY_CONFIG > /tmp/conf && mv /tmp/conf $XRAY_CONFIG
    
    # 3. Restart Service
    # systemctl restart xray
    
    clear
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "           VMESS ACCOUNT DETAILS"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e " Remarks   : ${user}"
    echo -e " Domain    : ${DOMAIN}"
    echo -e " UUID      : ${uuid}"
    echo -e " AlterId   : 0"
    echo -e " Security  : auto"
    echo -e " Expired   : ${exp}"
    echo -e " Database  : ${GREEN}Redis (NoSQL)${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    read -n 1 -s -r -p "Tekan sembarang tombol untuk kembali..."
}

list_vmess() {
    clear
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "           LIST USER VMESS (DARI REDIS)"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "USER             | UUID                                 | EXP"
    echo -e "--------------------------------------------------------"
    
    # Loop data dari Redis
    for user in $(db_list_vmess); do
        uuid=$(redis-cli -h $DB_HOST -p $DB_PORT HGET "vmess:$user" uuid)
        exp=$(redis-cli -h $DB_HOST -p $DB_PORT HGET "vmess:$user" exp)
        printf "%-16s | %-36s | %s\n" "$user" "$uuid" "$exp"
    done
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -n 1 -s -r -p "Tekan sembarang tombol untuk kembali..."
}

# --- TAMPILAN UTAMA (MENU) ---
show_menu() {
    # Ambil Data System
    IPVPS=$(curl -s ifconfig.me)
    RAM_US=$(free -m | grep Mem | awk '{print $3}')
    RAM_TOT=$(free -m | grep Mem | awk '{print $2}')
    DB_STATUS=$(redis-cli ping) # PONG artinya connect

    clear
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}        PREMIUM PANEL - REDIS EDITION ${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    echo -e "  ${RED}●${NC} IP VPS       = $IPVPS"
    echo -e "  ${RED}●${NC} RAM          = $RAM_US / $RAM_TOT MB"
    echo -e "  ${RED}●${NC} DATABASE     = ${GREEN}REDIS ($DB_STATUS)${NC}"
    echo -e "  ${RED}●${NC} DOMAIN       = $DOMAIN"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  [01] BUAT AKUN VMESS (Add User)"
    echo -e "  [02] LIST AKUN VMESS (Cek DB)"
    echo -e "  [03] HAPUS AKUN VMESS"
    echo -e "  [04] RESTART SERVICE"
    echo -e "  [00] KELUAR"
    echo -e ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -p " Select Option >>> " opt
    
    case $opt in
        1) add_vmess ;;
        2) list_vmess ;;
        3) echo "Fitur hapus bisa ditambahkan dengan logika DEL key Redis" ; sleep 2 ;;
        4) echo "Restarting Xray..." ; sleep 1 ;;
        0) exit 0 ;;
        *) echo "Menu tidak tersedia"; sleep 1 ;;
    esac
}

# --- MAIN LOOP ---
cek_redis
while true; do
    show_menu
done
