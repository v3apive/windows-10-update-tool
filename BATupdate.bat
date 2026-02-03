@echo off
chcp 65001 >nul
title Windows Multi-Installer (Select ISO Mode)
color 0b

:: Проверка прав администратора
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] ЗАПУСТИТЕ ОТ ИМЕНИ АДМИНИСТРАТОРА!
    pause
    exit
)

:: Установка пути по умолчанию (если файл Windows.iso на рабочем столе)
set "iso=%USERPROFILE%\Desktop\Windows.iso"

:menu
cls
echo ===================================================
echo           ВЫБОР И ПОДГОТОВКА ОБРАЗА
echo ===================================================
echo ТЕКУЩИЙ ISO: %iso%
echo ---------------------------------------------------
echo 1. ВЫБРАТЬ ISO ФАЙЛ (Открыть проводник)
echo 2. МОНТИРОВАТЬ ВЫБРАННЫЙ ОБРАЗ
echo 3. РАСПАКОВАТЬ (Без hwid.migration)
echo 4. ЗАПУСТИТЬ УСТАНОВКУ (Setup.exe)
echo 5. РАЗМОНТИРОВАТЬ / ИЗВЛЕЧЬ
echo 6. ВЫХОД
echo ===================================================
set /p choice="Выберите пункт (1-6): "

if "%choice%"=="1" goto select_iso
if "%choice%"=="2" goto mount_iso
if "%choice%"=="3" goto unpack
if "%choice%"=="4" goto run_setup
if "%choice%"=="5" goto unmount
if "%choice%"=="6" exit
goto menu

:select_iso
cls
echo [i] Открываю окно выбора файла...
:: Магия PowerShell для вызова стандартного окна выбора файла
for /f "delims=" %%I in ('powershell -Command "Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.OpenFileDialog; $f.Filter = 'ISO Files (*.iso)|*.iso'; $f.InitialDirectory = [Environment]::GetFolderPath('Desktop'); $f.ShowDialog() | Out-Null; $f.FileName"') do set "iso=%%I"

if "%iso%"=="" (
    echo [!] Файл не выбран.
    set "iso=%USERPROFILE%\Desktop\Windows.iso"
) else (
    echo [OK] Выбран файл: %iso%
)
pause
goto menu

:mount_iso
cls
if not exist "%iso%" (
    echo [!] Ошибка: Файл не найден! Проверьте путь.
    pause
    goto menu
)
echo [i] Монтирование: %iso%
powershell -Command "Mount-DiskImage -ImagePath '%iso%'"
echo [OK] Готово.
pause
goto menu

:unpack
cls
set "out=%USERPROFILE%\Desktop\Win10_Pack"
echo [i] Ищем букву диска для %iso%...
for /f "tokens=*" %%a in ('powershell -Command "(Get-DiskImage -ImagePath '%iso%' | Get-Volume).DriveLetter"') do set "drive=%%a"

if "%drive%"=="" (
    echo [!] Ошибка: Образ не примонтирован!
    pause
    goto menu
)

echo [i] Найдена буква: %drive%:\. Начинаю распаковку...
if not exist "%out%" mkdir "%out%"
robocopy %drive%:\ "%out%" /E /MT:8 /R:0 /W:0 /XD hwid.migration /NFL /NDL
echo [OK] Распаковка завершена! (hwid пропущен)
pause
goto menu

:run_setup
cls
if exist "%USERPROFILE%\Desktop\Win10_Pack\setup.exe" (
    start "" "%USERPROFILE%\Desktop\Win10_Pack\setup.exe"
) else (
    echo [!] Ошибка: Сначала распакуйте файлы!
)
pause
goto menu

:unmount
cls
powershell -Command "Dismount-DiskImage -ImagePath '%iso%'"
echo [OK] Извлечено.
pause
goto menu