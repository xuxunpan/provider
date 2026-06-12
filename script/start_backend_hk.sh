#!/bin/bash
set -e

# ============================================
#   AI Provider - Start HK Backend
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
cd "$ROOT/backend-hk"

if [ ! -f ".env" ]; then
    echo "[INFO] 从 .env.example 创建 .env 配置文件"
    cp ".env.example" ".env"
    echo "[WARN] 必须设置 backend-hk/.env 中的 OPENAI_API_KEY !!"
fi

if grep -q "OPENAI_API_KEY=sk-your-openai-api-key" ".env" 2>/dev/null; then
    echo "[ERROR] backend-hk/.env 中的 OPENAI_API_KEY 仍为示例值"
    echo "        请编辑该文件，设置为真实的 OpenAI API Key"
    exit 1
fi

if [ ! -d ".venv" ]; then
    echo "[INFO] 创建 Python 虚拟环境..."
    python3 -m venv .venv
    echo "[INFO] 安装依赖..."
    .venv/bin/pip install --upgrade pip -q
    .venv/bin/pip install -r requirements.txt -q
fi

if [ ! -d "generated" ]; then
    mkdir generated
fi

echo "[INFO] 启动 HK 后端 (端口 8001)..."
.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8001
