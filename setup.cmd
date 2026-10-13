@echo off
setlocal EnableExtensions
cd /d "%~dp0"

set "MSYS_ROOT=C:\msys64"
set "ICPC_BIN=%MSYS_ROOT%\ucrt64\bin"
set "PATH=C:\Program Files\PowerShell\7;C:\Program Files\Git\cmd;C:\Program Files\Neovim\bin;%ICPC_BIN%;%PATH%"

if /I "%~1"=="--check" goto verify

echo [1/6] Checking Windows Package Manager...
where winget.exe >nul 2>nul
if errorlevel 1 (
  echo ERROR: winget was not found. Install Microsoft App Installer and run setup.cmd again.
  goto fail
)

echo [2/6] Installing command-line tools when missing...
call :ensure_package Microsoft.PowerShell
if errorlevel 1 goto fail
call :ensure_package Git.Git
if errorlevel 1 goto fail
call :ensure_package Neovim.Neovim
if errorlevel 1 goto fail
call :ensure_package MSYS2.MSYS2
if errorlevel 1 goto fail
call :ensure_package AutoHotkey.AutoHotkey
if errorlevel 1 goto fail

if not exist "%MSYS_ROOT%\usr\bin\pacman.exe" (
  echo ERROR: MSYS2 was installed, but pacman.exe was not found at %MSYS_ROOT%.
  goto fail
)

echo [3/6] Installing the UCRT64 C/C++ toolchain...
"%MSYS_ROOT%\usr\bin\pacman.exe" -Syu --noconfirm
"%MSYS_ROOT%\usr\bin\pacman.exe" -Syu --noconfirm
if errorlevel 1 goto fail
"%MSYS_ROOT%\usr\bin\pacman.exe" -S --needed --noconfirm mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-clang mingw-w64-ucrt-x86_64-clang-tools-extra
if errorlevel 1 goto fail

call :find_pwsh
if errorlevel 1 goto fail

echo [4/6] Adding the UCRT64 toolchain to the user PATH...
"%PWSH_EXE%" -NoLogo -NoProfile -Command "$bin=$env:ICPC_BIN; $userPath=[Environment]::GetEnvironmentVariable('Path','User'); if ([string]::IsNullOrWhiteSpace($userPath)) { $newPath=$bin } elseif (($userPath -split ';') -contains $bin) { exit 0 } else { $newPath=$bin + ';' + $userPath }; [Environment]::SetEnvironmentVariable('Path',$newPath,'User')"
if errorlevel 1 goto fail

echo [5/6] Previewing and installing the Neovim configuration...
"%PWSH_EXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\install.ps1" -Mode Junction -WhatIf
if errorlevel 1 goto fail
"%PWSH_EXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\install.ps1" -Mode Junction
if errorlevel 1 goto fail

echo [6/6] Installing the Caps Lock to Escape startup script...
set "AHK_SOURCE=%~dp0scripts\vim.ahk"
set "AHK_DEST=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\vim.ahk"
if exist "%AHK_DEST%" (
  fc /b "%AHK_SOURCE%" "%AHK_DEST%" >nul 2>nul
  if errorlevel 1 (
    for /f %%I in ('"%PWSH_EXE%" -NoLogo -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss"') do set "AHK_STAMP=%%I"
    copy /y "%AHK_DEST%" "%AHK_DEST%.backup-%AHK_STAMP%" >nul
    if errorlevel 1 goto fail
    copy /y "%AHK_SOURCE%" "%AHK_DEST%" >nul
    if errorlevel 1 goto fail
  )
) else (
  copy /y "%AHK_SOURCE%" "%AHK_DEST%" >nul
  if errorlevel 1 goto fail
)
start "" "%AHK_DEST%"

:verify
echo Verifying the environment...
for %%C in (pwsh.exe git.exe nvim.exe g++.exe gcc.exe clangd.exe clang-format.exe) do (
  where %%C >nul 2>nul
  if errorlevel 1 (
    echo ERROR: %%C is not available on PATH.
    goto fail
  )
)
if not exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\vim.ahk" (
  echo ERROR: the Caps Lock startup script is missing.
  goto fail
)
fc /b "%~dp0scripts\vim.ahk" "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\vim.ahk" >nul 2>nul
if errorlevel 1 (
  echo ERROR: the installed Caps Lock script differs from the repository version.
  goto fail
)
if not exist "%LOCALAPPDATA%\nvim\init.lua" (
  echo ERROR: the Neovim configuration is not installed.
  goto fail
)
fc /b "%~dp0init.lua" "%LOCALAPPDATA%\nvim\init.lua" >nul 2>nul
if errorlevel 1 (
  echo ERROR: the installed Neovim configuration differs from this repository.
  goto fail
)
nvim.exe --headless "+lua assert(vim.g.colors_name == 'vscode')" "+qa"
if errorlevel 1 goto fail

echo.
echo Setup completed successfully.
echo Open a new PowerShell 7 terminal, run nvim, and execute :checkhealth interactively.
exit /b 0

:ensure_package
winget list --id "%~1" --exact --accept-source-agreements --disable-interactivity 2>nul | findstr /I /C:"%~1" >nul
if not errorlevel 1 (
  echo   %~1 is already installed.
  exit /b 0
)
echo   Installing %~1...
winget install --id "%~1" --exact --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
if errorlevel 1 exit /b 1
exit /b 0

:find_pwsh
set "PWSH_EXE="
for /f "delims=" %%I in ('where pwsh.exe 2^>nul') do if not defined PWSH_EXE set "PWSH_EXE=%%I"
if not defined PWSH_EXE if exist "C:\Program Files\PowerShell\7\pwsh.exe" set "PWSH_EXE=C:\Program Files\PowerShell\7\pwsh.exe"
if not defined PWSH_EXE (
  echo ERROR: PowerShell 7 was installed, but pwsh.exe could not be found.
  exit /b 1
)
exit /b 0

:fail
echo.
echo Setup failed. Review the error above, then run setup.cmd again.
exit /b 1
