// =====================================================================
//  ABC Carburant — android/app/build.gradle.kts
//  Version complete, signature de release incluse.
//
//  Ce fichier est une REFERENCE. Le votre a ete genere par
//  "flutter create" et peut differer selon votre version de Flutter :
//  comparez plutot que d'ecraser aveuglement, ou utilisez le script
//  patch_signature.ps1 qui applique les modifications une par une.
// =====================================================================

@file:Suppress("DEPRECATION", "DEPRECATION_ERROR")

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
        minSdk = flutter.minSdkVersion
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
            // Passer a false si le build echoue sur la minification :
            // ce sont des optimisations de taille, pas des obligations.
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
