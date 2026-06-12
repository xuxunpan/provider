#!/bin/bash
# ============================================
#   AI Provider - View Service Logs
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd "$ROOT"

echo "============================================"
echo "  AI Provider - Service Logs"
echo "============================================"
echo ""

if [ $# -eq 0 ]; then
    # Follow all logs
    echo -e "${CYAN}[INFO]${NC}  Following all service logs (Ctrl+C to exit)..."
    echo ""
    docker compose logs -f
else
    # Follow specific service logs
    echo -e "${CYAN}[INFO]${NC}  Following logs for: $*"
    echo ""
    docker compose logs -f "$@"
fi
