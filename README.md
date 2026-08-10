# ABC Carburant

Comparateur de prix des carburants en France, en temps réel.
Développé par **ABCduWeb** — Beauvallon, Drôme-Ardèche — contact@abcduweb.fr

---

## Ce que contient ce paquet

```
lib/                      code source Dart complet
assets/images/            logo ABCduWeb (fond transparent)
pubspec.yaml              dépendances et déclaration des assets
icones/                   jeu d'icônes Android + iOS + sources SVG
config_reference/         AndroidManifest.xml + correctif build.gradle
```

**Ce paquet ne contient pas les dossiers `android/` et `ios/`.**
Ils sont générés par Flutter sur votre machine et contiennent des chemins
absolus propres à votre poste. Voir l'installation ci-dessous.

---

## Installation sur un projet existant

Si vous avez déjà `C:\abc_carburant` fonctionnel :

```powershell
cd C:\abc_carburant
Remove-Item lib -Recurse -Force
Expand-Archive -Path chemin\vers\abc_carburant_complet.zip -DestinationPath . -Force
flutter pub get
flutter build apk --release
```

Puis appliquer les icônes (section plus bas).

---

## Installation depuis zéro

```powershell
# 1. Créer le squelette Flutter
flutter create --org com.abcduweb --project-name abc_carburant abc_carburant
cd abc_carburant

# 2. Écraser lib/, assets/ et pubspec.yaml avec ceux de ce paquet
Remove-Item lib -Recurse -Force
#    puis décompresser le paquet ici

# 3. Remplacer android\app\src\main\AndroidManifest.xml
#    par config_reference\AndroidManifest.xml
#    et y coller votre clé Google Maps

# 4. Compiler
flutter pub get
flutter build apk --release
```

L'APK est produit dans `build\app\outputs\flutter-apk\app-release.apk`.

---

## Icônes

**Android** — trois copies vers `android\app\src\main\res\` :

| Depuis | Vers |
|---|---|
| `icones/android/mipmap-*` | `res\` (écraser) |
| `icones/android/mipmap-anydpi-v26/ic_launcher.xml` | `res\mipmap-anydpi-v26\` |
| `icones/android/values/ic_launcher_background.xml` | `res\values\` |

Si un `colors.xml` existe déjà dans `values\`, ajoutez-y la ligne `<color>`
plutôt que de déposer un second fichier : deux fichiers déclarant la même
ressource font échouer le build.

Puis `flutter clean` avant de recompiler — Gradle met les ressources en
cache et conserverait sinon l'ancienne icône.

**iOS** — glisser `icones/icon_1024.png` dans Xcode (App Icons Source),
qui régénère toutes les tailles. Les fichiers de `icones/ios/` sont fournis
pour un remplacement manuel dans `AppIcon.appiconset`.

---

## Fond de carte

La carte utilise **OpenStreetMap** via `flutter_map`. Aucune clé API,
aucun compte, aucune facturation. La balise `<meta-data>` Google Maps
dans le manifeste n'est plus utilisée et peut être supprimée.

L'attribution « OpenStreetMap contributors » affichée sur la carte est
**obligatoire** au titre de la licence ODbL : ne la retirez pas.

Le serveur de tuiles public d'OSM est soumis à une politique d'usage
raisonnable. Il convient pour un usage personnel ou une audience modeste.
Au-delà de quelques milliers d'utilisateurs quotidiens, il faut passer
par un fournisseur de tuiles (MapTiler, Stadia Maps, Thunderforest) —
il suffit alors de changer l'`urlTemplate` dans `map_screen.dart`.

---

## Architecture

```
lib/
├── main.dart                       point d'entrée, thème, Provider
├── theme/app_theme.dart            charte ABCduWeb centralisée
├── models/station.dart             modèle station + parsing API
├── services/
│   ├── fuel_api_service.dart       appels data.economie.gouv.fr
│   ├── location_service.dart       géolocalisation
│   └── navigation_service.dart     ouverture Google Maps / Waze
├── providers/fuel_provider.dart    état : stations, filtres, rayon
├── utils/date_formatter.dart       dates en français
├── services/
│   ├── favorites_service.dart      favoris persistants
│   ├── savings_service.dart        véhicule + calcul du gain net
│   ├── routing_service.dart        géocodage Nominatim + itinéraire OSRM
│   └── alerts_service.dart         alertes de prix + tâche de fond
├── screens/
│   ├── home_screen.dart            liste
│   ├── map_screen.dart             carte OSM + marqueurs prix
│   ├── location_intro_screen.dart  explication avant demande GPS
│   ├── trip_screen.dart            stations le long d'un trajet
│   ├── settings_screen.dart        véhicule et alertes
│   └── about_screen.dart           crédits
└── widgets/                        fiche station, filtres, recherche,
                                    écrans d'erreur
