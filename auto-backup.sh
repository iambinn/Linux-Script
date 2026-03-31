#!/bin/bash
# Script: auto-backup.sh
# Fungsi: Backup folder dan simpan hanya 5 backup terbaru

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Konfigurasi
SOURCE_DIR="/home/bunser25/script"
BACKUP_DIR="/home/bunser25/backup"
DATE=$(date +%Y%m%d)
BACKUP_FILE="$BACKUP_DIR/backup-$DATE.tar.gz"
LOG_FILE="$BACKUP_DIR/backup.log"

clear
echo -e "${BLUE}=== Auto Backup System ===${NC}"
echo ""

# Buat direktori backup jika belum ada
mkdir -p "$BACKUP_DIR"

# Cek apakah source directory ada
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}Error: Source directory $SOURCE_DIR tidak ditemukan!${NC}"
    exit 1
fi

# Mulai backup
echo -e "${YELLOW}Mulai backup $SOURCE_DIR -> $BACKUP_FILE${NC}"

# Lakukan backup dengan tar
tar -czf "$BACKUP_FILE" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")" 2>/dev/null

# Cek apakah backup berhasil
if [ $? -eq 0 ] && [ -f "$BACKUP_FILE" ]; then
    # Hitung ukuran file
    SIZE=$(ls -lh "$BACKUP_FILE" | awk '{print $5}')
    echo -e "${GREEN}✓ Backup berhasil! Ukuran: $SIZE${NC}"
    
    # Catat log
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Backup berhasil: $BACKUP_FILE ($SIZE)" >> "$LOG_FILE"
else
    echo -e "${RED}❌ Backup gagal!${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Backup gagal!" >> "$LOG_FILE"
    exit 1
fi

# ========== ROTATION: Hanya simpan 5 backup terbaru ==========
echo ""
echo -e "${YELLOW}--- Rotasi Backup (simpan 5 terbaru) ---${NC}"

# List semua backup, urutkan berdasarkan tanggal, ambil yang ke-6 ke atas
BACKUP_FILES=$(ls -1 "$BACKUP_DIR"/backup-*.tar.gz 2>/dev/null | sort -r)

# Hitung jumlah file
COUNT=$(echo "$BACKUP_FILES" | wc -l)

if [ $COUNT -gt 5 ]; then
    # Ambil file ke-6 sampai seterusnya (yang harus dihapus)
    FILES_TO_DELETE=$(echo "$BACKUP_FILES" | tail -n +6)
    
    echo "$FILES_TO_DELETE" | while read -r file; do
        if [ -f "$file" ]; then
            rm -f "$file"
            echo "  Hapus: $(basename "$file")"
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Hapus backup lama: $file" >> "$LOG_FILE"
        fi
    done
    
    echo -e "${GREEN}✓ Rotasi selesai. $(($COUNT - 5)) backup lama dihapus${NC}"
else
    echo -e "${GREEN}✓ Total backup: $COUNT (kurang dari 5, tidak perlu hapus)${NC}"
fi

# Tampilkan daftar backup yang tersisa
echo ""
echo -e "${YELLOW}Backup saat ini:${NC}"
ls -lh "$BACKUP_DIR"/backup-*.tar.gz 2>/dev/null | awk '{print "  - " $9 " (" $5 ")"}'

echo ""
echo -e "${GREEN}Semua selesai! Log tersimpan di: $LOG_FILE${NC}"
