# genMV.sh — Version2 

# Paramètres
VM="Debian1"
RAM=4096           # MiB (4 Gio)
DISK=65536         # MiB (64 Gio)
CPU=1
VRAM=128
OSTYPE="Debian_64"
BOOT_NET_FIRST=1   # 1 = boot PXE en premier

# Vérifier VBoxManage
if ! command -v VBoxManage >/dev/null 2>&1; then
  echo "Erreur: VBoxManage introuvable. Installe VirtualBox ou ajoute-le au PATH."
  exit 1
fi

# Q2 — petite aide
vm_exists() { VBoxManage list vms | grep -q "^\"$1\" "; }

# Q2 — si la VM existe déjà → suppression 
if vm_exists "$VM"; then
  echo "La VM '$VM' existe déjà. Suppression pour rejouer la démo…"
  if ! VBoxManage unregistervm "$VM" --delete; then
    echo "Erreur: Impossible de supprimer la VM existante."
    exit 1
  fi
  rm -rf "$HOME/VirtualBox VMs/$VM" 2>/dev/null || true
fi

# Q1 — création
echo "Création de la VM '$VM' (type=$OSTYPE)…"
if ! VBoxManage createvm --name "$VM" --ostype "$OSTYPE" --register; then
  echo "Erreur: Création de la VM échouée."
  exit 1
fi

# Q1 — configuration (RAM/CPU/VRAM + NAT)
echo "Configuration mémoire/processeur/vidéo + réseau NAT…"
if ! VBoxManage modifyvm "$VM" --memory "$RAM" --cpus "$CPU" --vram "$VRAM" --nic1 nat; then
  echo "Erreur: Configuration de base échouée."
  exit 1
fi

# Q1 — boot PXE en premier 
if [ "$BOOT_NET_FIRST" -eq 1 ]; then
  echo "Boot PXE en premier…"
  if ! VBoxManage modifyvm "$VM" --boot1 net --boot2 disk --boot3 none --boot4 none; then
    echo "Erreur: Réglage de l'ordre de boot échoué."
    exit 1
  fi
fi

# Q1 — disque 64 Gio + contrôleur SATA
VMDIR="$HOME/VirtualBox VMs/$VM"
VDI="$VMDIR/$VM.vdi"
echo "Création du disque (64 Gio) et attache sur contrôleur SATA…"
mkdir -p "$VMDIR"

if ! VBoxManage createhd --filename "$VDI" --size "$DISK" --format VDI >/dev/null; then
  echo "Erreur: Création du disque échouée."
  exit 1
fi

if ! VBoxManage storagectl "$VM" --name "SATA" --add sata --controller IntelAhci; then
  echo "Erreur: Ajout du contrôleur SATA échoué."
  exit 1
fi

if ! VBoxManage storageattach "$VM" \
     --storagectl "SATA" --port 0 --device 0 \
     --type hdd --medium "$VDI"; then
  echo "Erreur: Attache du disque sur SATA échouée."
  exit 1
fi

# Pause automatique (5 secondes) pour vérifier dans la GUI
echo
echo "PAUSE : ouvre la GUI VirtualBox et vérifie que la VM '$VM' existe."
echo "La suppression commencera dans 5 secondes…"
sleep 5

# Q1 — destruction de la VM
echo "Suppression de la VM '$VM'…"
if ! VBoxManage unregistervm "$VM" --delete; then
  echo "Erreur: Suppression de la VM échouée."
  exit 1
fi
rm -rf "$VMDIR" 2>/dev/null || true

echo "Terminé"

