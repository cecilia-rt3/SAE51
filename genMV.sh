# genMV.sh — Version finale 

# Paramètres 
RAM=4096
DISK=65536
CPU=1
VRAM=128
OSTYPE="Debian_64"
BOOT_NET_FIRST=1

# Vérif VBoxManage
if ! type -P VBoxManage >/dev/null 2>&1; then
  echo "Erreur: VBoxManage introuvable. Installe VirtualBox ou ajoute-le au PATH."
  exit 1
fi

# Aides
vm_exists()  { VBoxManage list vms        | grep -q "^\"$1\" "; }
vm_running() { VBoxManage list runningvms | grep -q "^\"$1\" "; }

usage() {
  cat <<EOF
Usage:
  $0 Q1                      # Démo : créer 'Debian1' -> pause -> supprimer
  $0 L                       # Lister VMs + métadonnées
  $0 N <vm>                  # Créer une VM
  $0 D <vm>                  # Démarrer (GUI)
  $0 A <vm>                  # Arrêter (ACPI puis poweroff)
  $0 S <vm>                  # Supprimer
  $0 I <vm> <chemin_iso>     # Insérer une ISO (lecteur DVD) + priorité boot DVD
  $0 U <vm>                  # Éjecter l'ISO et remettre boot sur disque
  $0 M <vm>                  # Réparer/poser les métadonnées sur une VM existante
  $0 MF                      # Réparer/poser les métadonnées sur TOUTES les VMs
EOF
}

# --- Métadonnées (Q5) ---
set_metadata() {
  VM="$1"
  # Pose (ou remplace) les métadonnées
  VBoxManage setextradata "$VM" CreationDate "$(TZ=Europe/Paris date '+%Y-%m-%d %H:%M:%S')"
  VBoxManage setextradata "$VM" CreatedBy "$USER"
}

ensure_metadata() {
  VM="$1"
  # Lit les valeurs actuelles
  RAW_D="$(VBoxManage getextradata "$VM" CreationDate 2>/dev/null || true)"
  RAW_U="$(VBoxManage getextradata "$VM" CreatedBy    2>/dev/null || true)"

  # Si manquantes, on (re)pose
  if ! echo "$RAW_D" | grep -q '^Value:' || ! echo "$RAW_U" | grep -q '^Value:'; then
    echo "[M] Pose des métadonnées sur '$VM'…"
    set_metadata "$VM"
  fi
}

# Opérations de base
create_vm() {
  VM="$1"
  vm_exists "$VM" && { echo "La VM '$VM' existe déjà."; exit 1; }

  VBoxManage createvm --name "$VM" --ostype "$OSTYPE" --register
  VBoxManage modifyvm "$VM" --memory "$RAM" --cpus "$CPU" --vram "$VRAM" --nic1 nat

  if [ "$BOOT_NET_FIRST" -eq 1 ]; then
    VBoxManage modifyvm "$VM" --boot1 net --boot2 disk --boot3 none --boot4 none
  else
    VBoxManage modifyvm "$VM" --boot1 disk --boot2 net --boot3 none --boot4 none
  fi

  VMDIR="$HOME/VirtualBox VMs/$VM"
  VDI="$VMDIR/$VM.vdi"
  mkdir -p "$VMDIR"
  VBoxManage createhd --filename "$VDI" --size "$DISK" --format VDI >/dev/null
  VBoxManage storagectl "$VM" --name "SATA" --add sata --controller IntelAhci 2>/dev/null || true
  VBoxManage storageattach "$VM" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "$VDI"

  # --- Métadonnées Q5 ---
  set_metadata "$VM"

  echo "VM '$VM' créée."
}

start_vm()  {
  VM="$1"; vm_exists "$VM" || { echo "introuvable"; exit 1; }
  VBoxManage startvm "$VM" --type gui
}

