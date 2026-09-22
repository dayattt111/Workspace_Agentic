# 🚀 Penggunaan Harian

Panduan alur kerja harian menggunakan Gasken Workspace untuk meningkatkan produktivitas tanpa distraksi dan tanpa beban memori.

---

## 1. Memulai Sesi Workspace

Untuk mengaktifkan workspace di direktori proyek mana pun yang sedang Anda kerjakan:

```bash
# 1. Pindah ke folder proyek Anda
cd ~/proyek/aplikasi-keren

# 2. Jalankan perintah gasken
gasken
```

### Mekanisme Penamaan Sesi Otomatis
Skrip akan secara otomatis:
1. Mengambil nama direktori aktif (`basename "$PWD"`).
2. Membuat nama sesi tmux dengan pola `gasken-[nama-folder]`.
3. Memeriksa apakah sesi tersebut sudah aktif. Jika sudah ada, tmux akan langsung **re-attach** ke sesi tersebut tanpa menduplikasi proses.

---

## 2. Alur Kolaborasi 3 Panel

Setelah perintah `gasken` dieksekusi, layar akan terbagi menjadi tiga area fungsional:

### A. Panel 0: AI Agent (Kiri - 40% Lebar Layar)
* **Peran:** Pusat interaksi instruksi agentic coding.
* **Alur Kerja:** Jika tool CLI seperti `hermes` terpasang, panel akan otomatis memuat antarmuka AI. Anda dapat memberikan prompt pengkodean, perbaikan bug, atau instruksi pembuatan fitur baru langsung di panel ini.

### B. Panel 1: File Manager Yazi (Kanan Atas - 60% Lebar Layar)
* **Peran:** Eksplorasi struktur proyek dan pembuka berkas instan.
* **Fitur Utama:**
  * Didukung oleh kernel Linux `inotify`: Setiap kali AI Agent atau editor membuat/mengubah file, daftar direktori di Yazi akan langsung ter-update secara *real-time*.
  * Sorot file dan tekan `Alt + o` untuk membuka kode di editor Nano secara instan.
  * Sorot file gambar (`.png`, `.jpg`, `.svg`) dan tekan `Alt + o` untuk membuka viewer grafis EOG di latar belakang tanpa mengunci terminal.

### C. Panel 2: Git & Execution Shell (Kanan Bawah - 35% Tinggi)
* **Peran:** Pusat kontrol terminal, kompilasi, pengujian, dan manajemen versi Git.
* **Fokus Awal:** Saat pertama kali `gasken` dibuka, kursor terminal secara otomatis difokuskan ke panel ini sehingga Anda bisa langsung mengetik perintah tanpa perlu klik mouse.
* **Tugas Umum:** Menjalankan unit test (`npm test`, `pytest`, `cargo test`), mengecek status Git (`git status`, `git diff`), serta melakukan `git commit`.

---

## 3. Menutup Workspace Secara Bersih

Untuk mematikan seluruh sesi dan semua panel sekaligus secara elegan:

Ketik perintah berikut di panel kanan bawah (Git Runner):

```bash
tutup
```
> Atau gunakan alias padanannya: `bubar`

Perintah ini akan memanggil `tmux kill-session` sehingga tidak ada background process tak terlihat yang tertinggal di memori sistem.
