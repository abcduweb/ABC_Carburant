# =====================================================================
#  ABC Carburant - reconstruction complete du projet
#
#  A utiliser quand le dossier de travail a ete vide ou corrompu : le
#  dossier android/ n'est pas versionne et doit etre regenere par
#  flutter create, puis reconfigure (signature, desugaring, NDK).
#
#  Usage :
#     cd C:\abc_carburant\publication
#     powershell -ExecutionPolicy Bypass -File RECONSTRUIRE.ps1
#
#  Le script fonctionne que la source soit le dossier cible lui-meme
#  ou un dossier separe : le code est d'abord mis a l'abri dans un
#  dossier temporaire, puis restaure APRES flutter create.
#
#  Fichier volontairement sans aucun caractere accentue : PowerShell
#  lit les .ps1 en ANSI sur un Windows francais et les accents UTF-8
#  y cassent l'analyse du script.
# =====================================================================

$ErrorActionPreference = "Stop"

$projet   = "C:\abc_carburant"
$keystore = "$env:USERPROFILE\abcduweb-release.jks"
$source   = Split-Path -Parent $PSScriptRoot
$stage    = "$env:TEMP\abc_src_$(Get-Date -Format 'yyyyMMddHHmmss')"

Write-Host ""
Write-Host "=== Reconstruction de ABC Carburant ===" -ForegroundColor Green
Write-Host "Source : $source"
Write-Host "Cible  : $projet"
Write-Host ""

# --- 0. La source contient-elle bien le code ? ----------------------

if (-not (Test-Path "$source\lib\main.dart")) {
    Write-Host "Code source introuvable : $source\lib\main.dart" -ForegroundColor Red
    Write-Host ""
    Write-Host "Recuperez le projet avant de relancer :"
    Write-Host "   cd C:\"
    Write-Host "   git clone https://github.com/abcduweb/ABC_Carburant.git abc_carburant"
    exit 1
}

# --- 1. Le keystore : sans lui, plus aucune mise a jour possible ----

if (-not (Test-Path $keystore)) {
    Write-Host "KEYSTORE INTROUVABLE : $keystore" -ForegroundColor Red
    Write-Host ""
    Write-Host "Sans ce fichier, Google Play refusera toute mise a jour de"
    Write-Host "l'application : la cle de signature ne peut pas etre recreee."
    Write-Host "Cherchez-le avant d'aller plus loin (sauvegardes, autre disque)."
    exit 1
}
Write-Host "[1/7] Keystore trouve." -ForegroundColor Green

# --- 2. Mise a l'abri du code ---------------------------------------
# Indispensable : si la source EST la cible, flutter create et les
# copies qui suivent travailleraient sur le dossier qu'on vient de
# modifier. On fige donc une copie avant toute operation.

Write-Host "[2/7] Mise a l'abri du code dans $stage..."
New-Item -ItemType Directory -Path $stage -Force | Out-Null
foreach ($e in @("lib","assets","publication","play_store","config_reference","icones")) {
    if (Test-Path "$source\$e") { Copy-Item "$source\$e" $stage -Recurse -Force }
}
foreach ($f in @("pubspec.yaml","README.md","LICENSE",".gitignore")) {
    if (Test-Path "$source\$f") { Copy-Item "$source\$f" $stage -Force }
}
if (-not (Test-Path "$stage\lib\main.dart")) {
    Write-Host "La mise a l'abri a echoue, rien n'a ete modifie." -ForegroundColor Red
    exit 1
}
$n = (Get-ChildItem "$stage\lib" -Recurse -Filter *.dart).Count
Write-Host "      $n fichiers Dart mis a l'abri." -ForegroundColor Green

# --- 3. Projet Flutter neuf -----------------------------------------
# --org + --project-name donnent le package com.abcduweb.abc_carburant,
# celui declare dans Play Console. Un package different serait refuse.

Write-Host "[3/7] Creation du projet Flutter..."
if (-not (Test-Path $projet)) { New-Item -ItemType Directory -Path $projet | Out-Null }
Push-Location $projet
& flutter create --org com.abcduweb --project-name abc_carburant --platforms android,ios . | Out-Null
$code = $LASTEXITCODE
Pop-Location
if ($code -ne 0) {
    Write-Host "flutter create a echoue. Code intact dans $stage" -ForegroundColor Red
    exit 1
}

