@echo off
chcp 65001 >nul 2>&1
setlocal
title Claude (Dangerously Skip Permissions)
cd /d "%~dp0"
echo 当前工作目录：%CD%
echo 正在检测 Claude CLI...
where claude >nul 2>&1
if errorlevel 1 (
    echo [ERROR] 未在 PATH 中找到 claude。
    echo 请先安装 Claude CLI，并重新打开应用或终端以刷新 PATH。
    pause
    exit /b 1
)
echo 正在启动：claude --dangerously-skip-permissions
echo.
call claude --dangerously-skip-permissions
set "CLAUDE_EXIT=%ERRORLEVEL%"
if not "%CLAUDE_EXIT%"=="0" (
    echo.
    echo [ERROR] Claude 启动或运行失败，退出码：%CLAUDE_EXIT%
    pause
    exit /b %CLAUDE_EXIT%
)
echo.
echo Claude 已关闭。
pause
endlocal
