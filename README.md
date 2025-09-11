#README.md
# SAE51 — Automatisation VirtualBox (BUT R&T)

Ce projet contient un script `genMV.sh` permettant d’automatiser la gestion de machines virtuelles sous VirtualBox. 
Il s’inscrit dans le cadre de la SAE51 (BUT Réseaux & Télécommunications).

## Fonctionnalités
- Création et configuration automatique de VMs (RAM, CPU, disque…)
- Démarrage, arrêt et suppression de VMs
- Attachement/éjection d’images ISO (ex : Debian netinst)
- Gestion des métadonnées (date de création, auteur)
- Support PXE (netboot Debian)

## Organisation du dépôt
- `genMV.sh` : script principal
- `versions/` : anciennes versions intermédiaires (V1 à V4)
- `iso/` : dossier pour placer vos images ISO (`.iso`)
- `README.md` : présentation rapide du projet
- `usage.md` : guide d’utilisation détaillé

## Auteur
- Cécilia Emmanuelle Boukaka , Camila Kamga
BUT2 Réseaux & Télécoms — IUT de Rouen (site d’Elbeuf)

