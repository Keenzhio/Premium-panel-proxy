#!/bin/bash

# ==========================================================
#  PREMIUM SCRIPT: ALL PROTOCOL (VMESS/VLESS/TROJAN)
#  Created for Ubuntu 22.04 LTS
# ==========================================================

# --- WARNA (ANSI COLORS) ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

# --- KONFIGURASI SYSTEM ---
DB_HOST="127.0.0.1"
DB_PORT="6379"
XRAY_CONFIG="/etc/xray/config.json"

# --- FUNGSI HELPER & DATABASE ---
cek_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Harap jalankan script sebagai ROOT!${NC}"
        exit 1
    fi
}

# Wrapper Redis untuk Config Global (Domain, Port)
db_set_config() {
    redis-cli -h $DB_HOST -p $DB_PORT HSET "system:config" "$1" "$2" > /dev/null
}

db_get_config() {
    local val=$(redis-cli -h $DB_HOST -p $DB_PORT HGET "system:config" "$1")
    echo "${val:-$2}" # Return default value ($2) jika kosong
}

# --- 1. VMESS MANAGER ---
vmess_menu() {
    clear
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "                 VMESS MANAGER"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e " [1] Buat Akun VMess"
    echo -e " [2] Hapus Akun VMess"
    echo -e " [3] Cek User Login"
    echo -e " [0] Kembali"
    echo -e ""
    read -p " Select >>> " v_opt
    case $v_opt in
        1)
            read -p "Username : " user
            if redis-cli -h $DB_HOST -p $DB_PORT SISMEMBER "users:vmess" "$user" | grep -q "1"; then
                echo -e "${RED}User sudah ada!${NC}"; sleep 1; return
            fi
            read -p "Expired (hari) : " masaaktif
            uuid=$(uuidgen)
            exp=$(date -d "+${masaaktif} days" +"%Y-%m-%d")
            
            # Simpan DB
            redis-cli -h $DB_HOST -p $DB_PORT HSET "vmess:$user" uuid "$uuid" exp "$exp" > /dev/null
            redis-cli -h $DB_HOST -p $DB_PORT SADD "users:vmess" "$user" > /dev/null
            
            # Inject Config (Tag: vmess)
            jq --arg u "$user" --arg id "$uuid" \
               '.inbounds[] | select(.tag=="vmess").settings.clients += [{"id": $id, "email": $u, "alterId": 0}]' \
               $XRAY_CONFIG > /tmp/x && mv /tmp/x $XRAY_CONFIG
            
            systemctl restart xray
            echo -e "${GREEN}Sukses! VMess $user dibuat.${NC}"; sleep 2
            ;;
        2)
            echo "List User VMess:"; 
            redis-cli -h $DB_HOST -p $DB_PORT SMEMBERS "users:vmess"
            read -p "Masukkan Username yg dihapus: " deluser
            # Hapus dari DB & Config (Logic simplified)
            redis-cli -h $DB_HOST -p $DB_PORT DEL "vmess:$deluser"
            redis-cli -h $DB_HOST -p $DB_PORT SREM "users:vmess" "$deluser"
            # Hapus dari JSON perlu logic jq del(...)
            echo -e "${YELLOW}User $deluser dihapus dari DB.${NC}"; sleep 1
            ;;
        0) return ;;
    esac
}

