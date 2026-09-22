# Instalasi & Prasyarat

Halaman ini memandu instalasi dependensi sistem dan penyiapan berkas konfigurasi agar Gaskenle dapat beroperasi sempurna.

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
# Struktur direktori modular yang diharapkan
/home/hikaruu/gasken_workspace/
├── bin/
│   ├── gasken.sh             # Skrip utama pembangun sesi tmux
│   ├── gaskenle              # Symlink eksekutor CLI
│   └── buka                  # Script opener mandiri
├── config/
│   ├── tmux.conf             # Konfigurasi navigasi & mouse tmux
│   └── workspace-bashrc      # Konfigurasi subshell & alias
├── panes/
│   ├── pane-hermes.sh        # Skrip injeksi panel AI Agent
│   ├── pane-yazi.sh          # Skrip injeksi panel Yazi
│   └── pane-git.sh           # Skrip injeksi panel Git Runner
└── docs/                     # Dokumentasi Docsify
```

Beri izin eksekusi (*executable permission*) untuk seluruh skrip di `bin/` dan `panes/`:

```bash
chmod +x /home/hikaruu/gasken_workspace/bin/* /home/hikaruu/gasken_workspace/panes/*.sh
```

---

---

## 4. Konfigurasi Aplikasi Siap Pakai (Turnkey Setup)

Seluruh template konfigurasi yang sudah diuji dan dioptimasi telah tersedia di direktori `config/`. Anda cukup menyalinnya dengan satu blok perintah:

```bash
# 1. Pastikan folder konfigurasi tujuan tersedia
mkdir -p ~/.config/yazi

# 2. Salin template konfigurasi siap pakai
cp /home/hikaruu/gasken_workspace/config/yazi.toml ~/.config/yazi/yazi.toml
cp /home/hikaruu/gasken_workspace/config/keymap.toml ~/.config/yazi/keymap.toml
cp /home/hikaruu/gasken_workspace/config/nanorc ~/.nanorc
```

### Rincian Isi File Template:

#### A. Yazi Opener (`~/.config/yazi/yazi.toml`)
Menggunakan `orphan = true` agar popup modal terminal Nano terbuka seketika dalam 0 ms:

```toml
[opener]
edit = [
  { run = '/home/hikaruu/gasken_workspace/bin/edit-modal %s', orphan = true, desc = "Edit Nano (Floating Modal)" }
]
image = [
  { run = 'eog %s', orphan = true, desc = "Lihat Gambar (EOG)" }
]

[open]
rules = [
  { mime = "image/*", use = "image" },
  { mime = "text/*", use = "edit" },
  { mime = "application/json", use = "edit" },
  { mime = "application/javascript", use = "edit" },
  { url = "*", use = "edit" }
]
```

#### B. Yazi Keybindings (`~/.config/yazi/keymap.toml`)
Mengatur pintasan `Alt + o` untuk memanggil modal terminal:

```toml
[manager]
prepend_keymap = [
  { on = [ "<A-o>" ], run = "open", desc = "Buka berkas langsung (Modal Nano / EOG)" },
  { on = [ "<A-d>" ], run = "remove", desc = "Hapus berkas" },
  { on = [ "<A-i>" ], run = "size", desc = "Hitung ukuran direktori" }
]
```

#### C. Pengaturan Visual Nano (`~/.nanorc`)
Mengaktifkan nomor baris, tab size 2 spasi, dan scrolling kursor mouse:

```nanorc
set linenumbers
set autoindent
set tabsize 2
set tabstospaces
set mouse
set softwrap
set constantshow
set trimblanks
```

---

## 5. Pendaftaran Perintah Global `gasken`

Tambahkan alias ke konfigurasi shell utama Anda (`~/.bashrc`):

```bash
echo 'alias gasken="/home/hikaruu/gasken_workspace/bin/gasken.sh"' >> ~/.bashrc
echo 'alias gaskenle="/home/hikaruu/gasken_workspace/bin/gasken.sh"' >> ~/.bashrc
source ~/.bashrc
```

Sekarang perintah `gasken` dan `gaskenle` siap digunakan di folder mana saja!
