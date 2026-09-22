# ⚙️ Arsitektur & Detail Konfigurasi

Halaman ini mengulas anatomi setiap berkas konfigurasi yang menyusun ekosistem Gaskenle.

---

## 1. Direktori Inti Workspace (`/home/hikaruu/gasken_workspace/`)

### A. `bin/gasken.sh` (Skrip Orkestrator Utama)
Skrip ini bertindak sebagai otak pembangun sesi. Alur eksekusinya adalah:
1. **Deteksi Folder & Sesi:** Mengambil nama folder aktif dan membuat identifier sesi `gasken-[nama_folder]`. Jika sesi sudah ada, langsung melakukan `attach-session`.
2. **Kalkulasi Dimensi Dinamis:**
   ```bash
   WIN_COLS=$(tput cols 2>/dev/null || echo 160)
   WIN_LINES=$(tput lines 2>/dev/null || echo 40)
   
   RIGHT_COLS=$(( WIN_COLS * 60 / 100 ))
   BOTTOM_LINES=$(( WIN_LINES * 35 / 100 ))
   ```
   Rasio dihitung proporsional terhadap ukuran jendela terminal pengguna (40% kiri untuk AI, 60% kanan dibagi menjadi 65% atas untuk Yazi dan 35% bawah untuk Git).
3. **Pembagian Window (Splitting):**
   * Membuat sesi dasar di Pane 0 (kiri).
   * Melakukan `split-window -h` dengan lebar `RIGHT_COLS` untuk Pane 1 (kanan).
   * Melakukan `split-window -v` pada sisi kanan dengan tinggi `BOTTOM_LINES` untuk Pane 2 (kanan bawah).
4. **Injeksi Skrip & Pengalihan Fokus:** Mengirim perintah eksekusi ke masing-masing pane secara halus (`send-keys`), lalu mengarahkan kursor aktif ke Pane 2 (Git).

### B. `config/tmux.conf` (Konfigurasi Multiplexer)
* **Prefix Custom:** Mengubah prefix default `Ctrl + b` menjadi `Ctrl + a` yang lebih mudah dijangkau satu tangan:
  ```tmux
  unbind C-b
  set -g prefix C-a
  bind C-a send-prefix
  ```
* **Latensi Nol untuk Escape:** `set -s escape-time 0` menghilangkan delay 500 ms default tmux saat menekan tombol `Esc`.
* **Mouse Integration:** `set -g mouse on` memungkinkan scrolling, klik fokus pane, dan resize border panel dengan mouse.
* **Pintasan Cepat:**
  ```tmux
  bind -n C-Space select-pane -t :.+
  bind -n BTab select-pane -t :.+
  bind -n F2 select-pane -t :.+
  ```

### C. `panes/pane-hermes.sh` (Panel Kiri - AI Agent)
Menyiapkan lingkungan untuk interaksi AI. Mengecek ketersediaan binary `hermes`:
```bash
if command -v hermes &> /dev/null; then
    hermes
else
    echo "Ketik hermes di sini nanti"
    bash --rcfile /home/hikaruu/gasken_workspace/config/workspace-bashrc -i
fi
```

### D. `panes/pane-yazi.sh` (Panel Kanan Atas - Yazi)
Menjalankan binary file manager Yazi secara eksklusif menggunakan perintah `exec yazi` sehingga tidak meninggalkan shell wrapper tambahan di memori.

### E. `panes/pane-git.sh` & `config/workspace-bashrc` (Panel Kanan Bawah - Shell Eksekusi)
Memuat subshell khusus dengan prompt ringkas dan alias penutupan sesi instan:
```bash
alias tutup="tmux kill-session"
alias bubar="tmux kill-session"
```

---

## 2. Konfigurasi Global Aplikasi Terkait

### A. Yazi Opener (`~/.config/yazi/yazi.toml`)
Kunci tercapainya **latensi 0 ms** pada pembukaan file adalah penggunaan placeholder `%s` native Yazi:

```toml
[opener]
edit = [
  { run = 'nano %s', block = true, desc = "Edit dengan Nano" }
]
image = [
  { run = 'eog %s', orphan = true, desc = "Lihat Gambar (EOG)" }
]
```

* **`block = true` pada Nano:** Menghentikan sementara interaksi Yazi sampai proses Nano selesai diedit dan ditutup (`Ctrl + x`), mencegah tumpang tindih input terminal.
* **`orphan = true` pada EOG:** Melepaskan proses viewer gambar Eye of GNOME dari process group terminal sehingga jendela gambar terbuka di latar belakang tanpa memblokir navigasi Yazi.

---

> [!IMPORTANT]
> Jangan gunakan skrip shell wrapper perantara untuk membuka file teks jika ingin mempertahankan latensi 0 ms. Pemanggilan langsung `nano %s` mengeksekusi binary editor tanpa overhead spawn subshell tambahan.
