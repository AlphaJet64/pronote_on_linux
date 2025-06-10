#!/bin/bash

# Préfixe Wine 64 bits dédié à PRONOTE
WINEPREFIX="$HOME/.wine-pronote"
export WINEPREFIX
export WINEARCH=win64

# Chemin d'installation attendu
INSTALL_DIR="$WINEPREFIX/drive_c/Program Files/Index Education/Client PRONOTE"

# 1. VÉRIFICATION AVANT TOUTE INSTALLATION DE WINE OU CRÉATION DE PRÉFIXE
if [ -d "$INSTALL_DIR" ]; then
    echo "──────────────────────────────────────────────"
    echo "✅ Le client PRONOTE est déjà installé !"
    echo "Chemin : $INSTALL_DIR"
    echo "──────────────────────────────────────────────"
    read -p "Voulez-vous réinstaller ou mettre à jour PRONOTE ? (o/n) " REP
    if [[ ! "$REP" =~ ^[Oo]$ ]]; then
        echo "Aucune action n'a été effectuée. Fin du script."
        exit 0
    fi
    echo "→ Réinstallation/mise à jour de PRONOTE en cours..."
fi

# 2. INSTALLATION DE WINE SELON LA DISTRIBUTION (SI BESOIN)
install_debian() {
    echo "Ajout de la clé de dépôt WineHQ..."
    wget -nc https://dl.winehq.org/wine-builds/winehq.key
    sudo apt-key add winehq.key

    echo "Ajout du dépôt WineHQ..."
    sudo apt-get install -y software-properties-common
    sudo add-apt-repository "deb https://dl.winehq.org/wine-builds/ubuntu/ $(lsb_release -cs) main"

    echo "Mise à jour des paquets..."
    sudo apt-get update

    echo "Installation de Wine et des dépendances..."
    sudo apt-get install -y --install-recommends winehq-stable winetricks
    winetricks corefonts windowscodecs msxml6
}

install_fedora() {
    echo "Mise à jour des paquets..."
    sudo dnf check-update
    echo "Installation de Wine et des dépendances..."
    sudo dnf install -y wine winetricks
    winetricks corefonts windowscodecs msxml6
}

install_arch() {
    echo "Mise à jour des paquets..."
    sudo pacman -Syu
    echo "Installation de Wine et des dépendances..."
    sudo pacman -S --noconfirm wine winetricks
    winetricks corefonts windowscodecs msxml6
}

if [ -f /etc/debian_version ]; then
    echo "Détection de Debian/Ubuntu..."
    install_debian
elif [ -f /etc/fedora-release ]; then
    echo "Détection de Fedora..."
    install_fedora
elif [ -f /etc/arch-release ]; then
    echo "Détection d'Arch Linux..."
    install_arch
else
    echo "Système d'exploitation non pris en charge. Veuillez installer Wine manuellement."
    exit 1
fi

# 3. CRÉATION DU PRÉFIXE WINE SI NÉCESSAIRE
if [ ! -d "$WINEPREFIX" ]; then
    echo "Création du préfixe Wine 64 bits..."
    winecfg
    echo "Veuillez sélectionner 'Windows 10' dans la liste des versions de Windows dans la fenêtre de configuration de Wine."
fi

# 4. RÉCUPÉRATION AUTOMATIQUE DU LIEN DE TÉLÉCHARGEMENT PRONOTE
# Récupération du HTML
URL="https://www.index-education.com/fr/telecharger-pronote.php"
HTML=$(wget -qO- "$URL")

# Extraction de tous les liens .exe
LINKS=$(echo "$HTML" | grep -oiE 'href="[^"]+\.exe"' | cut -d'"' -f2)

# Filtrage indépendant de la casse et des séparateurs
DL_LINK=$(echo "$LINKS" | awk '{
    l=tolower($0)
    if(l ~ /install/ && l ~ /prnclient/ && l ~ /fr/ && l ~ /win64/) print $0
}' | head -n1)

if [ -z "$DL_LINK" ]; then
    echo "Impossible de trouver le lien de téléchargement PRONOTE Windows 64 bits."
    exit 1
fi

echo "Lien détecté : $DL_LINK"


# 5. TÉLÉCHARGEMENT
echo "Téléchargement de PRONOTE..."
wget -O pronote_install.exe "$DL_LINK"

if [ $? -ne 0 ]; then
    echo "Le téléchargement a échoué. Vérifiez le lien et réessayez."
    exit 1
fi

# 6. INSTALLATION
echo "Installation de PRONOTE..."
wine pronote_install.exe

if [ $? -eq 0 ]; then
    echo "PRONOTE a été installé avec succès."
else
    echo "L'installation a échoué."
fi


