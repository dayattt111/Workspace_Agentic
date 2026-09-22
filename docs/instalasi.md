# 📦 Instalasi & Prasyarat

Halaman ini memandu instalasi dependensi sistem dan penyiapan berkas konfigurasi agar Gasken Workspace dapat beroperasi sempurna.

---

## 1. Prasyarat Sistem

* **Sistem Operasi:** Ubuntu 22.04 LTS / 24.04 LTS (atau distro Linux turunan Debian lainnya).
* **Terminal Emulator:** GNOME Terminal, Ptyxis, Alacritty, Kitty, atau WezTerm dengan dukungan *True Color* (24-bit).
* **Font Rekomendasi:** Nerd Font (misal: *JetBrains Mono Nerd Font* atau *FiraCode Nerd Font*) agar ikon di Yazi tampil sempurna.

---

## 2. Instalasi Paket Dependensi

Buka terminal dan pasang dependensi utama sistem menggunakan perintah berikut:

```bash
# Update repository
sudo apt update

# Pasang tmux, nano, eog (Eye of GNOME), dan utilitas pendukung
sudo apt install -y tmux nano eog git curl xclip
```

### Memasang Yazi File Manager
Yazi adalah file manager terminal berbasis Rust yang sangat cepat. Anda dapat memasang versi prebuilt binary resminya:

```bash
# Unduh dan pasang binary Yazi (contoh x86_64)
curl -sS https://raw.githubusercontent.com/sxyazi/yazi/main/scripts/install.sh | bash
```
> Atau melalui package manager jika tersedia (misal: `cargo install --locked yazi-fm yazi-cli`).

Pastikan Yazi sudah terpasang dengan mengecek versinya:
```bash
yazi --version
```

---

## 3. Penyiapan Berkas Workspace

Pastikan seluruh berkas orkestrasi berada di folder workspace Anda:

```bash
# Struktur direktori yang diharapkan
/home/hikaruu/gasken_workspace/
├── gasken.sh             # Skrip utama pembangun sesi tmux
├── tmux.conf             # Konfigurasi navigasi & mouse tmux
├── pane-hermes.sh        # Skrip injeksi panel AI Agent
├── pane-yazi.sh          # Skrip injeksi panel Yazi
├── pane-git.sh           # Skrip injeksi panel Git Runner
├── workspace-bashrc      # Konfigurasi subshell & alias
└── docs/                 # Dokumentasi Docsify
```

Beri izin eksekusi (*executable permission*) untuk seluruh skrip `.sh`:

```bash
chmod +x /home/hikaruu/gasken_workspace/*.sh
```

---

## 4. Konfigurasi Global Aplikasi Terkait

### A. Konfigurasi Yazi (`~/.config/yazi/yazi.toml`)
Pastikan aturan *opener* dikonfigurasi untuk memetakan teks ke Nano secara *blocking* dan gambar ke EOG secara *orphan*:

```toml
[opener]
edit = [
  { run = 'nano %s', block = true, desc = "Edit dengan Nano" }
]
image = [
  { run = 'eog %s', orphan = true, desc = "Lihat Gambar (EOG)" }
]

[open]
rules = [
  { mime = "text/*", use = "edit" },
  { mime = "application/json", use = "edit" },
  { mime = "application/javascript", use = "edit" },
  { mime = "image/*", use = "image" },
  { name = "*", use = "edit" }
]
```

### B. Konfigurasi Pintasan Tombol Yazi (`~/.config/yazi/keymap.toml`)
Tambahkan aturan tombol agar `Alt + o` memanggil opener:

```toml
[manager]
prepend_keymap = [
  { on = [ "<A-o>" ], run = "open", desc = "Buka berkas langsung" },
  { on = [ "<A-d>" ], run = "remove", desc = "Hapus berkas" },
  { on = [ "<A-i>" ], run = "size", desc = "Hitung ukuran direktori" }
]
```

### C. Konfigurasi Nano Editor (`~/.nanorc`)
Agar Nano nyaman untuk quick code-review, tambahkan baris ini ke berkas `~/.nanorc`:

```nanorc
set linenumbers
set autoindent
set tabsize 2
set tabstospaces
set mouse
set softwrap
set constantshow
```

---

## 5. Pendaftaran Perintah Global `gasken`

Tambahkan alias ke konfigurasi shell utama Anda (`~/.bashrc`):

```bash
echo 'alias gasken="/home/hikaruu/gasken_workspace/gasken.sh"' >> ~/.bashrc
source ~/.bashrc
```

Sekarang perintah `gasken` siap digunakan di folder mana saja!
