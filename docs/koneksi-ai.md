# 🤖 Koneksi AI Agent & Protokol Keamanan

Gaskenle dirancang dari awal untuk mengakomodasi kolaborasi manusia dan AI Agent (*pair programming*) dengan pemisahan peran yang tegas dan aman.

---

## 1. Integrasi AI Agent di Panel Kiri

Panel 0 (kiri) difungsikan sebagai wadah interaksi agen AI berbasis CLI, seperti:
* **Hermes CLI:** CLI AI agent yang otomatis dipanggil via `pane-hermes.sh` jika tersedia di sistem.
* **CLI Coding Agent Lainnya:** Antarmuka CLI AI apa pun dapat diintegrasikan dengan mengubah pemanggilan di file `pane-hermes.sh`.

### Kolaborasi Dua Arah (Dual-Layer Workflow)
Dalam setup modern, Anda dapat menggabungkan:
1. **Antigravity IDE:** Digunakan sebagai arsitek kode utama, penganalisis berkas mendalam, dan perancang sistem.
2. **Gaskenle Terminal:** Digunakan untuk eksekusi, runtime checks, monitoring file via Yazi, dan interaksi CLI cepat.

---

## 2. Sinkronisasi Antar-Proses (Zero-Polling via `inotify`)

Salah satu keunggulan arsitektur Gaskenle adalah integrasi event kernel Linux:
* Ketika AI Agent (atau Antigravity) menulis, mengedit, atau menghapus file di filesystem proyek, kernel Linux akan langsung menembakkan sinyal `inotify`.
* File manager **Yazi** di Panel Kanan Atas mendengarkan sinyal ini secara native dan memperbarui daftar berkas secara instan tanpa perlu refresh manual.
* Developer dapat langsung meninjau perubahannya di Panel Kanan Bawah menggunakan `git diff` atau `git status`.

---

## 3. Protokol Keamanan & Aturan Operasional Agen

Untuk menjaga kestabilan sistem operasi dan mencegah kerusakan pada konfigurasi OS penting, setiap AI Agent (termasuk Antigravity) yang beroperasi pada sistem ini terikat oleh **Gaskenle Protocol**:

### 🛡️ ATURAN 1: Larangan Modifikasi Tanpa Persetujuan (*Explicit Consent*)
1. Agen dilarang keras membuat skrip otomatis untuk menimpa (*overwrite*), menghapus (*rm*), atau mengubah file di lokasi:
   * `/home/hikaruu/gasken_workspace/*`
   * `~/.config/yazi/*`
   * `~/.nanorc`
   * `~/.bashrc` / `~/.profile`
2. Setiap kali ada rekomendasi perubahan atau penambahan fitur baru, Agen **wajib** menyajikan:
   * **Target File:** (Lokasi path berkas lengkap)
   * **Aksi:** (Ubah / Tambah / Hapus)
   * **Alasan Teknis & Dampak:** (Mengapa diperlukan dan bagaimana dampaknya terhadap performa)
   * **Potongan Kode:** Diff atau blok kode yang akan diterapkan.

### 🛡️ ATURAN 2: Pola Verifikasi Manual (*Human-in-the-Loop*)
1. Agen dilarang menjalankan inspeksi filesystem secara liar di luar direktori proyek.
2. Jika Agen membutuhkan log atau isi berkas konfigurasi sistem tertentu, Agen wajib meminta instruksi secara transparan kepada pengguna untuk dieksekusi di Panel Git/Execution.

### 🛡️ ATURAN 3: Prinsip Ekstensi Berkelanjutan
1. **Pertahankan Latensi 0 ms:** Fitur baru tidak boleh menambahkan layer shell wrapper yang lambat. Gunakan native executable C/Rust atau placeholder `%s`.
2. **Isolasi Konfigurasi:** Skrip workspace dirancang mandiri agar tidak mengotori environment global sistem operasi.

---

> [!CAUTION]
> Jangan pernah memberikan token kredensial Git atau API key sensitif langsung ke dalam prompt AI CLI. Selalu gunakan environment variable yang aman.
