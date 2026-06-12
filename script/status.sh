#!/bin/bash
# ============================================
#   AI Provider - Service Status
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

cd "$ROOT"

echo "============================================"
echo "  AI Provider - Service Status"
echo "============================================"
echo ""

# Container status
echo -e "${CYAN}--- Containers ---${NC}"
docker compose ps 2>/dev/null || echo -e "${RED}  docker compose not available${NC}"
echo ""

# Health endpoints
echo -e "${CYAN}--- Health Checks ---${NC}"

check_health() {
    local name=$1
    local url=$2
    if curl -sf "$url" > /dev/null 2>&1; then
        echo -e "  ${GREEN}$name${NC}: $url"
    else
        echo -e "  ${RED}$name${NC}: $url (unreachable)"
    fi
}

check_health "HK Backend       " "http://localhost:8001/api/health"
check_health "Domestic Backend " "http://localhost:8000/api/health"
check_health "Frontend         " "http://localhost:5173"
echo ""

# Disk usage of volumes
echo -e "${CYAN}--- Volume Usage ---${NC}"
if [ -d "$ROOT/backend/uploads" ]; then
    echo -e "  uploads:   $(du -sh "$ROOT/backend/uploads" 2>/dev/null | cut -f1)"
fi
if [ -d "$ROOT/backend-hk/generated" ]; then
    echo -e "  generated: $(du -sh "$ROOT/backend-hk/generated" 2>/dev/null | cut -f1)"
fi