stop_vm()   {
  VM="$1"; vm_exists "$VM" || { echo "introuvable"; exit 1; }
  if vm_running "$VM"; then
    VBoxManage controlvm "$VM" acpipowerbutton || true
    for _ in {1..30}; do vm_running "$VM" || break; sleep 1; done
    vm_running "$VM" && VBoxManage controlvm "$VM" poweroff
  else
    echo "La VM n'est pas en cours d'exécution."
  fi
}

delete_vm() {
  VM="$1"
  if vm_exists "$VM"; then
    vm_running "$VM" && stop_vm "$VM"
    VBoxManage unregistervm "$VM" --delete
    rm -rf "$HOME/VirtualBox VMs/$VM" 2>/dev/null
    echo "VM '$VM' supprimée."
  else
    echo "introuvable."
  fi
}

# ISO : Insérer 
attach_iso() {
  VM="$1"; ISO="$2"
  vm_exists "$VM" || { echo "VM introuvable: $VM"; exit 1; }
  [ -f "$ISO" ] || { echo "ISO introuvable: $ISO"; exit 1; }

  # Utiliser un contrôleur IDE pour le lecteur DVD (compatible partout)
  VBoxManage storagectl "$VM" --name "IDE" --add ide --controller PIIX4 2>/dev/null || true
  VBoxManage storageattach "$VM" \
    --storagectl "IDE" --port 0 --device 0 \
    --type dvddrive --medium "$ISO"

  # Ordre de boot : DVD d'abord
  VBoxManage modifyvm "$VM" --boot1 dvd --boot2 disk --boot3 net --boot4 none
  echo "ISO insérée sur '$VM' (IDE). Boot prioritaire sur DVD."
}


# Q5 : Liste + métadonnées
list_with_meta() {
  echo "=== VMs & métadonnées (Q5) ==="
  VBoxManage list vms | while read -r line; do
    NAME="$(echo "$line" | cut -d'"' -f2)"
    RAW_D="$(VBoxManage getextradata "$NAME" CreationDate 2>/dev/null || true)"
    RAW_U="$(VBoxManage getextradata "$NAME" CreatedBy    2>/dev/null || true)"

    # Format attendu : "Value: 2025-09-11 14:22:00" ou "No value set!"
    VAL_D="$(echo "$RAW_D" | sed -n 's/^Value: //p')"
    VAL_U="$(echo "$RAW_U" | sed -n 's/^Value: //p')"
    [ -z "$VAL_D" ] && VAL_D="Unknown"
    [ -z "$VAL_U" ] && VAL_U="Unknown"

    echo "VM: $NAME"
    echo "  Creation : $VAL_D"
    echo "  By       : $VAL_U"
    echo
  done
}


# Q1 : 
q1_demo() {
  VM="Debian1"
  vm_exists "$VM" && { VBoxManage unregistervm "$VM" --delete; rm -rf "$HOME/VirtualBox VMs/$VM" 2>/dev/null; }
  create_vm "$VM"
  echo "PAUSE 5s : ouvre VirtualBox et vérifie que '$VM' existe."
  sleep 5
  delete_vm "$VM"
}

# Dispatch

ACT="${1:-}"; VM="${2:-}"; ISO="${3:-}"

if [ "$ACT" = "Q1" ]; then
  q1_demo
elif [ "$ACT" = "L" ]; then
  list_with_meta
elif [ "$ACT" = "N" ]; then
  [ -n "$VM" ] || { usage; exit 1; }
  create_vm "$VM"
elif [ "$ACT" = "D" ]; then
  [ -n "$VM" ] || { usage; exit 1; }
  start_vm "$VM"
elif [ "$ACT" = "A" ]; then
  [ -n "$VM" ] || { usage; exit 1; }
  stop_vm "$VM"
elif [ "$ACT" = "S" ]; then
  [ -n "$VM" ] || { usage; exit 1; }
  delete_vm "$VM"
elif [ "$ACT" = "I" ]; then
  [ -n "$VM" ] && [ -n "$ISO" ] || { usage; exit 1; }
  attach_iso "$VM" "$ISO"
else
  usage
fi

