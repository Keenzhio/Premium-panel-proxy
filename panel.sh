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
DB_HOST="127.0.0.1"
DB_PORT="6379"

# Lokasi Config (Sesuaikan path asli)
XRAY_CONFIG="/etc/xray/config.json"

# --- FUNGSI DATABASE (CRUD REDIS) ---

cek_redis() {
    if ! redis-cli -h $DB_HOST -p $DB_PORT ping | grep -q "PONG"; then
        echo -e "${RED}[ERROR] Redis Database tidak berjalan!${NC}"
        echo -e "Silahkan install: apt install redis-server"
        exit 1
    fi
}

# --- DATABASE WRAPPER UNTUK SETTING ---
db_set_config() {
    local key=$1
    local value=$2
    redis-cli -h $DB_HOST -p $DB_PORT HSET "system:config" "$key" "$value" > /dev/null
}

db_get_config() {
    local key=$1
    local default=$2
    local val=$(redis-cli -h $DB_HOST -p $DB_PORT HGET "system:config" "$key")
    if [[ -z "$val" ]]; then
        echo "$default"
    else
        echo "$val"
    fi
}

# --- FUNGSI VMESS ---
db_add_vmess() {
    local user=$1
    local uuid=$2
    local exp=$3
    redis-cli -h $DB_HOST -p $DB_PORT HSET "vmess:$user" uuid "$uuid" exp "$exp" > /dev/null
    redis-cli -h $DB_HOST -p $DB_PORT SADD "users:vmess" "$user" > /dev/null
}

db_list_vmess() {
    redis-cli -h $DB_HOST -p $DB_PORT SMEMBERS "users:vmess"
}

add_vmess() {
    # Ambil Domain dari Redis agar sinkron
    CURRENT_DOMAIN=$(db_get_config "domain" "sg.domainkamu.com")
    
    clear
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "           TAMBAH PENGGUNA VMESS"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -p "Username : " user
    if redis-cli -h $DB_HOST -p $DB_PORT EXISTS "vmess:$user" | grep -q "1"; then
        echo -e "${RED}[ERROR] User $user sudah ada!${NC}"; sleep 2; return
    fi
    read -p "Expired (hari) : " masaaktif
    uuid=$(uuidgen)
    exp=$(date -d "+${masaaktif} days" +"%Y-%m-%d")
    
    echo -e "${YELLOW}[DB] Menyimpan ke Redis...${NC}"
    db_add_vmess "$user" "$uuid" "$exp"
    
    clear
    echo -e "BERHASIL DITAMBAHKAN!"
    echo -e "Remarks : ${user}"
    echo -e "Domain  : ${CURRENT_DOMAIN}"
    echo -e "UUID    : ${uuid}"
    read -n 1 -s -r -p "Tekan tombol untuk kembali..."
}

list_vmess() {
    clear
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "           LIST USER VMESS (REDIS)"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    printf "%-15s | %-15s\n" "USER" "EXP"
    echo "-------------------------------------"
    for user in $(db_list_vmess); do
        exp=$(redis-cli -h $DB_HOST -p $DB_PORT HGET "vmess:$user" exp)
        printf "%-15s | %s\n" "$user" "$exp"
    done
    read -n 1 -s -r -p "Tekan tombol untuk kembali..."
}

