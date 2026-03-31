#!/bin/bash
# Script: identitas.sh
# Fungsi: Minta input nama dan umur, tampilkan output dengan kondisi

set -e

# Warna biar lebih kece
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo -e "${BLUE}=== Script Identitas ===${NC}"
echo ""

# Minta input nama
read -p "Masukkan nama lo: " NAMA

# Minta input umur
read -p "Masukkan umur lo: " UMUR

echo ""
echo "Halo $NAMA, umur lo $UMUR tahun"

# Kondisi umur
if [ $UMUR -lt 25 ]; then
    echo "Lo masih muda"
else
    echo "Lo seumuran gue"
fi
