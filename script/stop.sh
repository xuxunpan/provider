#!/bin/bash
set -e

# ============================================
#   AI Provider - Stop All Services
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "============================================"
echo "  AI Provider - Stop Services"
echo "============================================"
echo ""

cd "$ROOT"

if docker compose ps --status running 2>/dev/null | grep -q "."; then
    echo -e "${GREEN}[INFO]${NC}  Stopping all services..."
    docker compose down
    echo -e "${GREEN}[INFO]${NC}  All services stopped."
else
    echo -e "${YELLOW}[INFO]${NC}  No running services found."
fi
