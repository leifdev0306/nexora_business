# patch_printer_plugin.ps1
$pubCache = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev"
$pluginDirs = Get-ChildItem -Path $pubCache -Directory -Filter "flutter_pos_printer_platform_image_3-*"
if ($pluginDirs.Count -eq 0) { Write-Host "❌ No se encontró el plugin en caché" -ForegroundColor Red; exit 1 }
foreach ($dir in $pluginDirs) {
    $buildGradle = Join-Path $dir.FullName "android\build.gradle"
    if (Test-Path $buildGradle) {
        $content = Get-Content $buildGradle -Raw
        if ($content -match 'compileSdkVersion\s+\d+') {
            $newContent = $content -replace 'compileSdkVersion\s+\d+', 'compileSdkVersion 36'
            Set-Content -Path $buildGradle -Value $newContent -NoNewline
            Write-Host "✅ Parcheado: $buildGradle" -ForegroundColor Green
        }
    }
}
Write-Host "Listo. Ahora compila con: flutter build apk --release --split-per-abi" -ForegroundColor Cyan