# --- [UPDATE] FUNGSI HOST & PROXY MANAGER ---
# Ini menggabungkan setting Subdomain dan Port dalam satu menu
host_proxy_menu() {
    while true; do
        # Ambil config dari Redis (Real-time)
        # Jika belum ada di database, gunakan default value
        cur_domain=$(db_get_config "domain" "sg.default.com")
        socks_port=$(db_get_config "socks_port" "1080")
        http_port=$(db_get_config "http_port" "8080")

        clear
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "           HOST & PROXY CONFIGURATION"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e ""
        echo -e "  [1] Set Host/Subdomain : ${GREEN}$cur_domain${NC}"
        echo -e "  [2] Set SOCKS5 Port    : ${GREEN}$socks_port${NC}"
        echo -e "  [3] Set HTTP Port      : ${GREEN}$http_port${NC}"
        echo -e "  -------------------------"
        echo -e "  [4] Simpan & Terapkan (Restart)"
        echo -e "  [0] Kembali"
        echo -e ""
        read -p "  Pilih >>> " hp_opt

        case $hp_opt in
            1)
                read -p "Masukkan Subdomain Baru (misal: vip.myserver.com): " new_dom
                if [[ ! -z "$new_dom" ]]; then
                    db_set_config "domain" "$new_dom"
                    echo -e "${GREEN}Subdomain disimpan ke Redis.${NC}"
                fi
                sleep 1
                ;;
            2)
                read -p "Masukkan Port SOCKS5 Baru: " new_socks
                if [[ $new_socks =~ ^[0-9]+$ ]]; then
                    db_set_config "socks_port" "$new_socks"
                    echo -e "${GREEN}Port SOCKS5 disimpan.${NC}"
                else
                    echo -e "${RED}Port harus angka!${NC}"
                fi
                sleep 1
                ;;
            3)
                read -p "Masukkan Port HTTP Baru: " new_http
                if [[ $new_http =~ ^[0-9]+$ ]]; then
                    db_set_config "http_port" "$new_http"
                    echo -e "${GREEN}Port HTTP disimpan.${NC}"
                else
                    echo -e "${RED}Port harus angka!${NC}"
                fi
                sleep 1
                ;;
            4)
                echo -e "${YELLOW}Mengupdate konfigurasi sistem...${NC}"
                # Di sini logika untuk mengubah file asli Xray/Nginx
                # Contoh: Mengganti domain di sertifikat atau config json
                
                # Simulasi update berhasil
                echo -e "${GREEN}Sukses! Menggunakan Host: $cur_domain${NC}"
                echo -e "${GREEN}SOCKS5: $socks_port | HTTP: $http_port${NC}"
                sleep 2
                ;;
            0) break ;;
            *) echo "Menu salah"; sleep 1 ;;
        esac
    done
}

# --- TAMPILAN UTAMA (MENU) ---
show_menu() {
    IPVPS=$(curl -s ifconfig.me)
    RAM_US=$(free -m | grep Mem | awk '{print $3}')
    RAM_TOT=$(free -m | grep Mem | awk '{print $2}')
    DB_STATUS=$(redis-cli ping)
    
    # Domain juga ditampilkan di halaman depan
    MAIN_DOMAIN=$(db_get_config "domain" "Belum Diset")

    clear
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}        PREMIUM PANEL - REDIS EDITION ${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    echo -e "  ${RED}●${NC} IP VPS       = $IPVPS"
    echo -e "  ${RED}●${NC} DOMAIN       = ${GREEN}$MAIN_DOMAIN${NC}"
    echo -e "  ${RED}●${NC} RAM          = $RAM_US / $RAM_TOT MB"
    echo -e "  ${RED}●${NC} DATABASE     = ${GREEN}REDIS ($DB_STATUS)${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  [01] BUAT AKUN VMESS"
    echo -e "  [02] LIST AKUN VMESS"
    echo -e "  [03] HAPUS AKUN VMESS"
    echo -e "  [04] RESTART SERVICE"
    echo -e "  -------------------------"
    echo -e "  [05] HOST & PROXY SETTINGS ${YELLOW}[NEW]${NC}"
    echo -e "  -------------------------"
    echo -e "  [00] KELUAR"
    echo -e ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -p " Select Option >>> " opt
    
    case $opt in
        1) add_vmess ;;
        2) list_vmess ;;
        3) echo "Fitur hapus (coming soon)" ; sleep 2 ;;
        4) echo "Restarting Service..." ; sleep 1 ;;
        5) host_proxy_menu ;;
        0) exit 0 ;;
        *) echo "Menu tidak tersedia"; sleep 1 ;;
    esac
}

# --- MAIN LOOP ---
cek_redis
while true; do
    show_menu
done
