#!/bin/bash
set -e

# ============================================
#   AI Provider - Start HK Backend
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
cd "$ROOT/backend-hk"

if [ ! -f ".env" ]; then
    echo "[INFO] Creating .env from .env.example"
    cp ".env.example" ".env"
    echo "[WARN] You MUST set OPENAI_API_KEY in backend-hk/.env !!"
fi

if grep -q "OPENAI_API_KEY=sk-your-openai-api-key" ".env" 2>/dev/null; then
    echo "[ERROR] OPENAI_API_KEY is still the example value in backend-hk/.env"
    echo "        Please edit the file and set your real OpenAI API key."
    exit 1
fi

if [ ! -d ".venv" ]; then
    echo "[INFO] Creating Python virtual environment..."
    python3 -m venv .venv
    echo "[INFO] Installing dependencies..."
    .venv/bin/pip install --upgrade pip -q
    .venv/bin/pip install -r requirements.txt -q
fi

if [ ! -d "generated" ]; then
    mkdir generated
fi

echo "[INFO] Starting HK backend on port 8001..."
.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8001
