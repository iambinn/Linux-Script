#!/bin/bash
# Script: hitung.sh
# Fungsi: Kalkulator sederhana dengan pilihan operasi

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

clear
echo -e "${BLUE}=== Script Kalkulator ===${NC}"
echo ""

# Minta input angka pertama
read -p "Masukkan angka pertama: " ANGKA1

# Minta input angka kedua
read -p "Masukkan angka kedua: " ANGKA2

echo ""
echo -e "${YELLOW}Pilih operasi:${NC}"
echo "1. Tambah (+)"
echo "2. Kurang (-)"
echo "3. Kali (*)"
echo "4. Bagi (/)"
echo ""
read -p "Masukkan pilihan (1-4): " PILIHAN

echo ""
case $PILIHAN in
    1)
        HASIL=$((ANGKA1 + ANGKA2))
        echo "Hasil: $ANGKA1 + $ANGKA2 = $HASIL"
        ;;
    2)
        HASIL=$((ANGKA1 - ANGKA2))
        echo "Hasil: $ANGKA1 - $ANGKA2 = $HASIL"
        ;;
    3)
        HASIL=$((ANGKA1 * ANGKA2))
        echo "Hasil: $ANGKA1 * $ANGKA2 = $HASIL"
        ;;
    4)
        if [ $ANGKA2 -eq 0 ]; then
            echo "Error: Tidak bisa membagi dengan 0!"
        else
            HASIL=$(echo "scale=2; $ANGKA1 / $ANGKA2" | bc)
            echo "Hasil: $ANGKA1 / $ANGKA2 = $HASIL"
        fi
        ;;
    *)
        echo "Pilihan tidak valid!"
        ;;
esac
