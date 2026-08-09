# Correctif à appliquer dans `android/app/build.gradle(.kts)`

Deux erreurs de build viennent d'ici. Les corriger demande trois ajouts.

---

## 1. Activer le desugaring (obligatoire pour les notifications)

Erreur concernée :
```
Dependency ':flutter_local_notifications' requires core library desugaring
```

Dans le bloc `compileOptions`, ajouter la première ligne :

**Syntaxe Kotlin (`build.gradle.kts`)** — noter le préfixe `is`, absent
de la syntaxe Groovy : c'est la source d'erreur la plus fréquente.
```kotlin
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }
```

**Syntaxe Groovy (`build.gradle`)**
```groovy
    compileOptions {
        coreLibraryDesugaringEnabled true
        sourceCompatibility JavaVersion.VERSION_11
        targetCompatibility JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = '11'
    }
```

---

## 2. Ajouter la bibliothèque de desugaring

**Tout en bas du fichier**, en dehors du bloc `android { }` :

**Kotlin**
```kotlin
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

**Groovy**
```groovy
dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'
}
```

Si un bloc `dependencies { }` existe déjà, ajoutez-y seulement la ligne.

---

## 3. Relever le minSdk

`flutter_local_notifications` et `workmanager` ne descendent pas sous
l'API 23. Dans `defaultConfig` :

```
minSdk = 23        // Kotlin
minSdkVersion 23   // Groovy
```

Cela exclut Android 5.0 et 5.1, soit une part de marché résiduelle.

---

## Puis

```powershell
cd C:\abc_carburant
flutter clean
flutter pub get
flutter build apk --release
```

Le fichier `build.gradle.kts` de ce dossier est un exemple complet et
correct — utile pour comparer, mais ne l'écrasez pas aveuglément sur le
vôtre : `flutter create` a pu générer une structure légèrement
différente selon votre version de Flutter.
