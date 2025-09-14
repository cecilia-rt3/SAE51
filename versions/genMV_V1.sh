# genMV_V1.sh - Création simple d'une VM Debian1 

# --- Paramètres de la VM ---
VM="Debian1"
OSTYPE="Debian_64"
RAM=4096
CPU=1
VRAM=128
DISK=65536   # MiB (≈64 GiB)

# --- Vérification VBoxManage ---
if ! which VBoxManage >/dev/null 2>&1; then
  echo "Erreur : VBoxManage non trouvé. Installe VirtualBox."
  exit 1
fi

# --- Création de la VM ---
echo "Création de la VM '$VM'..."
VBoxManage createvm --name "$VM" --ostype "$OSTYPE" --register

echo "Configuration mémoire/CPU/VRAM + réseau NAT..."
VBoxManage modifyvm "$VM" --memory "$RAM" --cpus "$CPU" --vram "$VRAM" --nic1 nat

echo "Ordre de boot : PXE réseau en premier..."
VBoxManage modifyvm "$VM" --boot1 net --boot2 disk --boot3 none --boot4 none

# --- Disque dur (dans le répertoire courant) ---
echo "Création d'un disque local $((DISK/1024)) Go..."
VBoxManage createmedium disk --filename "./$VM.vdi" --size "$DISK" --format VDI

echo "Ajout du contrôleur SATA + attache disque"
VBoxManage storagectl "$VM" --name "SATA" --add sata --controller IntelAhci
VBoxManage storageattach "$VM" \
  --storagectl "SATA" --port 0 --device 0 \
  --type hdd --medium "./$VM.vdi"

# --- Pause pour vérification manuelle ---
echo
echo "PAUSE : Vérifie dans VirtualBox GUI que la VM '$VM' existe bien."
sleep 10   # pause automatique de 10 secondes

# --- Suppression de la VM ---
echo "Suppression de la VM '$VM'..."
VBoxManage unregistervm "$VM" --delete
rm -f "./$VM.vdi"

echo "Script terminé."
