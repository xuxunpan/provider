@echo off
chcp 65001 >nul 2>&1
set ROOT=%~dp0..
echo ============================================
echo   AI Provider - Local Dev Environment
echo ============================================
echo.
echo   HK Backend      : http://localhost:8001
echo   Domestic Backend: http://localhost:8000
echo   Frontend        : http://localhost:5173
echo.

tasklist /FI "IMAGENAME eq mongod.exe" 2>nul | find /I "mongod.exe" >nul
if %errorlevel% neq 0 (
    echo [WARN] MongoDB not detected. Please make sure MongoDB is running!
    echo         Start it with: mongod --dbpath=your-data-dir
    echo.
)

echo [1/3] Starting HK backend...
start "AI-HK-Backend" cmd /k ""%ROOT%\script_dev\start_backend_hk.bat""

echo         Waiting for HK backend...
:wait_hk
timeout /t 2 >nul
curl -s http://localhost:8001/api/health >nul 2>&1
if %errorlevel% neq 0 goto wait_hk
echo         HK backend is ready!

echo [2/3] Starting domestic backend...
start "AI-Domestic-Backend" cmd /k ""%ROOT%\script_dev\start_backend.bat""

echo         Waiting for domestic backend...
:wait_domestic
timeout /t 2 >nul
curl -s http://localhost:8000/api/health >nul 2>&1
if %errorlevel% neq 0 goto wait_domestic
echo         Domestic backend is ready!

echo [3/3] Starting frontend...
start "AI-Frontend" cmd /k ""%ROOT%\script_dev\start_frontend.bat""

echo.
echo ============================================
echo   All services started!
echo   Open: http://localhost:5173
echo ============================================

pause
