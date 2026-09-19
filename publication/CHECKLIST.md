# Publication sur Google Play — marche à suivre

Quatre points bloquants, dans l'ordre. Comptez une demi-journée au
total, plus le délai de revue de Google.

---

## A. Keystore de release · 20 min

```powershell
cd C:\abc_carburant\publication
powershell -ExecutionPolicy Bypass -File creer_keystore.ps1
```

Puis appliquer la signature :

```powershell
powershell -ExecutionPolicy Bypass -File patch_signature.ps1
cd C:\abc_carburant
flutter build appbundle --release
```

Et **vérifier avant d'envoyer quoi que ce soit** :

```powershell
cd C:\abc_carburant\publication
powershell -ExecutionPolicy Bypass -File verifier_signature.ps1
```

- [ ] Keystore créé
- [ ] **Fichier `.jks` et mot de passe sauvegardés hors de la machine**
- [ ] `patch_signature.ps1` exécuté sans erreur
- [ ] `flutter build appbundle --release` réussi
- [ ] `verifier_signature.ps1` confirme une signature de release

> Sans cette sauvegarde, une panne de disque vous interdit à jamais de
> mettre à jour l'application publiée.

---

## B. Politique de confidentialité · 15 min

Sur abcduweb.fr, créer une page WordPress :

- Titre : *Politique de confidentialité — ABC Carburant*
- Permalien : `/politique-de-confidentialite-abc-carburant/`
- Contenu : bloc **HTML personnalisé**, y coller `2_confidentialite.html`
- **Publier** (pas laisser en brouillon)

- [ ] Page en ligne
- [ ] URL vérifiée en navigation privée
- [ ] URL renseignée dans la fiche Play Store

---

## C. Captures d'écran · 45 min

Voir **3_CAPTURES.md** pour la liste des six écrans à capturer.

```powershell
cd C:\abc_carburant\publication
pip install pillow
python encadrer_captures.py
```

- [ ] 6 captures prises, mode « Ne pas déranger » activé
- [ ] Renommées 1.png à 6.png dans `captures_brutes\`
- [ ] Script exécuté, résultat vérifié
- [ ] Téléversées dans Play Console
- [ ] Icône 512×512 et bandeau 1024×500 téléversés

---

## D. Formulaire Sécurité des données · 20 min

Réponses exactes dans **4_SECURITE_DONNEES.md**.

- [ ] Sécurité des données rempli
- [ ] Classification du contenu obtenue
- [ ] Public cible défini
- [ ] Publicités : déclaré « aucune »

---

## E. Compte et première soumission

- [ ] Compte développeur Google Play créé — 25 € une fois
- [ ] Identité vérifiée (Google demande une pièce d'identité, comptez
      quelques jours)
- [ ] Textes de la fiche copiés depuis `play_store/FICHE_PLAY_STORE.md`
- [ ] AAB téléversé sur un **canal de test interne d'abord**
- [ ] Application installée depuis le test interne et vérifiée sur un
      vrai téléphone
- [ ] Passage en production

> Le test interne est disponible en quelques minutes, sans attendre la
> revue complète. Il sert surtout à vérifier que la version resignée
> par Google fonctionne — c'est là que les surprises apparaissent.

---

## Ordre recommandé

1. **B** (politique de confidentialité) — elle peut être publiée tout
   de suite et ne dépend de rien
2. **E** (création du compte) — la vérification d'identité prend
   plusieurs jours, lancez-la au plus tôt
3. **A** (keystore) puis génération de l'AAB
4. **C** (captures) sur l'application compilée
5. **D** (formulaires) une fois dans la console

Les étapes B et E n'attendent rien : commencez par elles aujourd'hui.
