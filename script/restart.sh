#!/bin/bash
set -e

# ============================================
#   AI Provider - Restart All Services
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"

GREEN='\033[0;32m'
NC='\033[0m'

echo "============================================"
echo "  AI Provider - Restart Services"
echo "============================================"
echo ""

cd "$ROOT"

echo -e "${GREEN}[INFO]${NC}  Restarting all services..."
docker compose restart
echo -e "${GREEN}[INFO]${NC}  All services restarted."
