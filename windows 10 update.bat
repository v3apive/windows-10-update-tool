@echo off
chcp 65001 >nul
title Windows 10 22H2 Downloader & Installer
color 0b

:: Проверка прав администратора
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] ОШИБКА: ЗАПУСТИТЕ ОТ ИМЕНИ АДМИНИСТРАТОРА!
    pause
    exit
)

:: Настройка путей
set "iso=%USERPROFILE%\Desktop\Windows.iso"
set "out=%USERPROFILE%\Desktop\Win10_Pack"

:menu
cls
echo ===================================================
echo        УПРАВЛЕНИЕ УСТАНОВКОЙ (ПОШАГОВО)
echo ===================================================
echo ТЕКУЩИЙ ОБРАЗ: %iso%
echo ---------------------------------------------------
echo 0. СКАЧАТЬ ISO НА РАБОЧИЙ СТОЛ (Шкала в консоли)
echo 1. ВЫБРАТЬ ISO (Если уже скачан)
echo 2. МОНТИРОВАТЬ ОБРАЗ (Создать вирт. диск)
echo 3. РАСПАКОВАТЬ (Robocopy без hwid.migration)
echo 4. ЗАПУСТИТЬ SETUP.EXE
echo 5. РАЗМОНТИРОВАТЬ / ИЗВЛЕЧЬ ISO
echo 6. ВЫХОД
echo ===================================================
set /p choice="Выберите пункт: "

if "%choice%"=="0" goto download
if "%choice%"=="1" goto select
if "%choice%"=="2" goto mount
if "%choice%"=="3" goto unpack
if "%choice%"=="4" goto run
if "%choice%"=="5" goto unmount
if "%choice%"=="6" exit
goto menu

:download
cls
echo [i] Начинаю загрузку ISO на рабочий стол...
echo [i] Шкала прогресса появится ниже (команда curl):
echo.
:: Твоя прямая ссылка. Флаг -# включает прогресс-бар в виде решетки
curl -L -# -o "%iso%" "https://dn710004.ca.archive.org/0/items/windows-10-22-h-2-russian-x-64/Windows%%2010%%2022H2%%20%%28Russian%%29%%20x64.iso"

if exist "%iso%" (
    echo.
    echo [OK] Загрузка завершена! Файл Windows.iso на рабочем столе.
) else (
    echo.
    echo [!] Ошибка при загрузке. Проверьте соединение.
)
pause
goto menu

:select
cls
echo [i] Выберите ISO образ в открывшемся окне...
for /f "delims=" %%I in ('powershell -Command "Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.OpenFileDialog; $f.Filter = 'ISO Files (*.iso)|*.iso'; $f.InitialDirectory = [Environment]::GetFolderPath('Desktop'); $f.ShowDialog() | Out-Null; $f.FileName"') do set "iso=%%I"
goto menu

:mount
cls
echo [i] Монтирование образа...
powershell -Command "Mount-DiskImage -ImagePath '%iso%'"
echo [OK] Готово. Если ошибок нет, диск появился в системе.
pause
goto menu

:unpack
cls
echo [i] Поиск буквы диска...
for /f "tokens=*" %%a in ('powershell -Command "(Get-DiskImage -ImagePath '%iso%' | Get-Volume).DriveLetter"') do set "drive=%%a"

if "%drive%"=="" (
    echo [!] ОШИБКА: Диск не найден. Сначала нажми кнопку 2!
    pause
    goto menu
)

echo [i] Распаковка диска %drive%:\ в папку Win10_Pack...
echo [!] Папка hwid.migration будет пропущена.
if not exist "%out%" mkdir "%out%"

:: /E (всё), /MT:8 (8 потоков), /XD (исключить папку)
robocopy %drive%:\ "%out%" /E /MT:8 /R:0 /W:0 /XD hwid.migration /NFL /NDL
echo.
echo [OK] Распаковка завершена! Проверьте папку на рабочем столе.
pause
goto menu

:run
cls
if exist "%out%\setup.exe" (
    echo [!] Запуск установки...
    start "" "%out%\setup.exe"
) else (
    echo [!] Ошибка: Setup.exe не найден. Сначала распакуйте (Пункт 3).
)
pause
goto menu

:unmount
cls
echo [i] Извлечение образа...
powershell -Command "Dismount-DiskImage -ImagePath '%iso%'"
echo [OK] Виртуальный привод пуст.
pause
goto menu

