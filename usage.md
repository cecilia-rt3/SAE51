#usage.md
# Guide d’utilisation du script `genMV.sh`

**Auteur :** Cécilia Emmanuelle Boukaka 
**Date :** 11/09/2025 

## Résumé
Ce document décrit la manière d’utiliser le script `genMV.sh` développé dans le cadre de la SAE51 (BUT R&T). 
Il permet de créer, configurer et gérer des machines virtuelles VirtualBox via la ligne de commande. 
Les fonctionnalités incluent la gestion des ISO, l’initialisation PXE et la pose de métadonnées. 
Des limites sont toutefois présentes (nécessité d’activer la virtualisation matérielle).

---

## Utilisation du script

### Commandes disponibles
#bash
./genMV.sh Q1             # Démo (crée 'Debian1' puis supprime après 5s)
./genMV.sh L              # Lister les VMs + métadonnées
./genMV.sh N <vm>         # Créer une nouvelle VM
./genMV.sh D <vm>         # Démarrer une VM (GUI)
./genMV.sh A <vm>         # Arrêter une VM
./genMV.sh S <vm>         # Supprimer une VM
./genMV.sh I <vm> <iso>   # Insérer un ISO et booter dessus

Exemple :

./genMV.sh I MonServeur ~/Téléchargements/debian-12.8.0-amd64-netinst.iso

Attache l'ISO à la VM et la démarre pour installation.
Fonctionnalités automatiques
Support PXE (Q3)

    Téléchargement automatique des fichiers netboot Debian Trixie
    Configuration TFTP dans ~/.config/VirtualBox/TFTP/
    Création automatique de liens PXE pour chaque VM

Métadonnées (Q5)

Chaque VM créée contient automatiquement :

    Date de création
    Nom de l'utilisateur créateur

Gestion des erreurs

    Vérification de l'existence des VMs
    Vérification de l'état (running/stopped)
    Validation des fichiers ISO
    Gestion gracieuse des échecs

Exemples d'utilisation typiques
Workflow complet d'installation Debian

# 1. Créer la VM
./genMV.sh N DebianServeur

# 2. Installer Debian via ISO
./genMV.sh I DebianServeur ~/debian-12.8.0-amd64-netinst.iso


Limites connues

Le script nécessite VirtualBox installé et accessible dans le $PATH.

La virtualisation matérielle (VT-x/AMD-V) doit être activée dans le BIOS/UEFI.
Dans un environnement en VM (TP), il faut que l’hôte autorise la virtualisation imbriquée.

Le support PXE nécessite une connexion internet lors du premier lancement.


Problèmes rencontrés

Erreur VERR_VMX_NO_VMX : virtualisation non disponible.

Métadonnées parfois manquantes si la VM est créée à la main (corrigé avec ./genMV.sh M <vm>).

Gestion des ISO : fonctionne uniquement si le chemin est correct.

