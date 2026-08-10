"""
Habillage des captures d'ecran pour Google Play.

Prend vos captures brutes, les place sur un fond aux couleurs ABCduWeb
avec un titre, et exporte aux dimensions attendues par le Play Store.

UTILISATION
-----------
1. Transferer vos captures depuis le telephone vers un dossier, par
   exemple C:\\abc_carburant\\publication\\captures_brutes\\
2. Les renommer 1.png, 2.png, 3.png... dans l'ordre d'affichage
3. Adapter la liste TITRES ci-dessous (un titre par capture)
4. Lancer :

       pip install pillow
       python encadrer_captures.py

Les fichiers habilles sortent dans captures_play_store/.
"""

import os
import sys

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    sys.exit("Pillow manquant.  Installez-le :  pip install pillow")

# --- Reglages --------------------------------------------------------

DOSSIER_ENTREE = "captures_brutes"
DOSSIER_SORTIE = "captures_play_store"

VERT = (138, 183, 52)
VERT_FONCE = (111, 148, 41)
BLANC = (255, 255, 255)

# Un titre par capture, dans l'ordre 1.png, 2.png, ...
TITRES = [
    "Les prix autour de vous",
    "Tous les carburants",
    "Sur la carte",
    "Votre gain reel",
    "Sur votre trajet",
    "Vos stations favorites",
]

LARGEUR = 1080
HAUTEUR = 1920
MARGE_HAUT = 260          # bandeau de titre
MARGE_COTE = 70


def police(taille, gras=True):
    """Cherche une police systeme, quelle que soit la plateforme."""
    candidats = [
        "C:/Windows/Fonts/segoeuib.ttf" if gras else "C:/Windows/Fonts/segoeui.ttf",
        "C:/Windows/Fonts/arialbd.ttf" if gras else "C:/Windows/Fonts/arial.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if gras
        else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    for c in candidats:
        if os.path.exists(c):
            try:
                return ImageFont.truetype(c, taille)
            except Exception:
                pass
    return ImageFont.load_default()


def degrade(largeur, hauteur, haut, bas):
    img = Image.new("RGB", (largeur, hauteur), haut)
    d = ImageDraw.Draw(img)
    for y in range(hauteur):
        r = y / max(hauteur - 1, 1)
        d.line(
            [(0, y), (largeur, y)],
            fill=(
                int(haut[0] + (bas[0] - haut[0]) * r),
                int(haut[1] + (bas[1] - haut[1]) * r),
                int(haut[2] + (bas[2] - haut[2]) * r),
            ),
        )
    return img


def coins_arrondis(img, rayon):
    masque = Image.new("L", img.size, 0)
    ImageDraw.Draw(masque).rounded_rectangle(
        [(0, 0), (img.size[0] - 1, img.size[1] - 1)], rayon, fill=255
    )
    sortie = img.convert("RGBA")
    sortie.putalpha(masque)
    return sortie


def habiller(chemin, titre, destination):
    capture = Image.open(chemin).convert("RGB")

    fond = degrade(LARGEUR, HAUTEUR, VERT, VERT_FONCE)
    dessin = ImageDraw.Draw(fond)

    # Titre, coupe en deux lignes si necessaire
    f = police(58)
    mots = titre.split()
    lignes, courante = [], ""
    for mot in mots:
        essai = (courante + " " + mot).strip()
        if dessin.textlength(essai, font=f) < LARGEUR - 2 * MARGE_COTE:
            courante = essai
        else:
            lignes.append(courante)
            courante = mot
    lignes.append(courante)

    y = 80
    for ligne in lignes:
        w = dessin.textlength(ligne, font=f)
        dessin.text(((LARGEUR - w) / 2, y), ligne, font=f, fill=BLANC)
        y += 70

    # Capture redimensionnee dans l'espace restant
    dispo_h = HAUTEUR - MARGE_HAUT - 60
    dispo_l = LARGEUR - 2 * MARGE_COTE
    ratio = min(dispo_l / capture.width, dispo_h / capture.height)
    nouvelle = capture.resize(
        (int(capture.width * ratio), int(capture.height * ratio)), Image.LANCZOS
    )
    nouvelle = coins_arrondis(nouvelle, 28)

    x = (LARGEUR - nouvelle.width) // 2
    fond.paste(nouvelle, (x, MARGE_HAUT), nouvelle)

    fond.save(destination, "PNG", optimize=True)
    print(f"  {os.path.basename(destination)}  ({titre})")


def main():
    if not os.path.isdir(DOSSIER_ENTREE):
        os.makedirs(DOSSIER_ENTREE, exist_ok=True)
        sys.exit(
            f"Dossier '{DOSSIER_ENTREE}' cree.\n"
            "Placez-y vos captures nommees 1.png, 2.png... puis relancez."
        )

    fichiers = sorted(
        f for f in os.listdir(DOSSIER_ENTREE)
        if f.lower().endswith((".png", ".jpg", ".jpeg"))
    )
    if not fichiers:
        sys.exit(f"Aucune image dans '{DOSSIER_ENTREE}'.")

    os.makedirs(DOSSIER_SORTIE, exist_ok=True)
    print(f"\n{len(fichiers)} capture(s) a habiller :\n")

    for i, nom in enumerate(fichiers):
        titre = TITRES[i] if i < len(TITRES) else "ABC Carburant"
        habiller(
            os.path.join(DOSSIER_ENTREE, nom),
            titre,
            os.path.join(DOSSIER_SORTIE, f"play_{i + 1:02d}.png"),
        )

    print(f"\nTermine. Fichiers prets dans '{DOSSIER_SORTIE}'.")
    print("Google Play en demande 2 minimum, 8 maximum.\n")


if __name__ == "__main__":
    main()
