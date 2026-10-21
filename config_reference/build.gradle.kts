// =====================================================================
//  ABC Carburant - android/app/build.gradle.kts
//  Version complete, signature de release incluse.
// =====================================================================

@file:Suppress("DEPRECATION", "DEPRECATION_ERROR")
// AGP 9 transforme en ERREURS de compilation du script les
// depreciations de "android { }" et de "kotlinOptions". L'ancien DSL
// reste fonctionnel a l'execution : cette annotation autorise
// explicitement son usage. A revoir pour AGP 10, qui le supprimera.
// (android.newDsl=false NE suffit pas : ce drapeau agit a l'execution,
// pas a la compilation du script.)

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
    // geolocator, sqflite...). flutter.ndkVersion provoque un conflit.
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