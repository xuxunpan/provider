#!/bin/bash
set -e

# ============================================
#   AI Provider - Production Deploy Script
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_info()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step()  { echo -e "\n${CYAN}[STEP]${NC} $1"; }

echo "============================================"
echo "  AI Provider - Production Deploy"
echo "============================================"
echo ""

# ---------- 1. Pre-flight checks ----------
log_step "1/4  Pre-flight checks"

if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! docker compose version &> /dev/null; then
    log_error "Docker Compose plugin is not available. Please install it."
    exit 1
fi

if [ ! -f "$ROOT/backend/.env" ]; then
    if [ -f "$ROOT/backend/.env.example" ]; then
        log_warn "backend/.env not found, creating from .env.example"
        cp "$ROOT/backend/.env.example" "$ROOT/backend/.env"
    else
        log_warn "backend/.env not found, please create it manually"
    fi
fi

if [ ! -f "$ROOT/backend-hk/.env" ]; then
    if [ -f "$ROOT/backend-hk/.env.example" ]; then
        log_warn "backend-hk/.env not found, creating from .env.example"
        cp "$ROOT/backend-hk/.env.example" "$ROOT/backend-hk/.env"
        log_error "You MUST set OPENAI_API_KEY in backend-hk/.env before deploying!"
        exit 1
    else
        log_warn "backend-hk/.env not found, please create it manually"
    fi
fi

if grep -q "OPENAI_API_KEY=sk-your-openai-api-key" "$ROOT/backend-hk/.env" 2>/dev/null; then
    log_error "OPENAI_API_KEY is still the example value in backend-hk/.env"
    log_error "Please edit backend-hk/.env and set your real OpenAI API key."
    exit 1
fi

log_info "All pre-flight checks passed."
log_info ""
log_info "  MongoDB       : docker-compose managed"
log_info "  Backend       : http://localhost:8000"
log_info "  Backend-HK    : http://localhost:8001"
log_info "  Frontend      : http://localhost:5173"
echo ""

# ---------- 2. Build images ----------
log_step "2/4  Building Docker images"
cd "$ROOT"
docker compose build --no-cache
log_info "Docker images built successfully."

# ---------- 3. Start services ----------
log_step "3/4  Starting services"
docker compose up -d
log_info "Containers started."

# ---------- 4. Health check ----------
log_step "4/4  Health check"

wait_for_service() {
    local name=$1
    local url=$2
    local max_attempts=${3:-30}
    local attempt=1

    echo -n "  Waiting for $name "
    while [ $attempt -le $max_attempts ]; do
        if curl -sf "$url" > /dev/null 2>&1; then
            echo -e " ${GREEN}ready!${NC}"
            return 0
        fi
        echo -n "."
        sleep 2
        ((attempt++))
    done
    echo -e " ${RED}timeout${NC}"
    return 1
}

wait_for_service "HK Backend"       "http://localhost:8001/api/health"
wait_for_service "Domestic Backend" "http://localhost:8000/api/health"
# Frontend may take longer (npm build + nginx start), just check if container is running
echo -n "  Waiting for Frontend "
sleep 3
if docker compose ps frontend 2>/dev/null | grep -q "Up"; then
    echo -e " ${GREEN}running!${NC}"
else
    echo -e " ${YELLOW}may still be starting${NC}"
fi

echo ""
echo "============================================"
echo "  Deployment complete!"
echo "  Open: http://localhost:5173"
echo "============================================"
