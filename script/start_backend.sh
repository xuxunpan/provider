#!/bin/bash
set -e

# ============================================
#   AI Provider - Start Domestic Backend
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
cd "$ROOT/backend"

if [ ! -f ".env" ]; then
    echo "[INFO] Creating .env from .env.example"
    cp ".env.example" ".env"
    echo "[WARN] Please review backend/.env and update settings if needed"
fi

if [ ! -d ".venv" ]; then
    echo "[INFO] Creating Python virtual environment..."
    python3 -m venv .venv
    echo "[INFO] Installing dependencies..."
    .venv/bin/pip install --upgrade pip -q
    .venv/bin/pip install -r requirements.txt -q
fi

if [ ! -d "uploads" ]; then
    mkdir uploads
fi

echo "[INFO] Starting domestic backend on port 8000..."
.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
