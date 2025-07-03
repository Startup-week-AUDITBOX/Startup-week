# V1.2
# Script_lancement.ps1 — Version finale avec popup de fin

# Se positionner dans le dossier du script
Set-Location -Path $PSScriptRoot
Write-Host "📁 Répertoire d'exécution : $PSScriptRoot"

# Débloquer les scripts si besoin
Unblock-File "$PSScriptRoot\data\Script_pingcastle.ps1"
Unblock-File "$PSScriptRoot\data\Script_nmap.ps1"

# === Lancer PingCastle ===
Write-Host "`n--- Lancement de Script_pingcastle.ps1 ---`n"
try {
    & "$PSScriptRoot\data\Script_pingcastle.ps1"
    Write-Host "`n✅ Script PingCastle terminé.`n"
}
catch {
    Write-Host "`n❌ Erreur dans Script_pingcastle.ps1 : $_`n"
}

# === Lancer Nmap ===
Write-Host "`n--- Lancement de Script_nmap.ps1 ---`n"
try {
    & "$PSScriptRoot\data\Script_nmap.ps1"
    Write-Host "`n✅ Script Nmap terminé.`n"
}
catch {
    Write-Host "`n❌ Erreur dans Script_nmap.ps1 : $_`n"
}

# === Afficher une popup de confirmation ===
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show(
    "Les rapports sont disponibles dans votre dossiers Documents.",
    "Rapports générés",
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information
)
