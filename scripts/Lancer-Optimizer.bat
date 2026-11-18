@echo off
:: Lanceur Windows Optimizer — Yoan / Jarvis
:: Place ce fichier dans le meme dossier que windows-optimize.ps1

:: Verifier les droits Admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo  [!] Relancement en Administrateur...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Lancer le script PowerShell depuis le meme dossier
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0windows-optimize.ps1"

pause
