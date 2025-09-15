# SAE51 – Gestion de machines virtuelles avec VirtualBox

## contexte
Ce projet a été réalisé dans le cadre de la SAE51 (BUT Réseaux & Télécoms – IUT de Rouen, 2025). 
L’objectif est d’automatiser la gestion de machines virtuelles (VMs) VirtualBox à l’aide de scripts Bash.

## Fonctionnalités principales
- Création automatique de VM (Debian 64 bits, disque local `.vdi`)
- Configuration mémoire, CPU, VRAM, réseau (NAT)
- Attachement automatique d’un ISO (Ubuntu ou Debian)
- Suppression, démarrage, arrêt (ACPI/poweroff) d’une VM
- Gestion via  "rguments" : 
  - `L` → liste les VMs (avec métadonnées date/auteur) 
  - `N <Nom>` → crée une VM 
  - `S <Nom>` → supprime une VM 
  - `D <Nom>` → démarre une VM 
  - `A <Nom>` → arrête une VM 

## Organisation du dépôt
- `genMV.sh` → script principal (gestion VMs + métadonnées)
- `usage.md` → guide utilisateur et retour d’expérience
- `versions/` → versions intermédiaires (V1 à V4)
- `iso/` → ISO téléchargés (non inclus dans GitHub)

## Dossier `iso/`

Le dossier `iso/` est prévu pour stocker localement les images ISO nécessaires à l’installation
ou au test des machines virtuelles (par ex. `debian-12.x-amd64-netinst.iso`, `ubuntu-22.04.iso`).

#Important :
- Ce dossier n’est "pas versionné" dans GitHub (exclu via `.gitignore`), car les fichiers ISO sont trop volumineux. 
- Chaque utilisateur doit télécharger ses propres images ISO et les placer manuellement dans `iso/`. 
- Exemple : 
  'bash'
  ~/SAE51/iso/ubuntu-22.04.5-desktop-amd64.iso


## Auteurs
- BOUKAKA Cécilia, KAMGA Camila – BUT3 R&T – IUT de Rouen 


