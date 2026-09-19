# 4 — Formulaire « Sécurité des données »

Play Console → **Règles** → **Contenu de l'application** →
**Sécurité des données**.

Réponses exactes pour ABC Carburant. Une déclaration inexacte expose à
une suspension de l'application, y compris rétroactivement : renseignez
ce formulaire à nouveau si vous ajoutez un jour de la publicité ou un
outil de mesure d'audience.

---

## Étape 1 — Collecte et partage

> **Votre application collecte-t-elle ou partage-t-elle l'un des types
> de données utilisateur requis ?**

**OUI**

La position est *utilisée*, même sans être conservée : Google considère
cela comme une collecte. Répondre « non » serait une fausse
déclaration.

> **Toutes les données sont-elles chiffrées en transit ?**

**OUI** — tous les appels (API gouvernementale, OpenStreetMap,
Nominatim, OSRM) passent par HTTPS.

> **Proposez-vous un moyen de demander la suppression des données ?**

**NON**, et sélectionner le motif : aucune donnée n'est conservée sur
un serveur. Les données locales disparaissent à la désinstallation.

---

## Étape 2 — Types de données

Une seule catégorie à cocher.

### Position → Position exacte

| Question | Réponse |
|----------|---------|
| Collectée | **Oui** |
| Partagée | **Non** |
| Traitée de façon éphémère | **Oui** |
| Obligatoire | **Non** — la recherche par commune fonctionne sans |
| Finalité | **Fonctionnalité de l'application** uniquement |

« Traitée de façon éphémère » est le point clé : la position sert au
calcul en cours et n'est jamais écrite sur disque ni envoyée.

### Ne rien cocher d'autre

Aucune de ces catégories ne s'applique :

- Informations personnelles — aucun compte, aucun nom, aucun e-mail
- Informations financières — aucun paiement
- Messages, photos, fichiers, contacts, calendrier
- **Identifiants** — aucun identifiant publicitaire ni d'appareil
- **Activité dans l'application** — aucune analyse d'audience
- Historique de navigation, informations de santé, contenus audio

### Cas des favoris et réglages

Ils sont stockés uniquement sur l'appareil et ne remontent nulle part.
Google ne demande de les déclarer que s'ils transitent hors du
téléphone. **Ne les déclarez pas.**

---

## Étape 3 — Autres déclarations liées

### Contenu de l'application → Publicités

**Non, mon application ne contient pas de publicité.**

### Contenu de l'application → Classification du contenu

Questionnaire IARC. Réponses : **non** à tout — pas de violence, pas de
contenu sexuel, pas de jeu d'argent, pas de contenu généré par les
utilisateurs, pas de partage de position entre utilisateurs.

Classification obtenue : **Tout public / PEGI 3**.

### Contenu de l'application → Public cible

**18 ans et plus** — ou 13 ans et plus. Évitez de cocher les tranches
d'âge enfants : cela déclencherait des obligations supplémentaires
(Families Policy) sans rapport avec une application de carburants.

### Contenu de l'application → Application d'actualités

**Non**.

### Autorisations sensibles

L'application ne demande **aucune** autorisation de la liste sensible
(SMS, journal d'appels, localisation en arrière-plan). La position
n'est demandée qu'au premier plan — aucune déclaration supplémentaire
n'est requise.

---

## Étape 4 — URL de la politique de confidentialité

Champ obligatoire, à renseigner dans **Fiche du store principale** :

```
https://abcduweb.fr/politique-de-confidentialite-abc-carburant/
```

Publiez d'abord la page avec `2_confidentialite.html`, puis vérifiez
que l'URL s'ouvre en navigation privée : Google la contrôle
automatiquement, et une page en brouillon fait rejeter la soumission.

---

## Vérification finale

Une fois tout rempli, Play Console affiche un récapitulatif public.
Relisez-le : c'est exactement ce que verront vos utilisateurs dans la
section « Sécurité des données » de la fiche.

Vous devriez y lire, en substance : aucune donnée partagée avec des
tiers, aucune donnée collectée, données chiffrées en transit. C'est un
argument commercial réel face aux concurrents bardés de traceurs
publicitaires — mettez-le en avant dans votre description.