# --- 2. VLESS MANAGER ---
vless_menu() {
    clear
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "                 VLESS MANAGER"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e " [1] Buat Akun VLess"
    echo -e " [2] Hapus Akun VLess"
    echo -e " [0] Kembali"
    echo -e ""
    read -p " Select >>> " vl_opt
    case $vl_opt in
        1)
            read -p "Username : " user
            if redis-cli -h $DB_HOST -p $DB_PORT SISMEMBER "users:vless" "$user" | grep -q "1"; then
                echo -e "${RED}User sudah ada!${NC}"; sleep 1; return
            fi
            read -p "Expired (hari) : " masaaktif
            uuid=$(uuidgen)
            exp=$(date -d "+${masaaktif} days" +"%Y-%m-%d")
            
            redis-cli -h $DB_HOST -p $DB_PORT HSET "vless:$user" uuid "$uuid" exp "$exp" > /dev/null
            redis-cli -h $DB_HOST -p $DB_PORT SADD "users:vless" "$user" > /dev/null
            
            # Inject Config (Tag: vless)
            jq --arg u "$user" --arg id "$uuid" \
               '.inbounds[] | select(.tag=="vless").settings.clients += [{"id": $id, "email": $u}]' \
               $XRAY_CONFIG > /tmp/x && mv /tmp/x $XRAY_CONFIG
            
            systemctl restart xray
            echo -e "${GREEN}Sukses! VLess $user dibuat.${NC}"; sleep 2
            ;;
        0) return ;;
    esac
}

# --- 3. TROJAN MANAGER ---
trojan_menu() {
    clear
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "                 TROJAN MANAGER"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e " [1] Buat Akun Trojan"
    echo -e " [2] Hapus Akun Trojan"
    echo -e " [0] Kembali"
    echo -e ""
    read -p " Select >>> " tr_opt
    case $tr_opt in
        1)
            read -p "Username : " user
            if redis-cli -h $DB_HOST -p $DB_PORT SISMEMBER "users:trojan" "$user" | grep -q "1"; then
                echo -e "${RED}User sudah ada!${NC}"; sleep 1; return
            fi
            read -p "Expired (hari) : " masaaktif
            password="${user}123" # Default pass
            exp=$(date -d "+${masaaktif} days" +"%Y-%m-%d")
            
            redis-cli -h $DB_HOST -p $DB_PORT HSET "trojan:$user" password "$password" exp "$exp" > /dev/null
            redis-cli -h $DB_HOST -p $DB_PORT SADD "users:trojan" "$user" > /dev/null
            
            # Inject Config (Tag: trojan)
            jq --arg u "$password" \
               '.inbounds[] | select(.tag=="trojan").settings.clients += [{"password": $u}]' \
               $XRAY_CONFIG > /tmp/x && mv /tmp/x $XRAY_CONFIG
            
            systemctl restart xray
            echo -e "${GREEN}Sukses! Trojan $user dibuat.${NC}"; sleep 2
            ;;
        0) return ;;
    esac
}

# --- 4. SETTING HOST & PORT ---
settings_menu() {
    while true; do
        # Ambil Data Real-time dari DB
        dom=$(db_get_config "domain" "sg.myserver.com")
        p_vmess=$(db_get_config "port_vmess" "8080")
        p_vless=$(db_get_config "port_vless" "2082")
        p_trojan=$(db_get_config "port_trojan" "2087")
        p_socks=$(db_get_config "port_socks" "1080")
        p_http=$(db_get_config "port_http" "8081")

        clear
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "             SETTING HOST & PORT"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e " [1] Host/Domain  : ${GREEN}$dom${NC}"
        echo -e " [2] Port VMess   : ${YELLOW}$p_vmess${NC}"
        echo -e " [3] Port VLess   : ${YELLOW}$p_vless${NC}"
        echo -e " [4] Port Trojan  : ${YELLOW}$p_trojan${NC}"
        echo -e " [5] Port Socks5  : ${YELLOW}$p_socks${NC}"
        echo -e " [6] Port HTTP    : ${YELLOW}$p_http${NC}"
        echo -e " -----------------"
        echo -e " [7] TERAPKAN PERUBAHAN (Restart Service)"
        echo -e " [0] KEMBALI"
        echo -e ""
        read -p " Pilih >>> " s_opt
        case $s_opt in
            1) read -p "New Domain: " d; db_set_config "domain" "$d" ;;
            2) read -p "New Port VMess: " p; db_set_config "port_vmess" "$p" ;;
            3) read -p "New Port VLess: " p; db_set_config "port_vless" "$p" ;;
            4) read -p "New Port Trojan: " p; db_set_config "port_trojan" "$p" ;;
            5) read -p "New Port Socks5: " p; db_set_config "port_socks" "$p" ;;
            6) read -p "New Port HTTP: " p; db_set_config "port_http" "$p" ;;
            7)
                echo "Mengubah Config JSON..."
                # Logic JQ Kompleks untuk mengubah port berdasarkan Tag
                # Asumsi config.json punya inbound dengan tag: vmess, vless, trojan, socks, http
                
                jq --argjson p $p_vmess '.inbounds[] | select(.tag=="vmess").port = $p' $XRAY_CONFIG > /tmp/c && mv /tmp/c $XRAY_CONFIG
                jq --argjson p $p_vless '.inbounds[] | select(.tag=="vless").port = $p' $XRAY_CONFIG > /tmp/c && mv /tmp/c $XRAY_CONFIG
                jq --argjson p $p_trojan '.inbounds[] | select(.tag=="trojan").port = $p' $XRAY_CONFIG > /tmp/c && mv /tmp/c $XRAY_CONFIG
                
                systemctl restart xray
                echo -e "${GREEN}Service Restarted dengan Port Baru!${NC}"; sleep 2
                ;;
            0) break ;;
        esac
    done
}

