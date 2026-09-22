#!/bin/bash
TARGET="$1"

# Deteksi tipe MIME file
MIME_TYPE=$(file --mime-type -b "$TARGET")

case "$MIME_TYPE" in
    image/*)
        # Jika gambar, buka dengan Eye of GNOME di latar belakang
        eog "$TARGET" >/dev/null 2>&1 &
        ;;
    *)
        # Selain gambar (kode, teks, json, csv), buka dengan Micro
        micro "$TARGET"
        ;;
esac
