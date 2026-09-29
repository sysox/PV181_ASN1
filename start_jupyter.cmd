@echo off
rem Windows: double-click this file in Explorer to start the classic Notebook.
rem It also works from cmd or PowerShell, with the same arguments as start_jupyter.ps1.
rem ExecutionPolicy Bypass is deliberate: it lets the launcher run where local
rem PowerShell scripts are blocked, and applies only to this one run.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start_jupyter.ps1" %*
if errorlevel 1 pause
