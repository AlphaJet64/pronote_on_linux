#!/bin/bash

# CONFIG
INSTALL_DIR="$HOME/.wine-pronote/drive_c/Program Files/Index Education/Client PRONOTE"
WINEPREFIX="$HOME/.wine-pronote"
WINEARCH=win64
WINETRICKS_MARKER="$WINEPREFIX/.pronote_win10_done"
PRONOTE_INSTALLER="pronote_install.exe" 

# Vérification commandes nécessaires
for cmd in wget wine winetricks; do
    if ! command -v $cmd &>/dev/null; then
        echo "❌ La commande '$cmd' est manquante."
        echo "Installation de Wine et Winetricks en cours..."
        if [ -f /etc/debian_version ]; then
            sudo dpkg --add-architecture i386
            sudo apt update
            sudo apt install -y wine64 wine32 winetricks winbind
        elif [ -f /etc/fedora-release ]; then
            sudo dnf install -y wine winetricks samba-winbind

        elif [ -f /etc/arch-release ]; then
            sudo pacman -Syu --noconfirm
            sudo pacman -S --noconfirm wine winetricks samba

        else
            echo "⚠ Système non pris en charge pour l'installation automatique."
            exit 1
        fi

        # Vérifier après install
        if ! command -v $cmd &>/dev/null; then
            echo "❌ '$cmd' n'a pas pu être installé automatiquement."
            exit 1
        fi
    fi
done

# Création préfixe Wine
if [ ! -d "$WINEPREFIX" ]; then
    echo "🛠 Création du préfixe Wine ($WINEARCH) à : $WINEPREFIX"
    WINEARCH=$WINEARCH WINEPREFIX=$WINEPREFIX winecfg >/dev/null 2>&1
else
    echo "✅ Préfixe déjà existant : $WINEPREFIX"
fi

# Application des winetricks
if [ ! -f "$WINETRICKS_MARKER" ]; then
    echo "🛠 Application de winetricks (win10, windowscodecs, corefonts)..."
    WINEPREFIX=$WINEPREFIX winetricks -q win10 windowscodecs corefonts
    touch "$WINETRICKS_MARKER"
else
    echo "✅ winetricks déjà appliqué sur ce préfixe."
fi

# Vérifier si PRONOTE déjà installé
if [ -d "$INSTALL_DIR" ]; then
    echo "✅ PRONOTE déjà installé dans : $INSTALL_DIR"
    read -p "Souhaitez-vous réinstaller/mise à jour ? (o/n) : " REP
    [[ ! "$REP" =~ ^[Oo]$ ]] && echo "Fin du script." && exit 0
fi

# Téléchargement PRONOTE
if [ ! -f "$PRONOTE_INSTALLER" ]; then
    echo "🔍 Recherche automatique du lien PRONOTE..."
    URL="https://www.index-education.com/fr/telecharger-pronote.php"
    DL_LINK=$(wget -qO- "$URL" | \
        grep -oiE 'href="[^"]+\.exe"' | \
        cut -d'"' -f2 | \
        grep -i 'install' | grep -i 'prnclient' | grep -i 'fr' | grep -i 'win64' | head -n1)

    while [ -z "$DL_LINK" ]; do
        echo "⚠ Lien non trouvé automatiquement."
        read -p "Collez un lien .exe (ou tapez 'q' pour quitter) : " DL_LINK
        DL_LINK=$(echo "$DL_LINK" | xargs)
        [[ "$DL_LINK" =~ ^[Qq]$ ]] && echo "Abandon." && exit 1
        [[ ! "$DL_LINK" =~ \.exe$ ]] && echo "❌ Lien invalide." && DL_LINK=""
    done

    echo "⬇ Téléchargement : $DL_LINK"
    wget -c --show-progress -O "$PRONOTE_INSTALLER" "$DL_LINK"
    if [ $? -ne 0 ]; then
        echo "❌ Téléchargement échoué."
        exit 1
    fi
else
    echo "✅ Fichier d'installation déjà présent : $PRONOTE_INSTALLER"
fi

# Installation PRONOTE
echo "🚀 Lancement de l'installation de PRONOTE..."
WINEPREFIX=$WINEPREFIX wine "$PRONOTE_INSTALLER"
RESULT=$?

# Nettoyer si OK
if [ $RESULT -eq 0 ]; then
    echo "✅ PRONOTE installé avec succès."
    rm -f "$PRONOTE_INSTALLER"
else
    echo "❌ L'installation de PRONOTE a échoué."
fi