# --- MENU UTAMA (DASHBOARD) ---
show_menu() {
    # Info System
    IPVPS=$(curl -s ifconfig.me)
    DOMAIN=$(db_get_config "domain" "Belum Diset")
    RAM_US=$(free -m | grep Mem | awk '{print $3}')
    
    # Status Service (Dummy Check)
    if systemctl is-active --quiet xray; then X_STAT="${GREEN}ON${NC}"; else X_STAT="${RED}OFF${NC}"; fi
    if systemctl is-active --quiet redis-server; then R_STAT="${GREEN}ON${NC}"; else R_STAT="${RED}OFF${NC}"; fi

    clear
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}        SCRIPT PREMIUM - MULTI PROTOCOL ${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    echo -e "   ${RED}Welcome To Script Premium St A1 Nyel${NC}"
    echo -e ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${RED}●${NC} IP VPS       = $IPVPS"
    echo -e "  ${RED}●${NC} DOMAIN       = $DOMAIN"
    echo -e "  ${RED}●${NC} RAM USED     = $RAM_US MB"
    echo -e "  ${RED}●${NC} XRAY CORE    = $X_STAT"
    echo -e "  ${RED}●${NC} DATABASE     = $R_STAT"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    echo -e "  [01] SSH MENU           [06] SS - LIBEV"
    echo -e "  [02] VMESS MENU         [07] INSTALL UDP"
    echo -e "  [03] VLESS MENU         [08] BACKUP/RESTORE"
    echo -e "  [04] TROJAN MENU        [09] REBOOT VPS"
    echo -e "  [05] SETTINGS (PORT)    [10] INFO SCRIPT"
    echo -e ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -p " Select Options [ 1 - 10 ] >>> " menu_option

    case $menu_option in
        1) echo "Menu SSH (Gunakan script ssh-vpn untuk ini)"; sleep 2 ;;
        2) vmess_menu ;;
        3) vless_menu ;;
        4) trojan_menu ;;
        5) settings_menu ;;
        6) echo "Shadowsocks coming soon..."; sleep 1 ;;
        7) echo "UDP Custom coming soon..."; sleep 1 ;;
        8) echo "Backup feature..."; sleep 1 ;;
        9) reboot ;;
        10) echo "Version: 3.0 Premium Redis"; sleep 2 ;;
        *) echo "Menu tidak tersedia"; sleep 1 ;;
    esac
}

# --- START ---
cek_root
while true; do
    show_menu
done
