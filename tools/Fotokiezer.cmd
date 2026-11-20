@echo off
rem Start de fotokiezer en opent hem in de browser. Stoppen: het zwarte venster sluiten.
start "Fotokiezer Van Uitert" /min powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0fotokiezer.ps1" -Open
