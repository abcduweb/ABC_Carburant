# =====================================================================
#  ABC Carburant - Creation du keystore de release et configuration
#  de la signature Gradle.
#
#  A executer UNE SEULE FOIS, depuis n'importe ou :
#     powershell -ExecutionPolicy Bypass -File creer_keystore.ps1
# =====================================================================

$ErrorActionPreference = "Stop"

$projet   = "C:\abc_carburant"
$keystore = "$env:USERPROFILE\abcduweb-release.jks"
$alias    = "abcduweb"

Write-Host ""
Write-Host "=== ABC Carburant - Configuration de la signature ===" -ForegroundColor Green
Write-Host ""

# --- 1. Localiser keytool -------------------------------------------

$keytool = $null
$candidats = @(
    "$env:LOCALAPPDATA\Programs\Android Studio\jbr\bin\keytool.exe",
    "$env:ProgramFiles\Android\Android Studio\jbr\bin\keytool.exe",
    "$env:ProgramFiles\Java\jdk*\bin\keytool.exe"
)
foreach ($c in $candidats) {
    $trouve = Get-ChildItem $c -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($trouve) { $keytool = $trouve.FullName; break }
}
if (-not $keytool) {
    $cmd = Get-Command keytool.exe -ErrorAction SilentlyContinue
    if ($cmd) { $keytool = $cmd.Source }
}
if (-not $keytool) {
    Write-Host "keytool introuvable. Installez Android Studio ou un JDK." -ForegroundColor Red
    exit 1
}
Write-Host "keytool : $keytool" -ForegroundColor Gray

# --- 2. Keystore existant ? -----------------------------------------

if (Test-Path $keystore) {
    Write-Host ""
    Write-Host "ATTENTION : un keystore existe deja ici :" -ForegroundColor Yellow
    Write-Host "  $keystore"
    Write-Host "Le remplacer vous empechera DEFINITIVEMENT de mettre a jour"
    Write-Host "une application deja publiee avec celui-ci."
    $rep = Read-Host "Taper REMPLACER pour ecraser, ou Entree pour conserver"
    if ($rep -ne "REMPLACER") {
        Write-Host "Keystore conserve. Passage a la configuration Gradle." -ForegroundColor Green
    } else {
        Remove-Item $keystore -Force
    }
}

# --- 3. Creation ----------------------------------------------------

if (-not (Test-Path $keystore)) {
    Write-Host ""
    Write-Host "Choisissez un mot de passe (8 caracteres minimum)." -ForegroundColor Cyan
    Write-Host "NOTEZ-LE : il est irrecuperable." -ForegroundColor Yellow
    $mdp1 = Read-Host "Mot de passe" -AsSecureString
    $mdp2 = Read-Host "Confirmer"   -AsSecureString

    $p1 = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
          [Runtime.InteropServices.Marshal]::SecureStringToBSTR($mdp1))
    $p2 = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
          [Runtime.InteropServices.Marshal]::SecureStringToBSTR($mdp2))

    if ($p1 -ne $p2)     { Write-Host "Les mots de passe different." -ForegroundColor Red; exit 1 }
    if ($p1.Length -lt 8){ Write-Host "8 caracteres minimum." -ForegroundColor Red; exit 1 }

    & $keytool -genkeypair -v `
        -keystore $keystore `
        -alias $alias `
        -keyalg RSA -keysize 2048 -validity 10000 `
        -storepass $p1 -keypass $p1 `
        -dname "CN=ABCduWeb, OU=Agence Web, O=SASU ABCduWeb, L=Beauvallon, ST=Drome, C=FR"

    if ($LASTEXITCODE -ne 0) { Write-Host "Echec de creation." -ForegroundColor Red; exit 1 }
    Write-Host ""
    Write-Host "Keystore cree : $keystore" -ForegroundColor Green

    # --- 4. key.properties ------------------------------------------

    $chemin = $keystore -replace '\\', '/'
    @"
storePassword=$p1
keyPassword=$p1
keyAlias=$alias
storeFile=$chemin
"@ | Set-Content "$projet\android\key.properties" -Encoding UTF8

    Write-Host "key.properties ecrit dans $projet\android\" -ForegroundColor Green
}

# --- 5. .gitignore --------------------------------------------------

$gi = "$projet\.gitignore"
if (Test-Path $gi) {
    $c = Get-Content $gi -Raw
    if ($c -notmatch "key\.properties") {
        Add-Content $gi "`r`nandroid/key.properties`r`n*.jks`r`n*.keystore"
    }
}

# --- 6. Empreinte SHA-1 ---------------------------------------------

Write-Host ""
Write-Host "=== Empreintes du keystore ===" -ForegroundColor Cyan
if (Test-Path "$projet\android\key.properties") {
    $props = @{}
    Get-Content "$projet\android\key.properties" | ForEach-Object {
        if ($_ -match '^(.+?)=(.*)$') { $props[$matches[1]] = $matches[2] }
    }
    & $keytool -list -v -keystore $keystore -alias $alias `
        -storepass $props['storePassword'] |
        Select-String -Pattern "SHA1:|SHA256:"
}

# --- 7. Rappels -----------------------------------------------------

Write-Host ""
Write-Host "=== A FAIRE MAINTENANT ===" -ForegroundColor Yellow
Write-Host "1. Copier $keystore sur un support externe (cle USB, coffre-fort"
Write-Host "   de mots de passe). Sa perte rend toute mise a jour impossible."
Write-Host "2. Noter le mot de passe au meme endroit."
Write-Host "3. Appliquer le bloc signingConfigs dans android\app\build.gradle.kts"
Write-Host "   (voir 1_KEYSTORE.md, section 3)."
Write-Host "4. flutter build appbundle --release"
Write-Host ""
