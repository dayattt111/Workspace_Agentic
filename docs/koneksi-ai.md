# Koneksi AI Agent & Protokol Keamanan

GaskenLE dirancang dari awal untuk mengakomodasi kolaborasi manusia dan AI Agent (*pair programming*) dengan pemisahan peran yang tegas, modular, dan aman.

---

## 1. Arsitektur Smart AI Launcher (Pane 0)

Panel 0 (kiri, lebar 40%) difungsikan sebagai pusat komando agen cerdas yang dikendalikan oleh skrip `panes/pane-hermes.sh`.

Skrip peluncur ini bersifat **multi-engine & portabel**, mendukung:
* **Hermes Agent (Docker):** Menghubungkan secara otomatis ke container Docker Hermes yang terisolasi, baik untuk *attach* shell interaktif maupun inspeksi log realtime.
* **9router Agentic AI:** Menjalankan gateway server `9router` (CLI Bun) pada port default `20128` atau membuka subshell di ruang kerja 9router.
* **Terminal Shell Biasa:** Shell Bash workspace mandiri yang diisolasi dengan konfigurasi `config/workspace-bashrc`.

### Konfigurasi Portabel: `config/agent.conf`
Seluruh path dan preferensi peluncuran diatur dalam berkas `config/agent.conf`. Berkas ini dapat disalin antar-laptop tanpa merusak repositori git:

```bash
# Lokasi direktori Hermes Agent (Docker)
HERMES_DIR="${HERMES_DIR:-$HOME/hermes-agents}"
HERMES_CONTAINER="${HERMES_CONTAINER:-hermes-agent}"

# Lokasi direktori 9router Agentic AI
NINEROUTER_DIR="${NINEROUTER_DIR:-$HOME/9router-agentic-AI}"

# Mode Default Eksekusi Pane 0:
# - "menu"    : Tampilkan menu pemilih interaktif (Hermes, 9router, Shell)
# - "hermes"  : Otomatis langsung menghubungkan ke Hermes Agent (Docker)
# - "9router" : Otomatis langsung membuka ruang kerja 9router
# - "shell"   : Terminal shell biasa dengan prompt workspace
DEFAULT_AGENT="menu"
```

---

## 2. Integrasi Hermes Agent (Docker)

Hermes dijalankan dalam wadah Docker terisolasi untuk memastikan keamanan host:
* **Deteksi Otomatis:** Skrip memeriksa apakah container `hermes-agent` sedang aktif.
* **Auto-Start:** Jika container belum berjalan, peluncur menawarkan eksekusi `docker compose up -d` secara aman di direktori Hermes.
* **Interaktivitas:** Pengguna dapat memilih untuk langsung masuk ke sesi shell container (`docker exec -it hermes-agent bash`) atau memantau streaming log (`docker logs -f`).
* **Fallback Elegan:** Apabila sesi container selesai (exit), terminal tidak menutup pane tmux, melainkan kembali ke shell workspace GaskenLE.

---

## 3. Integrasi 9router Agentic AI

9router berfungsi sebagai gateway routing AI lokal dan multi-provider:
* **Eksekusi Gateway:** Skrip otomatis mendeteksi CLI `9router` (misal via Bun di `~/.bun/bin/9router`) dan menyediakan opsi menjalankan gateway dengan log server aktif (`9router -l`).
* **Lingkungan Kerja:** Skrip berpindah ke direktori `NINEROUTER_DIR` sehingga 9router dapat membaca file konfigurasi lokal dan snapshot pencadangan.
* **Graceful Exit:** Menekan `Ctrl+C` saat memantau server akan mengembalikan pengguna ke subshell terminal tanpa menghentikan sesi tmux.

---

## 4. Sinkronisasi Antar-Proses (Zero-Polling via `inotify`)

Keunggulan arsitektur GaskenLE adalah integrasi event kernel Linux:
* Ketika AI Agent (atau Antigravity) menulis, mengedit, atau menghapus file di filesystem proyek, kernel Linux langsung memicu sinyal `inotify`.
* File manager **Yazi** di Panel Kanan Atas mendengarkan sinyal ini secara native dan memperbarui tampilan pohon berkas secara instan tanpa perlu refresh manual.
* Developer dapat langsung meninjau perubahannya di Panel Kanan Bawah menggunakan `git diff` atau `git status`.

---

## 5. Protokol Keamanan & Aturan Operasional Agen

Untuk menjaga kestabilan sistem operasi dan kerahasiaan data pengguna, setiap AI Agent yang beroperasi pada sistem ini terikat oleh **GaskenLE Security Protocol**:

### ATURAN 1: Privasi File `.env` & Kredensial (Zero-Touch Policy)
1. **Dilarang Membaca/Mengubah File `.env`:** AI Agent dilarang keras membuka, membaca, menampilkan, atau memodifikasi file `.env` maupun berkas kredensial apa pun.
2. **Kendali Penuh di Tangan Pengguna:** Seluruh token API, kredensial Git, dan secret keys wajib diisi atau dipaste secara manual oleh pengguna.
3. AI Agent hanya diperbolehkan menyediakan berkas template contoh (seperti `.env.example`).

### ATURAN 2: Larangan Modifikasi Tanpa Persetujuan (*Explicit Consent*)
1. Agen dilarang keras membuat skrip otomatis untuk menimpa (*overwrite*), menghapus (*rm*), atau mengubah file konfigurasi sistem luar:
   * `~/.config/yazi/*`
   * `~/.nanorc`
   * `~/.bashrc` / `~/.profile`
2. Setiap kali ada rekomendasi perubahan atau penambahan fitur baru, Agen **wajib** menyajikan:
   * **Target File:** (Lokasi path berkas lengkap)
   * **Aksi:** (Ubah / Tambah / Hapus)
   * **Alasan Teknis & Dampak:** (Mengapa diperlukan dan bagaimana dampaknya terhadap sistem)
   * **Potongan Kode:** Diff atau blok kode yang akan diterapkan.

### ATURAN 3: Pola Verifikasi Manual (*Human-in-the-Loop*)
1. Agen dilarang menjalankan inspeksi filesystem secara liar di luar direktori proyek.
2. Jika Agen membutuhkan log atau isi berkas konfigurasi sistem tertentu, Agen wajib meminta konfirmasi transparan kepada pengguna.

### ATURAN 4: Prinsip Ekstensi Berkelanjutan
1. **Pertahankan Latensi 0 ms:** Fitur baru tidak boleh menambahkan layer shell wrapper yang lambat. Gunakan native executable C/Rust atau placeholder `%s`.
2. **Isolasi Konfigurasi:** Skrip workspace dirancang mandiri agar tidak mengotori environment global sistem operasi.
