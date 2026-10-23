# ============================================================
#  patch_all_plugins.ps1
#  Sube compileSdk a 36 en TODOS los plugins de la cache Pub
#  que esten compilando contra API < 34.
#  Idempotente: se puede ejecutar multiples veces.
# ============================================================

$pubCache = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev"

if (-not (Test-Path $pubCache)) {
    Write-Host "ERROR: Cache de Pub no encontrada en: $pubCache" -ForegroundColor Red
    Write-Host "       Ejecuta 'flutter pub get' primero"
    exit 1
}

Write-Host ""
Write-Host "Escaneando plugins en: $pubCache" -ForegroundColor Cyan
Write-Host ""

$count = 0
$total = 0

Get-ChildItem -Path $pubCache -Directory | ForEach-Object {
    $pluginDir = $_.FullName
    $pluginName = $_.Name

    $buildGradle = Join-Path $pluginDir "android\build.gradle"
    $buildGradleKts = Join-Path $pluginDir "android\build.gradle.kts"

    # -- Caso 1: build.gradle (Groovy) --
    if (Test-Path $buildGradle) {
        $content = Get-Content $buildGradle -Raw
        $changed = $false
        $detected = $null

        if ($content -match 'compileSdkVersion\s+(\d+)') {
            $current = [int]$Matches[1]
            $detected = $current
            if ($current -lt 34) {
                $content = $content -replace 'compileSdkVersion\s+\d+', 'compileSdkVersion 36'
                $changed = $true
            }
        }
        elseif ($content -match '\bcompileSdk\s+(\d+)') {
            $current = [int]$Matches[1]
            $detected = $current
            if ($current -lt 34) {
                $content = $content -replace '\bcompileSdk\s+\d+', 'compileSdk 36'
                $changed = $true
            }
        }

        if ($changed) {
            Set-Content -Path $buildGradle -Value $content -NoNewline
            Write-Host "[OK] $pluginName : compileSdk $detected -> 36" -ForegroundColor Green
            $count++
        }
        $total++
    }

    # -- Caso 2: build.gradle.kts (Kotlin DSL) --
    if (Test-Path $buildGradleKts) {
        $content = Get-Content $buildGradleKts -Raw
        $changed = $false
        $detected = $null

        if ($content -match 'compileSdk\s*=\s*(\d+)') {
            $current = [int]$Matches[1]
            $detected = $current
            if ($current -lt 34) {
                $content = $content -replace 'compileSdk\s*=\s*\d+', 'compileSdk = 36'
                $changed = $true
            }
        }
        elseif ($content -match 'compileSdkVersion\s*=\s*(\d+)') {
            $current = [int]$Matches[1]
            $detected = $current
            if ($current -lt 34) {
                $content = $content -replace 'compileSdkVersion\s*=\s*\d+', 'compileSdkVersion = 36'
                $changed = $true
            }
        }

        if ($changed) {
            Set-Content -Path $buildGradleKts -Value $content -NoNewline
            Write-Host "[OK] $pluginName : compileSdk $detected -> 36" -ForegroundColor Green
            $count++
        }
        $total++
    }
}

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  Plugins escaneados:  $total" -ForegroundColor White
Write-Host "  Plugins parcheados:  $count" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

if ($count -eq 0) {
    Write-Host "INFO: No se encontraron plugins con compileSdk < 34." -ForegroundColor Yellow
    Write-Host "      Todos ya estan compilando contra API 34+." -ForegroundColor Yellow
}
else {
    Write-Host "Ahora compila con:" -ForegroundColor Cyan
    Write-Host "  flutter build apk --release --split-per-abi" -ForegroundColor White
}

Write-Host ""
Write-Host "NOTA: si ejecutas 'flutter pub cache repair', debes volver a correr este script." -ForegroundColor DarkYellow