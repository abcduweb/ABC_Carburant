# 1 — Keystore de release et signature

Sans cette étape, Google Play refuse votre AAB : le projet est signé
avec la clé de debug, réservée aux tests.

---

## 1. Lancer le script

```powershell
cd C:\abc_carburant\publication
powershell -ExecutionPolicy Bypass -File creer_keystore.ps1
```

Il crée le keystore, écrit `android/key.properties`, l'ajoute au
`.gitignore` et affiche votre empreinte SHA-1.

---

## 2. Sauvegarder immédiatement

> Perdre le fichier `.jks` ou son mot de passe rend **définitivement
> impossible** toute mise à jour de l'application publiée. Google ne
> dispose d'aucune procédure de récupération. Il faudrait republier
> sous un nouvel identifiant, en perdant les installations et les avis.

Copiez dès maintenant, sur un support **hors de cette machine** :

- `C:\Users\<vous>\abcduweb-release.jks`
- le mot de passe (gestionnaire de mots de passe, coffre-fort)

Un disque qui lâche, un poste réinstallé, et l'application est perdue.

---

## 3. Configurer Gradle

**Le plus simple — script automatique :**

```powershell
cd C:\abc_carburant\publication
powershell -ExecutionPolicy Bypass -File patch_signature.ps1
```

Il sauvegarde votre fichier, applique les trois modifications, puis
vérifie le résultat. Si une étape ne passe pas, il le signale et vous
renvoie vers la version de référence.

**Ou à la main**, dans `android/app/build.gradle.kts`.

**Tout en haut du fichier**, avant le bloc `plugins { }` :

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

**Dans le bloc `android { }`**, avant `buildTypes` :

```kotlin
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
```

**Et remplacer** le contenu de `buildTypes` :

```kotlin
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
```

`isMinifyEnabled` et `isShrinkResources` réduisent nettement la taille
du paquet. Si le build échoue à cause d'eux, passez-les à `false` : ce
sont des optimisations, pas des obligations.

---

## 4. Générer le bundle

```powershell
cd C:\abc_carburant
flutter build appbundle --release
```

Résultat : `build\app\outputs\bundle\release\app-release.aab`

---

## 5. Vérifier la signature — avant tout envoi

```powershell
cd C:\abc_carburant\publication
powershell -ExecutionPolicy Bypass -File verifier_signature.ps1
```

Le script extrait le certificat du bundle et vous dit lequel a servi.

> Un AAB signé avec la clé de debug est **refusé par Play Console** :
> « Vous avez importé un APK ou un fichier Android App Bundle avec une
> signature en mode débogage. » C'est le symptôme d'un `signingConfigs`
> non appliqué — relancez `patch_signature.ps1`, puis regénérez le
> bundle.

---

## 6. Important : le SHA-1 change après publication

Google Play resigne votre application avec sa propre clé. L'empreinte
utile pour tout service tiers devient celle affichée dans
**Play Console → Configuration → Intégrité de l'application**, et non
celle de votre keystore.

Cela ne concerne pas ABC Carburant, qui n'utilise plus aucune clé API
depuis le passage à OpenStreetMap. À retenir si vous ajoutez un jour
Google Maps, Firebase ou une connexion Google.
