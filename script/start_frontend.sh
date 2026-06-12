#!/bin/bash
set -e

# ============================================
#   AI Provider - Start Frontend (Production)
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
cd "$ROOT/frontend"

if [ ! -d "node_modules" ]; then
    echo "[INFO] 安装前端依赖..."
    npm install
fi

echo "[INFO] 构建前端..."
npm run build

echo "[INFO] 启动前端 (端口 5173)..."
npx vite preview --host 0.0.0.0 --port 5173