# --- 4. Restauration du code depuis la copie figee ------------------

Write-Host "[4/7] Restauration du code..."
Remove-Item "$projet\lib" -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item "$stage\lib" $projet -Recurse -Force
foreach ($e in @("assets","publication","play_store","config_reference","icones")) {
    if (Test-Path "$stage\$e") {
        Remove-Item "$projet\$e" -Recurse -Force -ErrorAction SilentlyContinue
        Copy-Item "$stage\$e" $projet -Recurse -Force
    }
}
foreach ($f in @("pubspec.yaml","README.md","LICENSE",".gitignore")) {
    if (Test-Path "$stage\$f") { Copy-Item "$stage\$f" $projet -Force }
}

# --- 5. Configuration Android ---------------------------------------
# build.gradle.kts porte la signature de release, le desugaring exige
# par flutter_local_notifications et la version du NDK imposee par les
# plugins. Celui genere par flutter create n'a rien de tout cela.

Write-Host "[5/7] Configuration Android..."
Copy-Item "$stage\config_reference\build.gradle.kts" `
          "$projet\android\app\build.gradle.kts" -Force
Copy-Item "$stage\config_reference\AndroidManifest.xml" `
          "$projet\android\app\src\main\AndroidManifest.xml" -Force

# --- 6. key.properties et icones ------------------------------------
# key.properties n'est jamais versionne : il contient le mot de passe.

Write-Host "[6/7] Signature et icones..."
$kp = "$projet\android\key.properties"
if (Test-Path $kp) {
    Write-Host "      key.properties existe deja, conserve."
} else {
    Write-Host ""
    Write-Host "      Mots de passe du keystore (saisie masquee)." -ForegroundColor Yellow
    $storePass = Read-Host "      Mot de passe du keystore" -AsSecureString
    $keyPass   = Read-Host "      Mot de passe de la cle (souvent le meme)" -AsSecureString

    $s = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
         [Runtime.InteropServices.Marshal]::SecureStringToBSTR($storePass))
    $k = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
         [Runtime.InteropServices.Marshal]::SecureStringToBSTR($keyPass))

    # Barres obliques : Java lit key.properties au format Properties, ou
    # l'antislash est un caractere d'echappement. "C:\Users\..." y
    # deviendrait "C:UsersUtilisateur...", le keystore serait introuvable
    # et Gradle retomberait SILENCIEUSEMENT sur la signature de debogage,
    # que Play Console refuse. ASCII, car -Encoding UTF8 ajoute un BOM
    # qui empecherait Java de lire la premiere cle.
    $chemin = $keystore -replace '\\', '/'
    @(
        "storePassword=$s",
        "keyPassword=$k",
        "keyAlias=abcduweb",
        "storeFile=$chemin"
    ) | Set-Content -Path $kp -Encoding ASCII
    Write-Host "      key.properties cree." -ForegroundColor Green
}

$res = "$projet\android\app\src\main\res"
foreach ($d in @("mipmap-mdpi","mipmap-hdpi","mipmap-xhdpi","mipmap-xxhdpi","mipmap-xxxhdpi","mipmap-anydpi-v26","values")) {
    $src = "$stage\icones\android\$d"
    if (-not (Test-Path $src)) { $src = "$source\icones\android\$d" }
    if (Test-Path $src) {
        if (-not (Test-Path "$res\$d")) { New-Item -ItemType Directory -Path "$res\$d" -Force | Out-Null }
        Copy-Item "$src\*" "$res\$d" -Force
    }
}

# --- 7. Dependances --------------------------------------------------

Write-Host "[7/7] Dependances..."
Push-Location $projet
& flutter pub get
$code = $LASTEXITCODE
Pop-Location
if ($code -ne 0) {
    Write-Host "flutter pub get a echoue. Code intact dans $stage" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Projet reconstruit ===" -ForegroundColor Green
Write-Host "Copie de securite conservee : $stage" -ForegroundColor Gray
Write-Host ""
Write-Host "Generer le fichier pour Play Store :"
Write-Host "   cd C:\abc_carburant"
Write-Host "   flutter build appbundle --release"
Write-Host ""
Write-Host "Puis verifier la signature AVANT de televerser :"
Write-Host "   cd C:\abc_carburant\publication"
Write-Host "   powershell -ExecutionPolicy Bypass -File verifier_signature.ps1"
Write-Host ""
