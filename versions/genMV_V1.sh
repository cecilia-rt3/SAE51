# --- Paramètres ---
VM="Debian1"
OSTYPE="Debian_64"
RAM=4096           # MiB
DISK=65536         # MiB (64 GiB)
CPU=1
VRAM=128
BOOT_NET_FIRST=1   # 1 = PXE d'abord, 0 = disque d'abord

# --- Préchecks ---
if ! command -v VBoxManage >/dev/null 2>&1; then
  echo "Erreur: VBoxManage introuvable. Installe VirtualBox ou ajoute-le au PATH." >&2
  exit 1
fi

# --- Utilitaires ---
vm_exists() { VBoxManage list vms | grep -q "^\"$1\" "; }

# --- (Q2) Si la VM existe, la supprimer pour rejouer proprement ---
if vm_exists "$VM"; then
  echo "Info: La VM '$VM' existe déjà. Suppression…"
  VBoxManage unregistervm "$VM" --delete || true
  rm -rf "$HOME/VirtualBox VMs/$VM" 2>/dev/null || true
fi

# --- Création & configuration de la VM ---
echo "Création de la VM '$VM' (type=$OSTYPE)…"
VBoxManage createvm --name "$VM" --ostype "$OSTYPE" --register

echo "Configuration mémoire/CPU/VRAM + NAT…"
VBoxManage modifyvm "$VM" --memory "$RAM" --cpus "$CPU" --vram "$VRAM" --nic1 nat

if [ "$BOOT_NET_FIRST" -eq 1 ]; then
  echo "Ordre de boot: réseau puis disque…"
  VBoxManage modifyvm "$VM" --boot1 net --boot2 disk --boot3 none --boot4 none
else
  echo "Ordre de boot: disque puis réseau…"
  VBoxManage modifyvm "$VM" --boot1 disk --boot2 net --boot3 none --boot4 none
fi

# --- Disque + contrôleur SATA ---
VMDIR="$HOME/VirtualBox VMs/$VM"
VDI="$VMDIR/$VM.vdi"
echo "Création du disque $((DISK/1024)) GiB et attache sur contrôleur SATA…"
mkdir -p "$VMDIR"
VBoxManage createmedium disk --filename "$VDI" --size "$DISK" --format VDI >/dev/null
VBoxManage storagectl "$VM" --name "SATA" --add sata --controller IntelAhci
VBoxManage storageattach "$VM" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "$VDI"

# --- Pause vérification ---
echo
echo "PAUSE: Ouvre VirtualBox et vérifie que la VM '$VM' existe et est configurée."
read -rp "Appuie sur Entrée pour SUPPRIMER la VM et terminer la démo…"

# --- Suppression (fin de démo Q1) ---
echo "Suppression de la VM '$VM'…"
VBoxManage unregistervm "$VM" --delete || true
rm -rf "$VMDIR" 2>/dev/null || true
echo "Terminé."

