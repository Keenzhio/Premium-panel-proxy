#!/bin/bash

# ==========================================
# AUTO INSTALLER FOR PREMIUM PANEL
# ==========================================

echo -e "\e[34m[1/5] Updating System & Installing Dependencies...\e[0m"
apt update && apt upgrade -y
apt install -y redis-server jq curl uuid-runtime unzip socat

echo -e "\e[34m[2/5] Installing Xray Core (Latest)...\e[0m"
# Menggunakan script install resmi Xray
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

echo -e "\e[34m[3/5] Configuring Basic Xray JSON...\e[0m"
# Membuat config dasar yang kompatibel dengan panel.sh
cat > /etc/xray/config.json << ENDOFFILE
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 443,
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
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
ENDOFFILE

echo -e "\e[34m[4/5] Installing Panel Script...\e[0m"
# Anggap panel.sh ada di repo yang sama, atau copy manual content-nya
# Disini kita buat dummy command agar user paste panel.sh nanti
touch /usr/bin/menu
chmod +x /usr/bin/menu

echo -e "\e[34m[5/5] Finishing Setup...\e[0m"
systemctl enable redis-server
systemctl restart redis-server
systemctl enable xray
systemctl restart xray

echo -e "\e[32m=============================================\e[0m"
echo -e "\e[32m       INSTALLATION COMPLETED!               \e[0m"
echo -e "\e[32m=============================================\e[0m"
echo -e "Silahkan copy isi file 'panel.sh' ke VPS Anda:"
echo -e "Command: nano /usr/bin/menu"
echo -e "Lalu paste kode panel.sh, save, dan ketik 'menu' untuk mulai."
