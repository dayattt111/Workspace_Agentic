# 9router Agentic AI (Internal Workspace Template)

Direktori ini menyediakan template konfigurasi dan eksekusi untuk **9router** di dalam GaskenLE.

## Opsi Penggunaan:
1. **Gunakan Instalasi 9router Pribadi yang Sudah Ada:**
   Tentukan path di file `.env`:
   ```bash
   CUSTOM_NINEROUTER_DIR="/home/hikaruu/9router-agentic-AI"
   ```
2. **Gunakan Template Bawaan Proyek Ini:**
   Biarkan `CUSTOM_NINEROUTER_DIR=""` kosong di `.env`. GaskenLE akan secara otomatis menggunakan direktori ini (`./9router`) dan file template konfigurasinya.

## Instalasi CLI 9router (Jika Belum Ada di Laptop Baru):
```bash
# Menggunakan Bun (Rekomendasi)
bun add -g 9router

# Atau menggunakan NPM
npm install -g 9router
```

## Menjalankan Manual:
```bash
9router -p 20128 -H 0.0.0.0 -l
```
Atau cukup gunakan opsi **Unified Mode** di Pane 0 GaskenLE (`gasken`).
