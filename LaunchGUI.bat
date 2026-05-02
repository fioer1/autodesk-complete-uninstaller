@echo off
:: Autodesk Universal Uninstaller - GUI Launcher
:: This script launches the PowerShell WPF GUI with administrator privileges

:: Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process cmd.exe -ArgumentList '/c \"%~f0\"' -Verb RunAs"
    exit /b
)

:: Launch the PowerShell GUI
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0AutodeskUninstallerGUI.ps1"
