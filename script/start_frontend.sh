#!/bin/bash
set -e

# ============================================
#   AI Provider - Start Frontend (Production)
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
cd "$ROOT/frontend"

if [ ! -d "node_modules" ]; then
    echo "[INFO] Installing frontend dependencies..."
    npm install
fi

echo "[INFO] Building frontend..."
npm run build

echo "[INFO] Starting frontend on port 5173..."
npx vite preview --host 0.0.0.0 --port 5173
