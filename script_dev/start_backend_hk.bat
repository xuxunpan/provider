@echo off
chcp 65001 >nul 2>&1
cd /d "%~dp0..\backend-hk"

if not exist ".env" (
    echo [INFO] Creating .env from .env.example
    copy ".env.example" ".env" >nul
    echo [WARN] You MUST set OPENAI_API_KEY in backend-hk\.env !!
)

findstr /C:"OPENAI_API_KEY=sk-your-openai-api-key" ".env" >nul 2>&1
if %errorlevel% equ 0 (
    echo [ERROR] OPENAI_API_KEY is still the example value in backend-hk\.env
    echo         Please edit the file and set your real OpenAI API key.
    pause
    exit /b 1
)

if not exist ".venv" (
    echo [INFO] Creating Python virtual environment...
    python -m venv .venv
    echo [INFO] Installing dependencies...
    call .venv\Scripts\python -m pip install --upgrade pip >nul
    call .venv\Scripts\pip install -r requirements.txt
)

if not exist "generated" mkdir generated

echo [INFO] Starting HK backend on port 8001...
call .venv\Scripts\uvicorn app.main:app --host 0.0.0.0 --port 8001 --reload
pause
