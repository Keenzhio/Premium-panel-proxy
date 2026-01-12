# 1. Hentikan semua service
systemctl stop xray
systemctl stop redis-server

# 2. Hapus Service & Aplikasi
apt purge -y xray redis-server redis-tools
apt autoremove -y

# 3. Hapus File Sampah & Konfigurasi Lama
rm -rf /etc/xray
rm -rf /usr/local/etc/xray
rm -rf /var/log/xray
rm -rf /var/lib/xray
rm -f /usr/bin/menu
rm -f /usr/bin/xray
rm -f /etc/systemd/system/xray.service
rm -f /etc/systemd/system/xray@.service

# 4. Hapus File Installer
rm -f setup.sh
rm -f panel.sh
rm -f repair.sh

# 5. Reload System
systemctl daemon-reload
clear

echo "VPS SUDAH DIBERSIHKAN!"
echo "Sekarang kamu bisa download ulang setup.sh dan coba install lagi."
