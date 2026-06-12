@echo off
chcp 65001 >nul 2>&1
cd /d "%~dp0..\backend"

if not exist ".env" (
    echo [INFO] Creating .env from .env.example
    copy ".env.example" ".env" >nul
    echo [WARN] Please review backend\.env and update settings if needed
)

if not exist ".venv" (
    echo [INFO] Creating Python virtual environment...
    python -m venv .venv
    echo [INFO] Installing dependencies...
    call .venv\Scripts\python -m pip install --upgrade pip >nul
    call .venv\Scripts\pip install -r requirements.txt
)

if not exist "uploads" mkdir uploads

echo [INFO] Starting domestic backend on port 8000...
call .venv\Scripts\uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
pause
