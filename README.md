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

## Auteurs
- BOUKAKA Cécilia, KAMGA Camila – BUT3 R&T – IUT de Rouen 


