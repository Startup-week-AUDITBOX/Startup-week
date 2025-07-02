# V1
# Script_lancement.ps1

# Vérifier si on est en mode admin
$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
$admin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $admin) {
    Write-Host "Redémarrage du script en mode administrateur..."
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# À partir d'ici, on est bien en mode administrateur
Write-Host "Script lancé en mode administrateur."
Set-Location -Path $PSScriptRoot

# Débloquer les scripts
Unblock-File "$PSScriptRoot\Script_pingcastle.ps1"
Unblock-File "$PSScriptRoot\Script_nmap.ps1"

# Lancer PingCastle
Write-Host "`n--- Lancement de Script_pingcastle.ps1 ---`n"
try {
    & "$PSScriptRoot\Script_pingcastle.ps1"
    Write-Host "Script PingCastle terminé.`n"
}
catch {
    Write-Host "Erreur dans Script_pingcastle.ps1 : $_`n"
}

# Lancer Nmap
Write-Host "`n--- Lancement de Script_nmap.ps1 ---`n"
try {
    & "$PSScriptRoot\Script_nmap.ps1"
    Write-Host "Script Nmap terminé."
}
catch {
    Write-Host "Erreur dans Script_nmap.ps1 : $_"
}
