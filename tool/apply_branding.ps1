# Applies the high-resolution Qamoosi icon to existing Flutter Android/web
# platform folders. It never deletes platforms or changes app/user data.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
    $source = Join-Path $root 'assets\branding\qamoosi_icon.png'
    if (-not (Test-Path $source)) {
        throw 'Missing Qamoosi icon source. Run git pull origin development.'
    }

    if (-not (Test-Path 'android/app/src/main/AndroidManifest.xml')) {
        Write-Host 'Creating missing Android platform...' -ForegroundColor Cyan
        flutter create --platforms=android .
        if ($LASTEXITCODE -ne 0) { throw 'Could not create Android platform.' }
    }
    if (-not (Test-Path 'web/manifest.json')) {
        Write-Host 'Creating missing Web platform...' -ForegroundColor Cyan
        flutter create --platforms=web .
        if ($LASTEXITCODE -ne 0) { throw 'Could not create Web platform.' }
    }

    Write-Host 'Resolving Flutter packages...' -ForegroundColor Cyan
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed.' }

    Write-Host 'Configuring native English pronunciation on Android...' -ForegroundColor Cyan
    dart run tool/configure_tts_android.dart
    if ($LASTEXITCODE -ne 0) { throw 'Android pronunciation setup failed.' }

    Write-Host 'Applying Qamoosi Android and Web icons...' -ForegroundColor Cyan
    dart run flutter_launcher_icons
    if ($LASTEXITCODE -ne 0) { throw 'Icon generation failed.' }

    $expected = @(
        'android/app/src/main/res/mipmap-mdpi/ic_launcher.png',
        'android/app/src/main/res/mipmap-hdpi/ic_launcher.png',
        'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png',
        'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png',
        'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
        'web/icons/Icon-192.png',
        'web/icons/Icon-512.png'
    )
    foreach ($item in $expected) {
        if (-not (Test-Path $item)) {
            throw "Expected generated icon not found: $item"
        }
    }

    Write-Host 'Qamoosi icon installed for Android and Web.' -ForegroundColor Green
    Write-Host 'To see updated icons: flutter run -d chrome / rebuild the Android APK.'
    Write-Host 'If your Android launcher caches the old icon, reinstall the APK.'
}
finally {
    Pop-Location
}
