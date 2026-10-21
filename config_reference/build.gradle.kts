// =====================================================================
//  ABC Carburant - android/app/build.gradle.kts
//  Version complete, signature de release incluse.
//
//  Ce fichier est une REFERENCE. Le votre a ete genere par
//  "flutter create" et peut differer selon votre version de Flutter :
//  comparez plutot que d'ecraser aveuglement, ou utilisez le script
//  patch_signature.ps1 qui applique les modifications une par une.
// =====================================================================

@file:Suppress("DEPRECATION", "DEPRECATION_ERROR")
// AGP 9 transforme en ERREURS de compilation du script les
// depreciations de "android { }" et de "kotlinOptions". L'ancien DSL
// reste parfaitement fonctionnel a l'execution : cette annotation
// autorise explicitement son usage. A revoir pour AGP 10, qui le
// supprimera pour de bon.
// (android.newDsl=false dans gradle.properties NE suffit pas : ce
// drapeau agit a l'execution, pas a la compilation du script.)

import java.util.Properties
import java.io.FileInputStream

// Lecture de android/key.properties (jamais versionne : il contient
// le mot de passe du keystore).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.abcduweb.abc_carburant"
    compileSdk = flutter.compileSdkVersion

    // Version imposee par les plugins (flutter_local_notifications,
    // geolocator, sqflite...). Laisser flutter.ndkVersion provoque un
    // conflit de versions au build.
    ndkVersion = "28.2.13676358"

    compileOptions {
        // Requis par flutter_local_notifications : sans cette ligne le
        // build echoue sur "requires core library desugaring".
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.abcduweb.abc_carburant"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // DESACTIVEES VOLONTAIREMENT (21/10/2026).
            // Avec R8 actif, l'application s'installait mais restait
            // bloquee sur l'ecran de demarrage : le premier appel de
            // plugin echouait dans un callback asynchrone, sans message.
            // Les reactiver exige des regles de conservation, notamment
            // pour flutter_local_notifications qui passe par Gson et
            // donc par la reflexion. Le gain n'est que de quelques Mo.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
