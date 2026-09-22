# Koneksi AI Agent & Protokol Keamanan

GaskenLE menyediakan ekosistem AI Agent terintegrasi langsung di dalam proyek dengan skema **Unified Gateway & Agent**.

---

## 1. Skema Arsitektur: 9router ⟷ Hermes Agent

Semua lalu lintas model kecerdasan buatan dirutekan secara efisien dan terisolasi:

```text
┌─────────────────────────────────────────────────────────────┐
│                       SISTEM HOST                           │
│                                                             │
│   ┌─────────────────────────────────────────────────────┐   │
│   │  9router Gateway Server                             │   │
│   │  (Port 20128 / Default 0.0.0.0)                     │   │
│   │  • Router LLM Lokal (Ollama) / Cloud API            │   │
│   └──────────────▲──────────────────────────────────────┘   │
│                  │ (host.docker.internal:20128/v1)          │
│                  ▼                                          │
│   ┌─────────────────────────────────────────────────────┐   │
│   │  Hermes Agent (Docker Container: gasken-hermes)     │   │
│   │  (Port 6666 lokal host -> 8642 container)           │   │
│   │  • Folder internal: ./hermes                        │   │
│   │  • Isolasi volume ./data & ./workspace              │   │
│   └──────────────▲──────────────────────────────────────┘   │
│                  │                                          │
│   ┌──────────────▼──────────────────────────────────────┐   │
│   │  GaskenLE Pane 0 (panes/pane-hermes.sh)             │   │
│   │  • Tampilan interaktif shell / streaming log agent  │   │
│   └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

1. **9router Gateway (Host):** Bertindak sebagai gateway cerdas yang mengagregasi model-model AI (Ollama lokal, Groq, OpenAI, Anthropic, OpenRouter).
2. **Hermes Agent (Docker):** Berjalan di container Docker di dalam folder internal `./hermes`. Hermes memanggil LLM melalui endpoint `http://host.docker.internal:20128/v1` milik 9router.
3. **GaskenLE Pane 0:** Terminal interaktif di panel kiri tmux yang langsung menghubungkan developer ke dalam sesi Hermes yang sudah siap pakai.

---

## 2. Struktur Internal Proyek

Proyek ini telah dilengkapi dengan runtime & template bawaan sehingga **siap pakai dan portabel** saat di-clone ke laptop mana pun:

### Folder `./hermes`
* `docker-compose.yml`: Definisi container Hermes, network bridge, resource limits (2 CPU, 2GB RAM), dan koneksi ke `host.docker.internal`.
* `data/`: Penyimpanan persisten memori & riwayat agent (diabaikan oleh git).
* `workspace/`: Ruang kerja eksekusi terisolasi (diabaikan oleh git).

### Folder `./9router`
* `template.config.json`: Template konfigurasi provider LLM kosongan siap pakai.
* `package.json`: Skrip npm/bun untuk menginstal CLI atau menjalankan server.

---

## 3. Konfigurasi Dinamis & Privat via `.env`

Untuk menjaga keamanan kredensial dan fleksibilitas konfigurasi antar-perangkat, semua pengaturan dapat disesuaikan di file `.env`.

Contoh template telah disediakan di [`.env.example`](file:///home/hikaruu/gasken_workspace/.env.example):

```bash
# --- MODE PELUNCURAN PANE 0 ---
# "unified" (Rekomendasi) | "menu" | "hermes" | "9router" | "shell"
AGENT_MODE="menu"

# --- HERMES AGENT (DOCKER) ---
HERMES_CONTAINER_NAME="gasken-hermes"
HERMES_PORT=6666
HERMES_DIR="" # Kosongkan untuk memakai ./hermes internal

# --- 9ROUTER GATEWAY ---
NINEROUTER_PORT=20128
NINEROUTER_HOST="0.0.0.0"
NINEROUTER_GATEWAY_URL="http://host.docker.internal:20128/v1"

# Ingin pakai instalasi 9router pribadi di luar? Isi path di sini:
# Contoh: CUSTOM_NINEROUTER_DIR="/home/hikaruu/9router-agentic-AI"
# Jika dikosongkan, GaskenLE otomatis memakai template internal ./9router
CUSTOM_NINEROUTER_DIR=""

# --- API KEYS (Diisi manual oleh Anda di .env) ---
OPENAI_API_KEY=""
ANTHROPIC_API_KEY=""
GROQ_API_KEY=""
```

---

## 4. Opsi Peluncuran Pane 0

Saat menjalankan `gasken`, Pane 0 menampilkan menu pemilih:

1. **🚀 Unified Mode (9router + Hermes Connected):**
   * Otomatis memeriksa apakah 9router aktif; jika belum, menjalankannya di background (`logs/9router.log`).
   * Menjalankan container Docker Hermes (`docker compose up -d`).
   * Membuka sesi shell interaktif langsung ke dalam Hermes Agent yang sudah tersambung ke 9router.
2. **🌐 9router Gateway Server Saja:**
   * Menjalankan server 9router dengan live console log di port `20128`.
3. **🤖 Hermes Agent Saja:**
   * Masuk ke shell container, streaming log realtime, atau restart container.
4. **🐚 Terminal Shell Biasa:**
   * Shell bash workspace standar.

---

## 5. Protokol Keamanan Kredensial (Zero-Touch Policy)

* File `.env` bersifat **RAHASIA & PRIVAT**. AI Agent tidak memiliki hak untuk membaca, mencetak, atau menimpa isi file `.env`.
* Pengguna mengisi atau menempelkan (*paste*) API key secara mandiri di `.env`.
* Folder data, log, dan token sesi otomatis diabaikan oleh `.gitignore` sehingga aman dari risiko *unintentional commit*.
