@echo off
chcp 65001 >nul 2>&1
title Claude (Bypass Permissions)
cd /d "%~dp0"
echo 正在启动 Claude (bypass permissions 模式)...
echo.
C:\Users\yile\AppData\Roaming\npm\claude.cmd --dangerously-skip-permissions
if %errorlevel% neq 0 (
    echo [ERROR] Claude 启动失败
    pause
    exit /b 1
)
echo Claude 已关闭。
pause
