# Guide d’utilisation – Script genMV.sh

Auteurs : BOUKAKA Cécilia, KAMGA Camila
Date : septembre 2025 

## Résumé
Ce document décrit l’utilisation du script `genMV.sh`, développé pour automatiser la création et la gestion de machines virtuelles sous VirtualBox. 
Le script gère la création de VMs Debian/Ubuntu, leur configuration, l’attachement d’ISO et l’ajout de métadonnées (date et auteur). 
Il inclut aussi les fonctions de suppression, démarrage et arrêt. 
Nous présentons ici la manière de l’utiliser, ses limites et les problèmes rencontrés.

---

1. Utilisation
Rendre le script exécutable :

#bash
chmod +x genMV.sh


#Commandes disponibles :

./genMV.sh L              # Lister toutes les VMs
./genMV.sh N Debian1      # Créer une VM Debian1
./genMV.sh D Debian1      # Démarrer Debian1
./genMV.sh A Debian1      # Arrêter Debian1
./genMV.sh S Debian1      # Supprimer Debian1


2. Métadonnées

Chaque VM créée contient des métadonnées stockées via VBoxManage setextradata :

Date de création

Auteur / utilisateur

Ces informations sont affichées avec ./genMV.sh L.


3. Limites

Le disque .vdi est créé dans le répertoire courant (./NomVM.vdi), et non dans le dossier par défaut de VirtualBox.

L’ISO doit être présent dans le chemin indiqué dans le script ($HOME/SAE51_Test/iso/...).

Le script suppose que VirtualBox et VBoxManage sont installés et accessibles dans le PATH.


4. Problèmes rencontrés

Gestion des chemins : initialement configuré dans ~/VirtualBox VMs/, modifié pour simplifier.

Différences entre arrêt ACPI (propre) et poweroff (forcé).

Parsing des métadonnées : nécessité d’utiliser awk pour extraire proprement les valeurs.

Nettoyage automatique du fichier temporaire lors du listing.


5. Évolutions possibles

Ajouter le mode headless (démarrage sans GUI).

Intégrer une installation Debian automatisée via fichier preseed.

