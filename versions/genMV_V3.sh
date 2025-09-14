# genMV_V3.sh - Création d'une VM Debian1 (test avec ISO Ubuntu, disque local)


# --- Paramètres de la VM ---
VM="Debian1"
OSTYPE="Debian_64"
RAM=4096
CPU=1
VRAM=128
DISK=65536   # MiB (≈64 GiB)
ISO="$HOME/SAE51/iso/ubuntu-22.04.5-desktop-amd64.iso"

# --- Vérification VBoxManage ---
if ! which VBoxManage >/dev/null 2>&1; then
  echo "Erreur : VBoxManage non trouvé. Installe VirtualBox."
  exit 1
fi

# --- Vérification si la VM existe déjà ---
if VBoxManage list vms | grep -q "\"$VM\""; then
  echo "Attention : la VM '$VM' existe déjà. Suppression..."
  VBoxManage unregistervm "$VM" --delete
  rm -f "./$VM.vdi" 2>/dev/null
fi

# --- Création de la VM ---
echo "Création de la VM '$VM'..."
VBoxManage createvm --name "$VM" --ostype "$OSTYPE" --register

echo "Configuration mémoire/CPU/VRAM + réseau NAT..."
VBoxManage modifyvm "$VM" --memory "$RAM" --cpus "$CPU" --vram "$VRAM" --nic1 nat

echo "Ordre de boot : PXE réseau en premier..."
VBoxManage modifyvm "$VM" --boot1 net --boot2 dvd --boot3 disk --boot4 none

# --- Disque dur (dans le répertoire courant) ---
echo "Création d'un disque local de $((DISK/1024)) Go..."
VBoxManage createmedium disk --filename "./$VM.vdi" --size "$DISK" --format VDI

echo "Ajout du contrôleur SATA + attache disque"
VBoxManage storagectl "$VM" --name "SATA" --add sata --controller IntelAhci
VBoxManage storageattach "$VM" \
  --storagectl "SATA" --port 0 --device 0 \
  --type hdd --medium "./$VM.vdi"

# --- Attacher l’ISO Ubuntu ---
if [ -e "$ISO" ]; then
  echo "Attachement de l’ISO Ubuntu : $ISO"
  VBoxManage storageattach "$VM" \
    --storagectl "SATA" --port 1 --device 0 \
    --type dvddrive --medium "$ISO"
else
  echo "ATTENTION : ISO non trouvé ($ISO)."
fi

# --- Démarrage automatique de la VM ---
echo
echo "Démarrage de la VM '$VM' en mode GUI..."
VBoxManage startvm "$VM" --type gui

# --- Pause pour vérification manuelle ---
echo
echo "PAUSE : La VM est en cours d’exécution. Vérifie dans VirtualBox GUI."
sleep 10   # pause de 10 secondes

# --- Suppression de la VM ---
echo "Suppression de la VM '$VM'..."
VBoxManage controlvm "$VM" poweroff 2>/dev/null || true
VBoxManage unregistervm "$VM" --delete
rm -f "./$VM.vdi" 2>/dev/null

echo "Script terminé."
