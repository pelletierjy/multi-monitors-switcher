@echo off
rem Thin launcher. The logic is in CentralOnly.ps1.
powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0CentralOnly.ps1"
