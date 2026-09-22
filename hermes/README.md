# Hermes Agent (Internal Workspace Runtime)

Direktori ini memuat konfigurasi runtime container untuk **Hermes Agent** di dalam proyek GaskenLE.

## Arsitektur Koneksi
Hermes secara otomatis dikonfigurasi untuk menggunakan **9router** sebagai gateway penyedia LLM (Large Language Models):
```
[ Hermes Docker Container ]
       │ (Port 8642)
       ▼ (Forward ke host.docker.internal:20128/v1)
[ 9router Gateway Server (Host) ]
       │
       ▼
[ Provider LLM: Ollama / Groq / OpenAI / Anthropic / dll. ]
```

## Struktur Direktori
- `docker-compose.yml`: Definisi container, pembatasan resource, network bridge, dan isolasi file.
- `data/`: Folder penyimpanan state lokal agent (diabaikan oleh git).
- `workspace/`: Folder kerja terisolasi untuk eksekusi file oleh Hermes (diabaikan oleh git).

## Cara Jalankan Manual
```bash
docker compose up -d
docker exec -it gasken-hermes bash
```
Atau cukup gunakan peluncur bawaan di Pane 0 GaskenLE (`gasken`).
