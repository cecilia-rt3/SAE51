# genMV.sh - Gestion simple de VM VirtualBox + métadonnées (L/N/S/D/A)


# --- Paramètres communs (faciles à modifier) ---
OSTYPE="Debian_64"
RAM=4096        # MiB
CPU=1
VRAM=128
DISK=65536      # MiB (≈64 GiB)
ISO="$HOME/SAE51/iso/ubuntu-22.04.5-desktop-amd64.iso" 

usage() {
  echo "Usage : $0 [L|N|S|D|A] <NomVM>"
  echo "  L            : Lister toutes les VMs (avec métadonnées si présentes)"
  echo "  N <NomVM>    : Créer une VM (disque ./<NomVM>.vdi, NAT, PXE->DVD->DISK)"
  echo "  S <NomVM>    : Supprimer une VM"
  echo "  D <NomVM>    : Démarrer une VM (GUI)"
  echo "  A <NomVM>    : Arrêter une VM"
}

# --- utilitaires erreurs ---
die() { echo "Erreur: $*" >&2; exit 1; }
run() {
  # Exécute une commande VBoxManage et s'arrête si ça échoue
  "$@"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    die "échec: $* (code=$rc)"
  fi
}

# --- Vérif VBoxManage ---
if ! which VBoxManage >/dev/null 2>&1; then
  die "VBoxManage non trouvé. Installe VirtualBox."
fi

vm_exists() { VBoxManage list vms | grep -q "^\"$1\" "; }

create_vm() {
  VM="$1"
  DISKPATH="./$VM.vdi"

  # Si existe déjà → suppression pour rester idempotent
  if vm_exists "$VM"; then
    echo "VM '$VM' déjà existante → suppression..."
    run VBoxManage unregistervm "$VM" --delete
    rm -f "$DISKPATH" 2>/dev/null
  fi

  echo "Création de la VM '$VM' (type=$OSTYPE)..."
  run VBoxManage createvm --name "$VM" --ostype "$OSTYPE" --register

  echo "Mémoire/CPU/VRAM + NAT…"
  run VBoxManage modifyvm "$VM" --memory "$RAM" --cpus "$CPU" --vram "$VRAM" --nic1 nat

  echo "Ordre de boot : PXE → DVD → DISK…"
  run VBoxManage modifyvm "$VM" --boot1 net --boot2 dvd --boot3 disk --boot4 none

  echo "Disque local $((DISK/1024)) Go…"
  run VBoxManage createmedium disk --filename "$DISKPATH" --size "$DISK" --format VDI

  run VBoxManage storagectl "$VM" --name "SATA" --add sata --controller IntelAhci
  run VBoxManage storageattach "$VM" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "$DISKPATH"

  if [ "$ISO" != "" ] && [ -e "$ISO" ]; then
    echo "Attachement ISO : $ISO"
    run VBoxManage storageattach "$VM" --storagectl "SATA" --port 1 --device 0 --type dvddrive --medium "$ISO"
  else
    echo "(Info) Aucun ISO attaché (variable ISO vide ou fichier absent)."
  fi

  # --- Métadonnées (date + propriétaire) ---
  CREATED_AT="$(date '+%Y-%m-%d %H:%M:%S')"
  OWNER="$USER"
  run VBoxManage setextradata "$VM" "meta/created_at" "$CREATED_AT"
  run VBoxManage setextradata "$VM" "meta/owner" "$OWNER"

  echo "VM '$VM' prête. (created_at='$CREATED_AT', owner='$OWNER')"
}

delete_vm() {
  VM="$1"
  if vm_exists "$VM"; then
    echo "Suppression de '$VM'…"
    VBoxManage controlvm "$VM" poweroff 2>/dev/null || true
    run VBoxManage unregistervm "$VM" --delete
    rm -f "./$VM.vdi" 2>/dev/null
    echo "Suppression OK."
  else
    die "la VM '$VM' n'existe pas."
  fi
}

start_vm() {
  VM="$1"
  if vm_exists "$VM"; then
    echo "Démarrage de '$VM' (GUI)…"
    run VBoxManage startvm "$VM" --type gui
  else
    die "la VM '$VM' n'existe pas."
  fi
}

stop_vm() {
  VM="$1"
  if ! vm_exists "$VM"; then
    die "la VM '$VM' n'existe pas."
  fi

  echo "Arrêt ACPI de '$VM'…"
  VBoxManage controlvm "$VM" acpipowerbutton 2>/dev/null || true

  # petit timeout (≈15s) avant de forcer
  tries=0
  while VBoxManage list runningvms | grep -q "^\"$VM\" " ; do
    sleep 3
    tries=$((tries+1))
    [ "$tries" -ge 5 ] && break
  done

  if VBoxManage list runningvms | grep -q "^\"$VM\" " ; then
    echo "Forçage poweroff…"
    VBoxManage controlvm "$VM" poweroff 2>/dev/null || true
  fi
  echo "Arrêt OK."
}

list_vms() {
  TMP="$(mktemp -t vms.XXXXXX)"
  trap 'rm -f "$TMP" 2>/dev/null' EXIT

  run VBoxManage list vms > "$TMP"

  echo "VMs enregistrées"
  while IFS= read -r line; do
    NAME="$(echo "$line" | awk -F\" '{print $2}')"
    UUID="$(echo "$line" | awk '{print $NF}' | tr -d '{}')"
    [ "$NAME" = "" ] && continue

    RAW_CREATED="$(VBoxManage getextradata "$NAME" "meta/created_at" 2>/dev/null)"
    RAW_OWNER="$(VBoxManage getextradata "$NAME" "meta/owner" 2>/dev/null)"
    CREATED="$(echo "$RAW_CREATED" | awk -F': ' '/Value/{print $2}')"
    OWNER="$(echo "$RAW_OWNER"   | awk -F': ' '/Value/{print $2}')"

    echo "- $NAME ($UUID)"
    if [ "$CREATED" != "" ] || [ "$OWNER" != "" ]; then
      echo "    created_at: ${CREATED:-N/A}"
      echo "    owner     : ${OWNER:-N/A}"
    fi
  done < "$TMP"
}

# --- Main ---
action="$1"
name="$2"

if [ "$action" = "L" ]; then
  list_vms

elif [ "$action" = "N" ]; then
  if [ "$name" = "" ]; then usage; else create_vm "$name"; fi

elif [ "$action" = "S" ]; then
  if [ "$name" = "" ]; then usage; else delete_vm "$name"; fi

elif [ "$action" = "D" ]; then
  if [ "$name" = "" ]; then usage; else start_vm "$name"; fi

elif [ "$action" = "A" ]; then
  if [ "$name" = "" ]; then usage; else stop_vm "$name"; fi

else
  usage; exit 1
fi

