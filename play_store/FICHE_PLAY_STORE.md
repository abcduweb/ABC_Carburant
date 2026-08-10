# Fiche Google Play — ABC Carburant

Tous les textes à copier-coller dans la Play Console.

---

## Nom de l'application (30 caractères max)

```
ABC Carburant
```

## Description courte (80 caractères max)

```
Comparez les prix des carburants près de chez vous. Données officielles.
```
*(72 caractères)*

## Description complète (4000 caractères max)

```
ABC Carburant vous aide à trouver la station la moins chère autour de vous, en quelques secondes.

L'application s'appuie sur les données officielles du Ministère de l'Économie, mises à jour en continu par les stations elles-mêmes. Aucune estimation, aucun prix inventé : ce que vous voyez est ce que les stations ont déclaré.

■ LES PRIX AUTOUR DE VOUS
Localisez instantanément les stations proches et comparez leurs tarifs. Choisissez votre rayon de recherche : 5, 10, 20, 50 ou 100 km.

■ TOUS LES CARBURANTS
Gazole, SP95, SP98, E10, E85 et GPLc. Sélectionnez le vôtre : les prix affichés et le classement s'adaptent.

■ CARTE INTERACTIVE
Visualisez toutes les stations sur une carte, avec le prix affiché directement sur chaque repère. Un code couleur du vert au rouge repère immédiatement les meilleures affaires.

■ ITINÉRAIRE EN UN TOUCHER
Lancez la navigation vers la station de votre choix avec Google Maps ou Waze.

■ VOS STATIONS FAVORIES
Marquez vos stations habituelles pour les retrouver d'un geste.

■ FRAÎCHEUR DES DONNÉES
Chaque prix indique sa date de relevé. Les prix anciens sont signalés, pour éviter les mauvaises surprises à la pompe.

■ RESPECTUEUSE DE VOTRE VIE PRIVÉE
Aucun compte à créer. Aucune publicité. Aucun traceur. Votre position ne quitte jamais votre téléphone : elle sert uniquement à calculer les distances, localement.

■ RECHERCHE SANS GPS
Pas envie d'activer la localisation ? Cherchez par commune ou code postal.

---

Source des données : fichier public des prix des carburants, data.economie.gouv.fr
Fond de carte : OpenStreetMap et ses contributeurs

Application développée par ABCduWeb, agence web à Beauvallon (Drôme).
www.abcduweb.fr
```

---

## Catégorisation

| Champ | Valeur |
|---|---|
| Catégorie | Cartes et navigation |
| Tags | prix carburant, station essence, économie |
| Classification | Tout public |
| Contient des annonces | Non |
| Achats intégrés | Non |

---

## Formulaire « Sécurité des données »

Réponses exactes à saisir. Une déclaration inexacte expose à une
suspension de l'application.

**Collectez-vous ou partagez-vous des données utilisateur ?**
→ **Oui** (la localisation est *utilisée*, il faut la déclarer)

**Type : Position → Position exacte**
- Collectée : Oui
- Partagée : **Non**
- Traitée de façon éphémère : **Oui**
- Obligatoire : Non — l'utilisateur peut chercher par commune
- Finalité : **Fonctionnalité de l'application**

**Aucun autre type de donnée** : pas d'identifiants, pas de contacts,
pas de fichiers, pas de données d'utilisation.

**Les données sont-elles chiffrées en transit ?** → Oui (HTTPS)
**L'utilisateur peut-il demander la suppression ?** → Sans objet,
aucune donnée n'est conservée sur serveur.

---

## URL de la politique de confidentialité

Publier `POLITIQUE_CONFIDENTIALITE.md` sur votre site, par exemple :

```
https://www.abcduweb.fr/abc-carburant/confidentialite
```

Cette URL est **obligatoire** : sans elle, la fiche est rejetée.

---

## Ressources graphiques

| Élément | Format | Fichier |
|---|---|---|
| Icône | 512×512 PNG | `icones/icon_1024.png` (redimensionner) |
| Bandeau | 1024×500 PNG | `play_store/feature_graphic.png` |
| Captures téléphone | 2 min., 8 max. | à réaliser |

**Captures à faire** (sur votre téléphone, bouton volume bas + power) :
1. La liste des stations, avec les prix visibles
2. La carte avec les marqueurs de prix
3. Une fiche station dépliée
4. L'écran des favoris

---

## Avant publication — points bloquants

- [ ] Keystore de release créé et **sauvegardé hors de la machine**
- [ ] `key.properties` configuré, `build.gradle` modifié
- [ ] Politique de confidentialité en ligne, URL accessible
- [ ] Formulaire Sécurité des données rempli
- [ ] `flutter build appbundle --release` réussi
- [ ] AAB testé via un canal de test interne avant production

---

## Après publication

La première soumission passe par une revue de quelques jours. Prévoyez
un canal de **test interne** d'abord : il permet d'installer l'app sur
vos propres appareils sans attendre la validation complète, et de
vérifier que la version signée par Play fonctionne réellement.
