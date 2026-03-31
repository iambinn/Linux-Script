#!/bin/bash
# Script: cek-file.sh
# Fungsi: Cek file, tampilkan ukuran, permission, dan 3 baris pertama

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo -e "${BLUE}=== Script Cek File ===${NC}"
echo ""

# Minta input nama file
read -p "Masukkan nama file: " FILE

# Cek apakah file ada
if [ -f "$FILE" ]; then
    echo ""
    echo -e "${GREEN}File ditemukan!${NC}"
    echo ""
    
    # Ukuran file
    SIZE=$(ls -lh "$FILE" | awk '{print $5}')
    echo "Ukuran file: $SIZE"
    
    # Permission file
    PERM=$(ls -l "$FILE" | awk '{print $1}')
    echo "Permission: $PERM"
    
    # 3 baris pertama isi file
    echo ""
    echo "3 baris pertama:"
    echo "-----------------------------------"
    head -n 3 "$FILE"
    echo "-----------------------------------"
else
    echo -e "${RED}Error: File '$FILE' tidak ditemukan!${NC}"
fi
