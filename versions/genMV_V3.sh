# genMV.sh — Version 3 (noms en français)

# Paramètres
VM="Debian1"
RAM=4096           # MiB (4 Gio)
DISK=65536         # MiB (64 Gio)
CPU=1
VRAM=128
OSTYPE="Debian_64"
BOOT_NET_FIRST=1   # 1 = boot PXE en premier

# Vérifier VBoxManage 
if ! type -P VBoxManage >/dev/null 2>&1; then
  echo "Erreur : VBoxManage introuvable. Installe VirtualBox ou ajoute-le au PATH."
  exit 1
fi

# Répertoire TFTP de VirtualBox (selon versions)
if   [ -d "$HOME/.config/VirtualBox" ]; then VB_DIR="$HOME/.config/VirtualBox"
elif [ -d "$HOME/.VirtualBox" ];       then VB_DIR="$HOME/.VirtualBox"
else VB_DIR="$HOME/.config/VirtualBox"; mkdir -p "$VB_DIR"
fi
TFTP_DIR="$VB_DIR/TFTP"

#Q2 ---
vm_existe() { VBoxManage list vms | grep -q "^\"$1\" "; }

# --- Q3 : préparation PXE (netboot Debian) ---
preparer_pxe() {
  mkdir -p "$TFTP_DIR"
  if [ ! -f "$TFTP_DIR/pxelinux.0" ]; then
    echo "Téléchargement des fichiers netboot Debian (amd64)…"
    URL="http://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/netboot/netboot.tar.gz"
    TAR="$TFTP_DIR/netboot.tar.gz"

    if type -P curl >/dev/null 2>&1; then
      curl -L -o "$TAR" "$URL"
    elif type -P wget >/dev/null 2>&1; then
      wget -O "$TAR" "$URL"
    else
      echo "Ni curl ni wget : dépose 'netboot.tar.gz' dans $TFTP_DIR puis lance : tar -xzf netboot.tar.gz"
      return
    fi

    if ! tar -xzf "$TAR" -C "$TFTP_DIR"; then
      echo "Erreur : extraction de netboot.tar.gz échouée."
      exit 1
    fi
    rm -f "$TAR"
  fi
}

# Créer le lien <VM>.pxe → pxelinux.0 (VirtualBox s'en sert par nom de VM)
lier_pxe_vm() {
  if [ -f "$TFTP_DIR/pxelinux.0" ]; then
    ln -sfn pxelinux.0 "$TFTP_DIR/$VM.pxe"
  else
    echo "pxelinux.0 absent : le démarrage PXE peut ne pas fonctionner."
  fi
}

# --- Q2 : si la VM existe déjà → suppression (pour rejouer proprement) ---
if vm_existe "$VM"; then
  echo "La VM '$VM' existe déjà. Suppression pour rejouer la démo…"
  if ! VBoxManage unregistervm "$VM" --delete; then
    echo "Erreur : suppression de la VM existante échouée."
    exit 1
  fi
  rm -rf "$HOME/VirtualBox VMs/$VM" 2>/dev/null || true
fi

# --- Q1 : création ---
echo "Création de la VM '$VM' (type=$OSTYPE)…"
if ! VBoxManage createvm --name "$VM" --ostype "$OSTYPE" --register; then
  echo "Erreur : création de la VM échouée."
  exit 1
fi

# Q1 — configuration (RAM/CPU/VRAM + NAT)
echo "Configuration mémoire/CPU/VIDÉO + réseau NAT…"
if ! VBoxManage modifyvm "$VM" --memory "$RAM" --cpus "$CPU" --vram "$VRAM" --nic1 nat; then
  echo "Erreur : configuration de base échouée."
  exit 1
fi

# Q1 — boot PXE en premier (si demandé)
if [ "$BOOT_NET_FIRST" -eq 1 ]; then
  echo "Ordre de boot : PXE en premier…"
  if ! VBoxManage modifyvm "$VM" --boot1 net --boot2 disk --boot3 none --boot4 none; then
    echo "Erreur : réglage de l'ordre de boot échoué."
    exit 1
  fi
fi

# Q1 — disque 64 Gio + contrôleur SATA
VMDIR="$HOME/VirtualBox VMs/$VM"
VDI="$VMDIR/$VM.vdi"
echo "Création du disque (64 Gio) et attache sur contrôleur SATA…"
mkdir -p "$VMDIR"

if ! VBoxManage createhd --filename "$VDI" --size "$DISK" --format VDI >/dev/null; then
  echo "Erreur : création du disque échouée."
  exit 1
fi

if ! VBoxManage storagectl "$VM" --name "SATA" --add sata --controller IntelAhci; then
  echo "Erreur : ajout du contrôleur SATA échoué."
  exit 1
fi

if ! VBoxManage storageattach "$VM" \
     --storagectl "SATA" --port 0 --device 0 \
     --type hdd --medium "$VDI"; then
  echo "Erreur : attache du disque SATA échouée."
  exit 1
fi

# Q3 — activer PXE netinst
preparer_pxe
lier_pxe_vm

# Pause automatique (5 secondes) pour vérifier dans la GUI
echo
echo "PAUSE : ouvre la GUI VirtualBox et vérifie que la VM '$VM' existe (et le boot PXE)."
echo "La suppression commencera dans 5 secondes…"
sleep 5

# Q1 — destruction de la VM
echo "Suppression de la VM '$VM'…"
if ! VBoxManage unregistervm "$VM" --delete; then
  echo "Erreur : suppression de la VM échouée."
  exit 1
fi
rm -rf "$VMDIR" 2>/dev/null || true

echo "Terminé "

