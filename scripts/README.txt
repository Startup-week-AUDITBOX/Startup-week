# AuditBox - Kit d'Audit Automatisé

## Description
Ce kit d'audit automatisé vous permet d'effectuer un audit de sécurité, réseau et infrastructure de votre environnement en quelques minutes.

## Contenu du Kit
- `Auditbox.ps1` : Script principal à exécuter  
- `data/` : Dossier contenant les scripts spécialisés et votre configuration  
  - `script_nmap.ps1` : Script d'audit réseau  
  - `script_pingcastle.ps1` : Script d'audit sécurité  
  - `data_client.csv` : Vos données de configuration  

## Prérequis
- Windows PowerShell 5.0 ou supérieur  
- Droits administrateur  
- Connexion internet pour télécharger les outils nécessaires  

---

## Étapes d'exécution depuis le serveur

1. Après avoir télécharger le dossier via le site web  
2. Décompresser le dossier  
3. Ouvrir le dossier décompressé et vérifier que le fichier `Auditbox.ps1` est bien présent  
4. Faire un clic droit sur `Auditbox.ps1` et sélectionner **Exécuter avec PowerShell**  
5 (facultatif). **Si le clic droit ne fonctionne pas** :  
   - Ouvrir PowerShell en tant qu'administrateur  
   - Se déplacer dans le dossier contenant le script avec la commande :  
     ```powershell
     cd "chemin\\vers\\le\\dossier\\AuditBox"
     ```
   - Lancer le script avec :  
     ```powershell
     .\\Auditbox.ps1
     ```

---

## Étapes d'exécution depuis un poste client

1. Après avoir télécharger le dossier via le site web 
2. Se connecter avec un utilisateur administrateur au serveur Windows de votre choix dans le domaine  
3. Copier le dossier téléchargé depuis votre poste et le coller dans le dossier souhaité sur le serveur via l'explorateur Windows  
4. Décompresser le dossier  
5. Ouvrir le dossier décompressé et vérifier que le fichier `Auditbox.ps1` est bien présent  
6. Faire un clic droit sur `Auditbox.ps1` et sélectionner **Exécuter avec PowerShell**  
7 (facultatif). **Si le clic droit ne fonctionne pas** :  
   - Ouvrir PowerShell en tant qu'administrateur  
   - Se déplacer dans le dossier contenant le script avec la commande :  
     ```powershell
     cd "chemin\\vers\\le\\dossier\\AuditBox"
     ```
   - Lancer le script avec :  
     ```powershell
     .\\Auditbox.ps1
     ```

---



AuditBox - Audit de sécurité accessible à tous  
© 2025 AuditBox. Tous droits réservés.
