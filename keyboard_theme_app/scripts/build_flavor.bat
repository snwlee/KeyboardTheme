@echo off
REM Flutter Multi-Brand Build Script for Windows
REM This script builds different flavors of the wallpaper app

setlocal enabledelayedexpansion

if "%1"=="" (
    echo Error: Flavor not specified
    goto :usage
)

set FLAVOR=%1
set BUILD_TYPE=%2
if "%BUILD_TYPE%"=="" set BUILD_TYPE=apk

REM Validate flavor
if "%FLAVOR%"=="kedehun" goto :valid_flavor
if "%FLAVOR%"=="aespa_winter" goto :valid_flavor
if "%FLAVOR%"=="aespa_karina" goto :valid_flavor

echo Error: Invalid flavor '%FLAVOR%'
goto :usage

:valid_flavor
echo Building flavor: %FLAVOR%

REM Map underscores to camelCase for Gradle
set GRADLE_FLAVOR=%FLAVOR:_=%
if "%FLAVOR%"=="aespa_winter" set GRADLE_FLAVOR=aespaWinter
if "%FLAVOR%"=="aespa_karina" set GRADLE_FLAVOR=aespaKarina

echo Step 1: Cleaning previous builds...
call flutter clean

echo Step 2: Getting dependencies...
call flutter pub get

echo Step 3: Building %BUILD_TYPE% for %FLAVOR%...

if "%BUILD_TYPE%"=="apk" (
    call flutter build apk --release --flavor %GRADLE_FLAVOR% --dart-define=FLAVOR=%FLAVOR%
    set OUTPUT_PATH=build\app\outputs\flutter-apk\app-%GRADLE_FLAVOR%-release.apk
) else if "%BUILD_TYPE%"=="appbundle" (
    call flutter build appbundle --release --flavor %GRADLE_FLAVOR% --dart-define=FLAVOR=%FLAVOR%
    set OUTPUT_PATH=build\app\outputs\bundle\%GRADLE_FLAVOR%Release\app-%GRADLE_FLAVOR%-release.aab
) else if "%BUILD_TYPE%"=="debug" (
    call flutter build apk --debug --flavor %GRADLE_FLAVOR% --dart-define=FLAVOR=%FLAVOR%
    set OUTPUT_PATH=build\app\outputs\flutter-apk\app-%GRADLE_FLAVOR%-debug.apk
) else (
    echo Error: Invalid build type '%BUILD_TYPE%'
    goto :usage
)

if exist "%OUTPUT_PATH%" (
    echo.
    echo ========================================
    echo Build successful!
    echo Output: %OUTPUT_PATH%
    echo ========================================
) else (
    echo Build failed - output file not found
    exit /b 1
)

goto :end

:usage
echo.
echo Usage: %0 ^<flavor^> [build_type]
echo.
echo Flavors:
echo   kedehun         - K-POP DEMON HUNTERS WALLPAPER
echo   aespa_winter    - Aespa Winter Wallpaper
echo   aespa_karina    - Aespa Karina Wallpaper
echo.
echo Build Types:
echo   apk            - Build APK (default)
echo   appbundle      - Build App Bundle (for Play Store)
echo   debug          - Build debug APK
echo.
echo Examples:
echo   %0 kedehun apk
echo   %0 aespa_winter appbundle
exit /b 1

:end
endlocal
