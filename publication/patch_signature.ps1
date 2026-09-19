# =====================================================================
#  ABC Carburant - application de la signature de release
#
#  Modifie android/app/build.gradle.kts pour signer avec votre keystore
#  au lieu de la cle de debug (refusee par Google Play).
#
#  Prerequis : android/key.properties doit exister
#              (le cree : publication\creer_keystore.ps1)
#
#  Usage :
#     powershell -ExecutionPolicy Bypass -File patch_signature.ps1
# =====================================================================

$ErrorActionPreference = "Stop"

$projet  = "C:\abc_carburant"
$gradle  = "$projet\android\app\build.gradle.kts"
$keyprop = "$projet\android\key.properties"

Write-Host ""
Write-Host "=== Signature de release ===" -ForegroundColor Green
Write-Host ""

# --- Verifications -------------------------------------------------

if (-not (Test-Path $gradle)) {
    Write-Host "Introuvable : $gradle" -ForegroundColor Red
    Write-Host "Le projet Android n'existe pas. Lancez d'abord flutter create."
    exit 1
}

if (-not (Test-Path $keyprop)) {
    Write-Host "Introuvable : $keyprop" -ForegroundColor Red
    Write-Host ""
    Write-Host "Le keystore n'a pas encore ete cree. Lancez d'abord :" -ForegroundColor Yellow
    Write-Host "   cd $projet\publication"
    Write-Host "   powershell -ExecutionPolicy Bypass -File creer_keystore.ps1"
    exit 1
}

Copy-Item $gradle "$gradle.bak" -Force
Write-Host "Sauvegarde : build.gradle.kts.bak" -ForegroundColor Gray

$c = Get-Content $gradle -Raw
$modifs = 0

# --- 1. Import et lecture de key.properties ------------------------

if ($c -notmatch "keystoreProperties") {
    $entete = @"
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

"@
    # Insere avant le bloc plugins, en tete de fichier
    if ($c -match "(?m)^plugins\s*\{") {
        $c = $c -replace "(?m)^plugins\s*\{", "$entete`plugins {"
    } else {
        $c = $entete + $c
    }
    $modifs++
    Write-Host "  + lecture de key.properties" -ForegroundColor Green
}

# --- 2. Bloc signingConfigs ----------------------------------------

if ($c -notmatch "signingConfigs\s*\{") {
    $bloc = @"
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

"@
    if ($c -match "(?m)^\s*buildTypes\s*\{") {
        $c = $c -replace "(?m)^(\s*)buildTypes\s*\{", "$bloc`$1buildTypes {"
        $modifs++
        Write-Host "  + bloc signingConfigs" -ForegroundColor Green
    } else {
        Write-Host "  ! bloc buildTypes introuvable : ajout manuel requis" -ForegroundColor Yellow
    }
}

# --- 3. Utiliser la config release ---------------------------------

if ($c -match "signingConfigs\.debug") {
    $c = $c -replace "signingConfig\s*=\s*signingConfigs\.debug",
                     'signingConfig = signingConfigs.getByName("release")'
    $modifs++
    Write-Host "  + signature release au lieu de debug" -ForegroundColor Green
}

# --- Ecriture ------------------------------------------------------

if ($modifs -eq 0) {
    Write-Host ""
    Write-Host "Aucune modification necessaire : le fichier semble deja configure." -ForegroundColor Yellow
} else {
    Set-Content $gradle $c -NoNewline
    Write-Host ""
    Write-Host "$modifs modification(s) appliquee(s)." -ForegroundColor Green
}

# --- Verification --------------------------------------------------

Write-Host ""
Write-Host "=== Verification ===" -ForegroundColor Cyan
$ok = $true
foreach ($motif in @("keystoreProperties", "signingConfigs", 'getByName\("release"\)')) {
    if (Select-String -Path $gradle -Pattern $motif -Quiet) {
        Write-Host "  OK   $motif" -ForegroundColor Green
    } else {
        Write-Host "  MANQUE $motif" -ForegroundColor Red
        $ok = $false
    }
}

if (Select-String -Path $gradle -Pattern "signingConfigs\.debug" -Quiet) {
    Write-Host "  ATTENTION : signingConfigs.debug encore present" -ForegroundColor Red
    $ok = $false
}

Write-Host ""
if ($ok) {
    Write-Host "Pret. Generez le bundle :" -ForegroundColor Green
    Write-Host "   cd $projet"
    Write-Host "   flutter build appbundle --release"
    Write-Host ""
    Write-Host "Puis verifiez la signature :" -ForegroundColor Gray
    Write-Host "   powershell -ExecutionPolicy Bypass -File verifier_signature.ps1"
} else {
    Write-Host "Modification incomplete. Comparez avec :" -ForegroundColor Yellow
    Write-Host "   config_reference\build.gradle.kts"
    Write-Host "Restauration si besoin : $gradle.bak"
}
Write-Host ""