```

**Charte graphique** — vert `#8AB734`, anthracite `#4D4844`, relevés sur le
logo officiel. Tout est centralisé dans `theme/app_theme.dart` : une seule
constante à modifier pour changer la couleur dans toute l'application.

---

## Source des données

API publique du Ministère de l'Économie, sans clé ni quota :

```
https://data.economie.gouv.fr/api/explore/v2.1/catalog/datasets/
prix-des-carburants-en-france-flux-instantane-v2/records
```

Mise à jour toutes les 10 minutes.

**Limite connue** : l'API renvoie au maximum 100 stations par requête. À
100 km autour d'une grande ville, ce plafond est atteint et les stations
les plus lointaines n'apparaissent pas. Le tri par distance est appliqué
côté serveur, donc ce sont bien les 100 plus proches qui remontent. Pour
lever cette limite, il faudra paginer avec le paramètre `offset`.

---

## Fonctionnalités

- Géolocalisation GPS et recherche par commune ou code postal
- Rayon de recherche réglable : 5, 10, 20, 50 ou 100 km
- Filtre par carburant : Gazole, E10, SP95, SP98, E85, GPLc
- Tri par distance ou par prix
- Carte OpenStreetMap, prix affiché directement sur chaque marqueur,
  coloré du vert au rouge selon son niveau
- Favoris persistants, préférences mémorisées entre deux lancements
- Signalement des relevés de plus de 5 jours
- Itinéraire vers Google Maps ou Waze
- Écran d'explication avant la demande de permission GPS
- Écrans d'erreur avec action adaptée (réglages, réessai, recherche
  manuelle) selon la cause réelle
- **Gain net** : économie sur le plein moins le carburant du détour,
  calculée à partir du réservoir et de la consommation du véhicule.
  Tri des stations par gain net disponible.
- **Mode trajet** : stations le long d'un itinéraire A → B, en liste ou
  sur carte, avec repérage de la moins chère
- **Alertes de prix** : notification quand un carburant passe sous un
  seuil, vérification périodique en arrière-plan

---

## Limites à connaître

**Alertes.** La vérification a lieu à l'ouverture de l'application, au
plus une fois par heure. Il n'y a pas de tâche de fond : le plugin
`workmanager` a été retiré, sa version compatible avec les Flutter
récents utilisant encore le Kotlin Gradle Plugin, que Flutter s'apprête
à interdire. Android bride de toute façon fortement les tâches de fond,
au point qu'une périodicité de 6 h n'aurait rien garanti. L'application
l'indique clairement dans les réglages plutôt que de promettre des
notifications qu'elle ne peut pas tenir.

Pour de vraies notifications sans ouverture de l'app, la solution
robuste est un serveur qui surveille les prix et envoie des messages
push (Firebase Cloud Messaging) — à envisager si un client le finance.

**Mode trajet.** Le géocodage utilise Nominatim et l'itinéraire OSRM,
deux services publics gratuits soumis à une politique d'usage
raisonnable. Ils conviennent à un usage individuel ou à une audience
modeste. Pour une diffusion large, il faut passer à une offre payante
(Mapbox, Stadia, ou une instance OSRM auto-hébergée) — seules les URL
dans `routing_service.dart` changent.

Le trajet est échantillonné en 10 points, chacun donnant lieu à une
requête dans un rayon de 6 km. Un trajet très long peut donc laisser
des trous entre deux points d'échantillonnage : augmenter `maxPoints`
améliore la couverture au prix du temps de réponse.

**Gain net.** Le calcul compare chaque station à la plus proche vendant
le même carburant, et compte le détour aller-retour. C'est une
approximation : il ignore le trajet réel et suppose un plein complet.

---

## Publication

Le dossier `publication/` regroupe tout ce qui bloque la mise en ligne :

| Fichier | Rôle |
|---|---|
| `CHECKLIST.md` | marche à suivre complète, dans l'ordre |
| `creer_keystore.ps1` | crée le keystore et `key.properties` |
| `1_KEYSTORE.md` | signature Gradle, sauvegarde, génération de l'AAB |
| `2_confidentialite.html` | page prête à coller dans WordPress |
| `3_CAPTURES.md` | quels écrans capturer et comment |
| `encadrer_captures.py` | habille vos captures aux couleurs ABCduWeb |
| `4_SECURITE_DONNEES.md` | réponses exactes du formulaire Google |

Le dossier `play_store/` contient les textes de la fiche et le bandeau
1024×500.

---

## Pistes d'évolution

- Historique et alertes de baisse de prix
- Pagination au-delà de 100 stations
- Filtre sur les services (station 24/24, boutique, lavage)
- Tests unitaires sur le parsing de l'API

---

© 2026 ABCduWeb — https://www.abcduweb.fr
