# genMV_V4.sh — Version 4 corrigée (FR)


# Paramètres par défaut

RAM=4096            # MiB
DISK=65536          # MiB (64 Gio)
CPU=1
VRAM=128
OSTYPE="Debian_64"
BOOT_NET_FIRST=1    # 1 = boot PXE en premier


# Vérification VirtualBox
if ! type -P VBoxManage >/dev/null 2>&1; then
  echo "Erreur : VBoxManage introuvable. Installe VirtualBox ou ajoute-le au PATH."
  exit 1
fi

# Dossier TFTP (PXE, Q3)

if   [ -d "$HOME/.config/VirtualBox" ]; then VB_DIR="$HOME/.config/VirtualBox"
elif [ -d "$HOME/.VirtualBox" ];       then VB_DIR="$HOME/.VirtualBox"
else VB_DIR="$HOME/.config/VirtualBox"; mkdir -p "$VB_DIR"
fi
TFTP_DIR="$VB_DIR/TFTP"


# Aides de base (Q2)

vm_existe()   { VBoxManage list vms        | grep -q "^\"$1\" "; }
vm_en_cours() { VBoxManage list runningvms | grep -q "^\"$1\" "; }


# PXE (Q3)
preparer_pxe() {
  mkdir -p "$TFTP_DIR"
  if [ ! -f "$TFTP_DIR/pxelinux.0" ]; then
    echo "Téléchargement netboot Debian (bookworm, amd64)…"
    local URL="http://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/netboot/netboot.tar.gz"
    local TAR="$TFTP_DIR/netboot.tar.gz"
    if   type -P curl >/dev/null 2>&1; then curl -L -o "$TAR" "$URL"
    elif type -P wget >/dev/null 2>&1; then wget -O "$TAR" "$URL"
    else
      echo "⚠ Ni curl ni wget : dépose netboot.tar.gz dans $TFTP_DIR puis : tar -xzf netboot.tar.gz"
      return
    fi
    tar -xzf "$TAR" -C "$TFTP_DIR" || { echo "Erreur : extraction de netboot.tar.gz échouée."; exit 1; }
    rm -f "$TAR"
  fi
}

lier_pxe_vm() {
  local VM="$1"
  if [ -f "$TFTP_DIR/pxelinux.0" ]; then
    ln -sfn pxelinux.0 "$TFTP_DIR/$VM.pxe"
  else
    echo "⚠ pxelinux.0 absent : le boot PXE peut ne pas fonctionner."
  fi
}

