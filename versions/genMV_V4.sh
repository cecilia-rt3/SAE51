# genMV_V4.sh - Gestion simple de VM VirtualBox avec arguments 


# --- Paramètres communs ---
OSTYPE="Debian_64"
RAM=4096        # MiB
CPU=1
VRAM=128
DISK=65536      # MiB (≈64 GiB)
ISO="$HOME/SAE51/iso/ubuntu-22.04.5-desktop-amd64.iso"

usage() {
  echo "Usage : $0 [L|N|S|D|A] <NomVM>"
  echo "  L            : Lister toutes les VMs"
  echo "  N <NomVM>    : Créer une VM"
  echo "  S <NomVM>    : Supprimer une VM"
  echo "  D <NomVM>    : Démarrer une VM (GUI)"
  echo "  A <NomVM>    : Arrêter une VM"
}

vm_exists() {
  VBoxManage list vms | grep -q "\"$1\""
}

create_vm() {
  VM="$1"

  # Supprimer si déjà existante
  if vm_exists "$VM"; then
    echo "VM '$VM' déjà existante → suppression..."
    VBoxManage unregistervm "$VM" --delete
    rm -f "./$VM.vdi"
  fi

  echo "Création de la VM '$VM'..."
  VBoxManage createvm --name "$VM" --ostype "$OSTYPE" --register

  echo "Configuration mémoire/CPU/VRAM + NAT..."
  VBoxManage modifyvm "$VM" --memory "$RAM" --cpus "$CPU" --vram "$VRAM" --nic1 nat

  echo "Ordre de boot : PXE puis DVD..."
  VBoxManage modifyvm "$VM" --boot1 net --boot2 dvd --boot3 disk --boot4 none

  echo "Création du disque local $((DISK/1024)) Go..."
  VBoxManage createmedium disk --filename "./$VM.vdi" --size "$DISK" --format VDI

  VBoxManage storagectl "$VM" --name "SATA" --add sata --controller IntelAhci
  VBoxManage storageattach "$VM" \
    --storagectl "SATA" --port 0 --device 0 \
    --type hdd --medium "./$VM.vdi"

  if [ "$ISO" != "" ] && [ -e "$ISO" ]; then
    echo "Attachement de l’ISO : $ISO"
    VBoxManage storageattach "$VM" \
      --storagectl "SATA" --port 1 --device 0 \
      --type dvddrive --medium "$ISO"
  else
    echo "ATTENTION : ISO non trouvé ($ISO)"
  fi

  echo "VM '$VM' prête."
}

delete_vm() {
  VM="$1"
  if vm_exists "$VM"; then
    echo "Suppression de '$VM'..."
    VBoxManage controlvm "$VM" poweroff 2>/dev/null || true
    VBoxManage unregistervm "$VM" --delete
    rm -f "./$VM.vdi"
  else
    echo "La VM '$VM' n'existe pas."
  fi
}

start_vm() {
  VM="$1"
  if vm_exists "$VM"; then
    echo "Démarrage de '$VM'..."
    VBoxManage startvm "$VM" --type gui
  else
    echo "La VM '$VM' n'existe pas."
  fi
}

stop_vm() {
  VM="$1"
  if vm_exists "$VM"; then
    echo "Arrêt de '$VM'..."
    VBoxManage controlvm "$VM" acpipowerbutton 2>/dev/null || true
    sleep 3
    VBoxManage controlvm "$VM" poweroff 2>/dev/null || true
  else
    echo "La VM '$VM' n'existe pas."
  fi
}

list_vms() {
  echo "Liste des VMs :"
  VBoxManage list vms
}

# --- Main ---
action="$1"
name="$2"

if [ "$action" = "L" ]; then
  list_vms

elif [ "$action" = "N" ]; then
  if [ "$name" = "" ]; then
    usage
  else
    create_vm "$name"
  fi

elif [ "$action" = "S" ]; then
  if [ "$name" = "" ]; then
    usage
  else
    delete_vm "$name"
  fi

elif [ "$action" = "D" ]; then
  if [ "$name" = "" ]; then
    usage
  else
    start_vm "$name"
  fi

elif [ "$action" = "A" ]; then
  if [ "$name" = "" ]; then
    usage
  else
    stop_vm "$name"
  fi

else
  usage
fi

