@echo off
chcp 65001 >nul 2>&1
cd /d "%~dp0..\frontend"

if not exist "node_modules" (
    echo [INFO] Installing frontend dependencies...
    call npm install
)

echo [INFO] Starting frontend dev server on port 5173...
call npm run dev
pause