# Q5 : Liste + métadonnées
list_with_meta() {
  echo "=== VMs & métadonnées (Q5) ==="
  VBoxManage list vms | while read -r line; do
    NAME="$(echo "$line" | cut -d'"' -f2)"
    RAW_D="$(VBoxManage getextradata "$NAME" CreationDate 2>/dev/null || true)"
    RAW_U="$(VBoxManage getextradata "$NAME" CreatedBy    2>/dev/null || true)"
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



creer_vm() {
  local VM="$1"
  if vm_existe "$VM"; then
    echo "Erreur : la VM '$VM' existe déjà."
    exit 1
  fi

  echo "Création de la VM '$VM' (type=$OSTYPE)…"
  VBoxManage createvm --name "$VM" --ostype "$OSTYPE" --register || { echo "Erreur : création VM."; exit 1; }

  echo "Configuration RAM/CPU/VRAM + NAT…"
  VBoxManage modifyvm "$VM" --memory "$RAM" --cpus "$CPU" --vram "$VRAM" --nic1 nat || { echo "Erreur : config VM."; exit 1; }

  if [ "$BOOT_NET_FIRST" -eq 1 ]; then
    echo "Boot PXE en premier…"
    VBoxManage modifyvm "$VM" --boot1 net --boot2 disk --boot3 none --boot4 none || { echo "Erreur : ordre de boot."; exit 1; }
  else
    VBoxManage modifyvm "$VM" --boot1 disk --boot2 net --boot3 none --boot4 none || { echo "Erreur : ordre de boot."; exit 1; }
  fi

  local VMDIR="$HOME/VirtualBox VMs/$VM"
  local VDI="$VMDIR/$VM.vdi"
  echo "Disque 64 Gio + contrôleur SATA…"
  mkdir -p "$VMDIR"
  VBoxManage createhd --filename "$VDI" --size "$DISK" --format VDI >/dev/null || { echo "Erreur : création disque."; exit 1; }
  VBoxManage storagectl "$VM" --name "SATA" --add sata --controller IntelAhci || { echo "Erreur : contrôleur SATA."; exit 1; }
  VBoxManage storageattach "$VM" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "$VDI" || { echo "Erreur : attache disque."; exit 1; }

  # --- Métadonnées Q5 ---
  set_metadata "$VM"

  # Préparer PXE (Q3)
  preparer_pxe
  lier_pxe_vm "$VM"

  echo "VM '$VM' créée."
}

demarrer_vm() {
  local VM="$1"
  vm_existe "$VM" || { echo "Erreur : VM '$VM' introuvable."; exit 1; }
  # Démarrage + message clair si VT-x/AMD-V indisponible
  if ! out="$(VBoxManage startvm "$VM" --type gui 2>&1)"; then
    echo "$out"
    if echo "$out" | grep -q 'VERR_VMX_NO_VMX'; then
      echo "⚠ Virtualisation matérielle non disponible (VT-x/AMD-V)."
      echo "  - Si tu es DANS une VM : activer la virtualisation imbriquée (nested) sur la VM hôte."
      echo "  - Sur PC physique : activer VT-x/AMD-V dans le BIOS/UEFI et fermer les autres hyperviseurs."
    fi
    exit 1
  fi
}

arreter_vm() {
  local VM="$1"
  vm_existe "$VM" || { echo "Erreur : VM '$VM' introuvable."; exit 1; }
  if vm_en_cours "$VM"; then
    echo "[*] Arrêt via ACPI…"
    VBoxManage controlvm "$VM" acpipowerbutton || true
    for _ in {1..30}; do vm_en_cours "$VM" || break; sleep 1; done
    if vm_en_cours "$VM"; then
      echo "Arrêt forcé (poweroff)…"
      VBoxManage controlvm "$VM" poweroff
    fi
  else
    echo "La VM n'est pas en cours d'exécution."
  fi
}

supprimer_vm() {
  local VM="$1"
  if vm_existe "$VM"; then
    vm_en_cours "$VM" && arreter_vm "$VM"
    VBoxManage unregistervm "$VM" --delete || { echo "Erreur : suppression VM."; exit 1; }
    rm -rf "$HOME/VirtualBox VMs/$VM" 2>/dev/null || true
    echo "VM '$VM' supprimée."
  else
    echo "VM '$VM' introuvable."
  fi
}


lister_avec_meta() {
  echo "=== VMs & métadonnées (Q5) ==="
  local lines vm d u
  lines="$(VBoxManage list vms || true)"
  [ -z "$lines" ] && { echo "(Aucune VM enregistrée)"; return; }

  while IFS= read -r line; do
    [ -z "$line" ] && continue
    vm="$(printf '%s' "$line" | cut -d'"' -f2)"
    d="$(_lire_meta "$vm" CreationDate)"; [ -z "$d" ] && d="Unknown"
    u="$(_lire_meta "$vm" CreatedBy)";   [ -z "$u" ] && u="Unknown"
    echo "VM: $vm"
    echo "  Creation : $d"
    echo "  By       : $u"
    echo
  done <<EOF
$lines
EOF
}

# Démo Q1 (création -> pause -> suppression)

demo_q1() {
  local VM="Debian1"
  if vm_existe "$VM"; then
    VBoxManage unregistervm "$VM" --delete || true
    rm -rf "$HOME/VirtualBox VMs/$VM" 2>/dev/null || true
  fi
  creer_vm "$VM"
  echo
  echo "PAUSE : vérifie dans la GUI VirtualBox… suppression dans 5 secondes."
  sleep 5
  supprimer_vm "$VM"
}


# (Q4)

afficher_usage() {
  cat <<EOF
Usage :
  $0 Q1            # Démo : créer 'Debian1' -> pause 5s -> supprimer
  $0 L             # Lister les VMs + métadonnées
  $0 N <vm>        # Créer une VM
  $0 D <vm>        # Démarrer une VM (GUI)
  $0 A <vm>        # Arrêter une VM (ACPI puis poweroff)
  $0 S <vm>        # Supprimer une VM (+ fichiers)
  $0 M <vm>        # (Ré)appliquer les métadonnées sur une VM existante
EOF
}


# Dispatch

ACTION="${1:-}"
NOM_VM="${2:-}"

if [ "$ACTION" = "Q1" ]; then
  demo_q1

elif [ "$ACTION" = "L" ]; then
  lister_avec_meta

elif [ "$ACTION" = "N" ]; then
  [ -n "$NOM_VM" ] || { afficher_usage; exit 1; }
  creer_vm "$NOM_VM"

elif [ "$ACTION" = "D" ]; then
  [ -n "$NOM_VM" ] || { afficher_usage; exit 1; }
  demarrer_vm "$NOM_VM"

elif [ "$ACTION" = "A" ]; then
  [ -n "$NOM_VM" ] || { afficher_usage; exit 1; }
  arreter_vm "$NOM_VM"

elif [ "$ACTION" = "S" ]; then
  [ -n "$NOM_VM" ] || { afficher_usage; exit 1; }
  supprimer_vm "$NOM_VM"

elif [ "$ACTION" = "M" ]; then
  [ -n "$NOM_VM" ] || { afficher_usage; exit 1; }
  reparer_meta_vm "$NOM_VM"

else
  afficher_usage
fi


