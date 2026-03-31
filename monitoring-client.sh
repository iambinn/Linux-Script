#!/bin/bash
# Script: monitor.sh
# Fungsi: Cek SSD health (HD Sentinel), suhu PC, dan storage usage
# Jika storage > 90%, hapus file .log dan .log.gz di /var/tmp/application

set -e

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}        System Monitoring Tool${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# ========== 1. CEK HD SENTINEL ==========
echo -e "${YELLOW}--- Hard Disk Sentinel (SSD Health) ---${NC}"

# Cek apakah HD Sentinel sudah ada
HDSENTINEL_PATH=""
if [ -f "./HDSentinel" ]; then
    HDSENTINEL_PATH="./HDSentinel"
elif [ -f "/usr/local/bin/HDSentinel" ]; then
    HDSENTINEL_PATH="/usr/local/bin/HDSentinel"
elif command -v HDSentinel &> /dev/null; then
    HDSENTINEL_PATH="HDSentinel"
else
    echo -e "${RED}HD Sentinel tidak ditemukan!${NC}"
    echo "Install dulu dengan langkah berikut:"
    echo "  cd ~"
    echo "  wget https://www.hdsentinel.com/hdslin/hdsentinel-020c-x64.zip"
    echo "  unzip hdsentinel-020c-x64.zip"
    echo "  chmod +x HDSentinel"
    echo "  sudo mv HDSentinel /usr/local/bin/"
    echo ""
fi

if [ -n "$HDSENTINEL_PATH" ]; then
    # Gunakan opsi -solid untuk output yang mudah diparsing
    # Format: drive, tempC, health%, power on hours, model, S/N, size
    sudo $HDSENTINEL_PATH -solid 2>/dev/null | while read line; do
        DRIVE=$(echo $line | awk '{print $1}')
        TEMP=$(echo $line | awk '{print $2}')
        HEALTH=$(echo $line | awk '{print $3}')
        HOURS=$(echo $line | awk '{print $4}')
        MODEL=$(echo $line | awk '{print $5}')
        SERIAL=$(echo $line | awk '{print $6}')
        SIZE=$(echo $line | awk '{print $7}')
        
        if [ "$HEALTH" != "?" ] && [ "$HEALTH" != "" ]; then
            echo "  $DRIVE - $MODEL"
            echo "    Health: $HEALTH% | Temp: ${TEMP}°C | Power On: ${HOURS} jam"
            if [ $HEALTH -lt 50 ]; then
                echo -e "    ${RED}⚠️ PERINGATAN: Health rendah! Segera backup data!${NC}"
            fi
        fi
    done
    echo ""
fi

# ========== 2. SUHU PC (Alternatif) ==========
echo -e "${YELLOW}--- Suhu CPU ---${NC}"
if command -v sensors &> /dev/null; then
    sensors | grep -E "Core|Package|temp|CPU" | head -5 | sed 's/^/  /' || echo "  Tidak ada data suhu"
else
    echo "  sensors tidak ditemukan. Install dengan: sudo apt install lm-sensors -y"
fi
echo ""

# ========== 3. CEK RAM DAN SWAP ==========
echo -e "${YELLOW}--- RAM Usage ---${NC}"

# Ambil total RAM dalam MB
TOTAL_RAM=$(free -m | awk '/^Mem:/ {print $2}')
USED_RAM=$(free -m | awk '/^Mem:/ {print $3}')
FREE_RAM=$(free -m | awk '/^Mem:/ {print $4}')
RAM_PERCENT=$((USED_RAM * 100 / TOTAL_RAM))

# Ambil info swap
TOTAL_SWAP=$(free -m | awk '/^Swap:/ {print $2}')
USED_SWAP=$(free -m | awk '/^Swap:/ {print $3}')

echo "  Total RAM: ${TOTAL_RAM}MB"
echo "  RAM Terpakai: ${USED_RAM}MB (${RAM_PERCENT}%)"
echo "  RAM Tersisa: ${FREE_RAM}MB"
echo "  Total Swap: ${TOTAL_SWAP}MB"
echo "  Swap Terpakai: ${USED_SWAP}MB"

echo ""

if [ $RAM_PERCENT -gt 95 ]; then
    echo -e "${RED}⚠️  PERINGATAN! RAM usage $RAM_PERCENT% > 95%${NC}"
    
    # Hitung 50% dari RAM fisik (dalam MB)
    SWAP_TO_ADD=$((TOTAL_RAM * 50 / 100))
    
    # Konversi ke GB untuk output (2 desimal)
    SWAP_TO_ADD_GB=$(echo "scale=2; $SWAP_TO_ADD / 1024" | bc)
    
    echo -e "${YELLOW}  Menambahkan swap sebesar 50% dari RAM fisik (${SWAP_TO_ADD}MB / ${SWAP_TO_ADD_GB}GB)${NC}"
    
    # Cek apakah swap file sudah ada
    SWAPFILE="/swapfile"
    
    if [ -f "$SWAPFILE" ]; then
        echo "  Swap file sudah ada di $SWAPFILE"
        echo "  Menonaktifkan swap sementara..."
        sudo swapoff $SWAPFILE 2>/dev/null
    fi
    
    # Buat swap file baru dengan ukuran yang ditentukan
    echo "  Membuat swap file baru..."
    sudo fallocate -l ${SWAP_TO_ADD}M $SWAPFILE 2>/dev/null || sudo dd if=/dev/zero of=$SWAPFILE bs=1M count=$SWAP_TO_ADD status=progress
    
    # Set permission
    sudo chmod 600 $SWAPFILE
    
    # Format sebagai swap
    sudo mkswap $SWAPFILE
    
    # Aktifkan swap
    sudo swapon $SWAPFILE
    
    # Tambahkan ke fstab jika belum ada
    if ! grep -q "$SWAPFILE" /etc/fstab; then
        echo "$SWAPFILE none swap sw 0 0" | sudo tee -a /etc/fstab
        echo "  Swap file ditambahkan ke /etc/fstab"
    fi
    
    echo ""
    echo -e "${GREEN}  ✓ Swap berhasil ditambahkan!${NC}"
    echo ""
    
    # Tampilkan swap baru
    NEW_TOTAL_SWAP=$(free -m | awk '/^Swap:/ {print $2}')
    echo -e "${YELLOW}  Total Swap setelah penambahan: ${NEW_TOTAL_SWAP}MB${NC}"
else
    echo -e "${GREEN}  ✓ RAM aman (${RAM_PERCENT}% < 95%)${NC}"
fi

echo ""

# ========== 4. STORAGE USAGE (VERSI CEPAT) ==========
echo -e "${YELLOW}--- Storage Usage ---${NC}"
df -h / | awk 'NR==2 {print "  Total: " $2 " | Terpakai: " $3 " | Sisa: " $4 " | Usage: " $5}'

# Ambil persentase usage (tanpa %)
USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')

echo ""
if [ $USAGE -gt 90 ]; then
    echo -e "${RED}⚠️  PERINGATAN! Storage usage $USAGE% > 90%${NC}"
    echo ""
    
    # Folder terbesar (skip /proc, /sys, /dev)
    echo -e "${YELLOW}  --- 10 Folder Terbesar di Seluruh Sistem ---${NC}"
    echo "  (Scanning... mohon tunggu)"
    du -sh /{home,var,usr,opt,root,tmp} 2>/dev/null | sort -rh | head -10 | while read size path; do
        echo "    $size - $path"
    done
    
    echo ""
    
    # File terbesar (cari di lokasi yang umum, batasi depth)
    echo -e "${YELLOW}  --- 10 File Terbesar di Seluruh Sistem ---${NC}"
    echo "  (Scanning... mohon tunggu)"
    find /home /var /usr /opt /root -type f -size +100M -exec du -sh {} \; 2>/dev/null | sort -rh | head -10 | while read size path; do
        echo "    $size - $path"
    done
    
    echo ""
    echo -e "${YELLOW}  Tips untuk investigasi lebih lanjut:${NC}"
    echo "    du -sh /home/* /var/* /usr/* 2>/dev/null | sort -rh | head -20"
    echo "    find / -type f -size +500M -exec du -sh {} \\; 2>/dev/null | sort -rh"
    
else
    echo -e "${GREEN}  ✓ Storage aman ($USAGE% < 90%)${NC}"
    echo ""
    echo -e "${YELLOW}  Info ringkas penggunaan storage:${NC}"
    echo "  --- 5 Folder Terbesar ---"
    du -sh /{home,var,usr,opt,root} 2>/dev/null | sort -rh | head -5 | while read size path; do
        echo "    $size - $path"
    done
    echo ""
    echo -e "${YELLOW}  --- 5 File Terbesar (>100MB) ---${NC}"
    find /home /var /usr /opt /root -type f -size +100M -exec du -sh {} \; 2>/dev/null | sort -rh | head -5 | while read size path; do
        echo "    $size - $path"
    done
    echo ""
    echo -e "${YELLOW}  Tidak ada file besar ditemukan? Coba cek di lokasi lain:${NC}"
    echo "    find / -type f -size +500M 2>/dev/null | head -20"
fi

echo ""
