#!/bin/bash
clear

# CONFIG
INSTALL_DIR="$HOME/.wine-pronote/drive_c/Program Files/Index Education/Client PRONOTE"
WINEPREFIX="$HOME/.wine-pronote"
WINEARCH=win64
WINETRICKS_MARKER="$WINEPREFIX/.pronote_win10_done"
PRONOTE_INSTALLER="pronote_install.exe" 

# Vérification de la commande wine
if ! command -v wine &>/dev/null; then
    echo "❌ La commande 'wine' est manquante. Installation en cours..."
    
    if [ -f /etc/debian_version ]; then
        sudo dpkg --add-architecture i386
        sudo apt update
        sudo apt install -y wine64 wine32 winetricks
    elif [ -f /etc/fedora-release ]; then
        sudo dnf install -y wine winetricks
    elif [ -f /etc/arch-release ]; then
        sudo pacman -Syu --noconfirm
        sudo pacman -S --noconfirm wine winetricks
    elif [ -f /etc/SuSE-release ]; then
        sudo zypper install -y wine winetricks
    elif [ -f /etc/gentoo-release ]; then
        sudo emerge app-emulation/wine app-emulation/winetricks
    else
        echo "⚠ Système non pris en charge pour l'installation automatique de wine."
        exit 1
    fi

    # Vérifier après installation
    if ! command -v wine &>/dev/null; then
        echo "❌ 'wine' n'a pas pu être installé automatiquement."
        exit 1
    fi
fi

# Vérification si WINEPREFIX est défini
if [ -z "$WINEPREFIX" ]; then
    echo "❌ La variable WINEPREFIX est vide. Vérifiez la configuration."
    exit 1
fi

# Création du préfixe Wine si nécessaire
if [ ! -d "$WINEPREFIX" ]; then
    echo "🛠 Création du préfixe Wine à : $WINEPREFIX"
    WINEARCH=$WINEARCH WINEPREFIX=$WINEPREFIX winecfg >/dev/null 2>&1
else
    echo "✅ Préfixe déjà existant : $WINEPREFIX"
fi

# Vérification de la version de Wine
WINE_OUTPUT=$(WINEPREFIX=$WINEPREFIX winecfg -v 2>&1)
echo "Sortie de winecfg :"
echo "$WINE_OUTPUT"

WINE_VERSION=$(echo "$WINE_OUTPUT" | awk '{print $NF}')
echo "La variable est : $WINE_VERSION"

# Vérification si WINE_VERSION est vide
if [ -z "$WINE_VERSION" ]; then
    echo "La variable WINE_VERSION est vide."
else
    echo "La variable WINE_VERSION contient : $WINE_VERSION"
fi

# Application des winetricks
if [ ! -f "$WINETRICKS_MARKER" ]; then
    echo "🛠 Application de winetricks (win10, windowscodecs, corefonts)..."
    WINEPREFIX=$WINEPREFIX winetricks -q win10 windowscodecs corefonts
    touch "$WINETRICKS_MARKER"
else
    echo "✅ winetricks déjà appliqué sur ce préfixe."
fi

# Vérification de la version de Windows
WINE_VERSION=$(WINEPREFIX=~/.wine-pronote winecfg -v 2>&1)
if [["$WINE_VERSION" != "10" ]]; then
    echo "❌ La version de Windows dans Wine n'est pas configurée sur Windows 10. Actuellement : $WINE_VERSION"
    echo "Lancement de Winetricks pour une mise en place manuelle..."
    WINEPREFIX=$WINEPREFIX winetricks
    echo "Veuillez configurer manuellement la version de Windows sur Windows 10 dans Winetricks."
    read -p "Appuyez sur Entrée pour continuer une fois que vous avez terminé..."

    # Vérification après la mise en place manuelle
    WINE_VERSION=$(WINEPREFIX=$WINEPREFIX winecfg -v 2>&1)
    if [["$WINE_VERSION" != "10" ]]; then
        echo "❌ La version de Windows est toujours incorrecte. Veuillez vérifier votre configuration."
        exit 1
    else
        echo "✅ La version de Windows est maintenant correctement configurée sur Windows 10."
    fi
else
    echo "✅ La version de Windows est correctement configurée sur Windows 10."
fi

# Affichage des valeurs de WINEPREFIX et WINEARCH
echo "🔍 Valeurs actuelles :"
echo "Préfixe : $WINEPREFIX"
echo "Avec une architectture : $WINEARCH"


echo "Début de la pause..."
sleep 5  # Pause de 5 secondes
echo "Fin de la pause."



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

