# 3 — Captures d'écran

Google Play exige **2 captures minimum**, 8 maximum. En pratique, ce
sont elles qui décident du téléchargement : la plupart des visiteurs ne
lisent pas la description.

---

## 1. Prendre les captures

Sur votre téléphone, dans l'application, appuyez simultanément sur
**Volume bas + Marche/Arrêt**.

Six écrans à capturer, dans cet ordre :

| N° | Écran | Ce qu'il faut y voir |
|----|-------|----------------------|
| 1 | Liste des stations | plusieurs stations avec leurs prix visibles |
| 2 | Filtres carburant | la barre de carburants et le rayon |
| 3 | Carte | les marqueurs de prix colorés, bien répartis |
| 4 | Fiche station dépliée | **le bandeau de gain net** — c'est votre argument le plus fort |
| 5 | Mode trajet | un trajet calculé, avec les stations dessus |
| 6 | Liste filtrée sur les favoris | quelques cœurs remplis |

**Trois erreurs à éviter.** Une liste vide ou en cours de chargement.
Un écran d'erreur. Une notification personnelle visible dans la barre
d'état — activez le mode « Ne pas déranger » avant de commencer.

Prenez-les de jour, avec des prix récents : une capture montrant
« Mis à jour il y a 3 semaines » donne une mauvaise impression.

---

## 2. Transférer sur le PC

Téléphone en USB, mode **Transfert de fichiers**, puis copiez les
images depuis `Pictures\Screenshots` vers :

```
C:\abc_carburant\publication\captures_brutes\
```

Renommez-les `1.png`, `2.png`, `3.png`… dans l'ordre du tableau
ci-dessus : le script associe chaque numéro à son titre.

---

## 3. Habiller les captures

```powershell
cd C:\abc_carburant\publication
pip install pillow
python encadrer_captures.py
```

Chaque capture est placée sur un fond vert ABCduWeb, surmontée de son
titre, et exportée en 1080×1920 — le format attendu par le Play Store.

Résultat dans `captures_play_store\`.

Pour changer les titres, modifiez la liste `TITRES` en haut du script.
Gardez-les courts : au-delà de quatre mots, le texte passe sur deux
lignes et mange l'espace de la capture.

---

## 4. Téléverser

Play Console → **Fiche du store principale** → Éléments graphiques →
Captures d'écran pour téléphone.

Ajoutez-les dans l'ordre : la première est celle que voient les
visiteurs sans faire défiler. Mettez en tête la liste des prix, qui
montre immédiatement à quoi sert l'application.

---

## 5. Autres éléments graphiques de la fiche

| Élément | Format | Où le trouver |
|---------|--------|---------------|
| Icône | 512×512 PNG | `icones/icon_1024.png`, à redimensionner |
| Bandeau | 1024×500 PNG | `play_store/feature_graphic.png` |

Le bandeau est obligatoire. Il s'affiche en tête de fiche et dans les
sélections éditoriales.
