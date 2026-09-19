# =====================================================================
#  ABC Carburant - verification de la signature de l'AAB
#
#  A lancer AVANT de televerser sur Play Console : evite le rejet
#  "signature en mode debogage".
#
#  Usage :
#     powershell -ExecutionPolicy Bypass -File verifier_signature.ps1
#
#  NOTE : ce fichier est volontairement ecrit sans aucun caractere
#  accentue. PowerShell lit les .ps1 en ANSI par defaut sur Windows
#  francais, et les accents encodes en UTF-8 y cassent l'analyse du
#  script ("Le terminateur " est manquant dans la chaine").
# =====================================================================

$ErrorActionPreference = "Continue"

$projet = "C:\abc_carburant"
$aab    = "$projet\build\app\outputs\bundle\release\app-release.aab"

Write-Host ""
Write-Host "=== Verification de la signature ===" -ForegroundColor Green
Write-Host ""

if (-not (Test-Path $aab)) {
    Write-Host "AAB introuvable : $aab" -ForegroundColor Red
    Write-Host "Generez-le avec :  flutter build appbundle --release"
    exit 1
}

$info = Get-Item $aab
Write-Host "Fichier  : app-release.aab"
Write-Host "Taille   : $([math]::Round($info.Length / 1MB, 1)) Mo"
Write-Host "Genere   : $($info.LastWriteTime)"
Write-Host ""

# --- Localiser keytool ----------------------------------------------

$keytool = $null
$chemins = @(
    "$env:LOCALAPPDATA\Programs\Android Studio\jbr\bin\keytool.exe",
    "$env:ProgramFiles\Android\Android Studio\jbr\bin\keytool.exe"
)
foreach ($c in $chemins) {
    if (Test-Path $c) { $keytool = $c; break }
}
if (-not $keytool) {
    $cmd = Get-Command keytool.exe -ErrorAction SilentlyContinue
    if ($cmd) { $keytool = $cmd.Source }
}

# --- Extraire le certificat du bundle -------------------------------
# Expand-Archive refuse l'extension .aab : on copie en .zip d'abord.

$tmp = "$env:TEMP\aab_verif"
$zip = "$env:TEMP\aab_verif.zip"
if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
Remove-Item $zip -Force -ErrorAction SilentlyContinue

Copy-Item $aab $zip -Force
Expand-Archive $zip -DestinationPath $tmp -Force

$meta = Get-ChildItem "$tmp\META-INF" -ErrorAction SilentlyContinue
if (-not $meta) {
    Write-Host "AUCUNE SIGNATURE dans le bundle." -ForegroundColor Red
    Write-Host "Le fichier sera refuse par Play Console."
    exit 1
}

$cert = $meta | Where-Object { $_.Name -match "\.(RSA|DSA|EC)$" } | Select-Object -First 1
if (-not $cert) {
    Write-Host "Signature incomplete (aucun certificat)." -ForegroundColor Red
    exit 1
}

Write-Host "Certificat trouve : $($cert.Name)" -ForegroundColor Gray
Write-Host ""

if ($keytool) {
    $sortie = & $keytool -printcert -file $cert.FullName 2>&1 | Out-String

    if ($sortie -match "CN=Android Debug") {
        Write-Host "SIGNATURE DE DEBOGAGE" -ForegroundColor Red
        Write-Host ""
        Write-Host "Play Console refusera ce fichier." -ForegroundColor Red
        Write-Host "Appliquez la signature de release :"
        Write-Host "   powershell -ExecutionPolicy Bypass -File patch_signature.ps1"
        Write-Host "puis regenerez :  flutter build appbundle --release"
        Write-Host ""
        exit 1
    }

    if ($sortie -match "ABCduWeb") {
        Write-Host "SIGNATURE DE RELEASE - pret pour Play Console" -ForegroundColor Green
    } else {
        Write-Host "Signature presente, proprietaire non reconnu :" -ForegroundColor Yellow
    }

    Write-Host ""
    $sortie -split "`n" |
        Select-String -Pattern "Proprietaire|Owner|SHA1:|SHA256:" |
        ForEach-Object { Write-Host "  $($_.ToString().Trim())" -ForegroundColor Gray }
} else {
    Write-Host "keytool introuvable : verification limitee." -ForegroundColor Yellow
    Write-Host "Le bundle est signe, mais l'origine du certificat n'a pas pu"
    Write-Host "etre controlee."
}

Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $zip -Force -ErrorAction SilentlyContinue
Write-Host ""
