# 5 — Correctif : « Déclarations trompeuses » (Google Play)

Google a rejeté la fiche avec ce motif :

> Absence de la clause de non-responsabilité indiquant clairement que
> l'appli n'est pas une appli officielle.

## Cause probable

L'écran « À propos » de l'application affichait la mention
**« 🏛️ Gouvernement Français »** au-dessus de la source des données.
Les scanners de Google Play l'ont interprétée comme une revendication
d'affiliation officielle — l'app n'expliquait nulle part qu'il s'agit
d'un usage indépendant de données publiques, pas d'un service d'État.

## Ce qui a été corrigé dans le code

**`lib/screens/about_screen.dart`** — deux changements :

1. Un bandeau orange, visible immédiatement sous le titre de l'écran
   « À propos » (donc sans action supplémentaire de l'utilisateur une
   fois l'écran ouvert), avec ce texte :

   > ABC Carburant est une application indépendante, éditée par
   > ABCduWeb. Elle n'est ni un service officiel ni un site du
   > gouvernement : elle affiche des données publiques mises à
   > disposition par l'État.

2. L'intitulé de la source de données, qui disait
   « 🏛️ Gouvernement Français », est devenu
   « 🏛️ Data.economie.gouv.fr », avec une description qui précise
   l'absence de lien officiel.

## Ce qui a été corrigé dans la fiche Play Store

`play_store/FICHE_PLAY_STORE.md` — la description commence désormais
par « ABC Carburant est une application indépendante éditée par
ABCduWeb, sans lien officiel avec l'État ni aucun organisme public »,
et le paragraphe de sources en bas de description précise que
l'application « n'est pas affiliée à cette administration et n'est
pas une application officielle ».

## À faire

1. Recompiler avec le `lib/` mis à jour :

   ```powershell
   cd C:\\abc_carburant
   flutter build appbundle --release
   ```

2. Mettre à jour le texte de la fiche Play Store avec la nouvelle
   description (copier-coller depuis `FICHE_PLAY_STORE.md`).

3. Retélécharger l'AAB et soumettre à nouveau. Les rejets pour ce motif
   sont généralement réexaminés en 24 à 48 h une fois le correctif
   appliqué.

## Pour éviter que ça se reproduise

Si vous déclinez l'application en marque blanche pour un client qui
utilise lui aussi une source de données publique (impôts, cadastre,
météo...), gardez ce réflexe : toute mention d'une administration dans
le contenu de l'app doit être accompagnée, au même endroit, d'une
précision d'indépendance. Une source citée sans cette précision est le
déclencheur le plus courant de ce motif de rejet.
