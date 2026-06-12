#!/bin/bash
set -e

# ============================================
#   AI Provider - Start Domestic Backend
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
cd "$ROOT/backend"

if [ ! -f ".env" ]; then
    echo "[INFO] 从 .env.example 创建 .env 配置文件"
    cp ".env.example" ".env"
    echo "[WARN] 请检查 backend/.env 并根据需要修改配置"
fi

if [ ! -d ".venv" ]; then
    echo "[INFO] 创建 Python 虚拟环境..."
    python3 -m venv .venv
    echo "[INFO] 安装依赖..."
    .venv/bin/pip install --upgrade pip -q
    .venv/bin/pip install -r requirements.txt -q
fi

if [ ! -d "uploads" ]; then
    mkdir uploads
fi

echo "[INFO] 启动国内后端 (端口 8000)..."
.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
