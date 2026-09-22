# ⌨️ Daftar Pintasan (Shortcuts)

Referensi lengkap pintasan keyboard (*keybindings*) untuk navigasi cepat di Gasken Workspace tanpa mengangkat tangan dari keyboard.

---

## 1. Pintasan Navigasi Antar-Panel (Tmux)

Navigasi antar-panel dirancang *zero-friction*. Anda tidak perlu menekan tombol prefix terlebih dahulu untuk berpindah panel secara berurutan:

| Pintasan Keyboard | Aksi | Keterangan |
| :--- | :--- | :--- |
| `Ctrl + Spasi` | Pindah ke panel berikutnya secara melingkar | Sangat cepat & ergonomis untuk jempol |
| `Shift + Tab` | Pindah ke panel berikutnya secara melingkar | Alternatif navigasi keyboard standar |
| `F2` | Pindah ke panel berikutnya secara melingkar | Pintasan tombol fungsi mandiri |
| `Klik Kiri Mouse` | Pindah fokus langsung ke panel yang diklik | Didukung berkat konfigurasi `mouse on` |
| `Drag Border Mouse` | Mengubah ukuran lebar/tinggi panel | Arahkan kursor ke garis pembatas panel |

### Navigasi Arah Spesifik (Menggunakan Prefix `Ctrl + a`)
Jika ingin melompat langsung ke arah panel tertentu:

| Pintasan | Aksi |
| :--- | :--- |
| `Ctrl + a` lalu `Panah Kiri` | Fokus ke Panel Kiri (AI Agent) |
| `Ctrl + a` lalu `Panah Kanan` | Fokus ke Panel Kanan |
| `Ctrl + a` lalu `Panah Atas` | Fokus ke Panel Kanan Atas (Yazi) |
| `Ctrl + a` lalu `Panah Bawah` | Fokus ke Panel Kanan Bawah (Git) |
| `Ctrl + a` lalu `o` | Rotasi fokus ke panel berikutnya |

---

## 2. Pintasan File Manager (Yazi)

Pintasan berikut berlaku ketika kursor aktif berada di dalam Panel Yazi:

| Pintasan | Fungsi | Deskripsi Teknis |
| :--- | :--- | :--- |
| `Alt + o` | **Buka File / Gambar** | Membuka kode via Nano atau gambar via EOG |
| `Enter` / `l` / `Panah Kanan` | Masuk ke direktori / Buka berkas | Navigasi hirarki folder ke dalam |
| `h` / `Panah Kiri` | Kembali ke direktori induk (Parent) | Navigasi hirarki folder keluar |
| `j` / `Panah Bawah` | Geser kursor ke bawah | Pindah item ke bawah |
| `k` / `Panah Atas` | Geser kursor ke atas | Pindah item ke atas |
| `Alt + d` | Hapus berkas / folder | Menghapus item yang sedang disorot |
| `Alt + i` | Hitung ukuran folder | Menghitung disk usage direktori |
| `.` (Titik) | Toggle berkas tersembunyi (*dotfiles*) | Menampilkan/menyembunyikan file `.env`, `.git`, dll |
| `q` | Tutup Yazi | Keluar dari file manager |

---

## 3. Pintasan Editor Teks (Nano)

Saat berkas teks dibuka via `Alt + o`, Anda berada di editor Nano:

| Pintasan | Fungsi |
| :--- | :--- |
| `Ctrl + o` lalu `Enter` | Simpan perubahan (*WriteOut*) |
| `Ctrl + x` | Keluar dari Nano (kembali ke Yazi) |
| `Ctrl + w` | Cari teks / kata kunci (*Where Is*) |
| `Ctrl + k` | Potong (*Cut*) satu baris teks |
| `Ctrl + u` | Tempel (*Paste*) baris teks yang dipotong |
| `Alt + a` | Mulai seleksi blok teks (*Mark Text*) |
| `Scroll Roda Mouse` | Gulir halaman ke atas/bawah secara halus |
| `Klik Mouse` | Memindahkan kursor langsung ke posisi klik |

---

> [!NOTE]
> Jika `Ctrl + Spasi` bentrok dengan input method bahasa (IBus) di Ubuntu, Anda dapat langsung mengandalkan `Shift + Tab` atau tombol `F2` yang sudah disiapkan bebas konflik.
