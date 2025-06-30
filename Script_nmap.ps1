# V1
# ========= ADMIN CHECK =========
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Redémarrage en mode administrateur..."
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}
 
# ========= DEMANDE PLAGE IP =========
$ipRange = Read-Host "Entrez la plage d'adresses IP à scanner (ex: 192.168.1.0/24)"
 
# ========= DÉTECTION / INSTALLATION NMAP =========
$nmapExe = $null
 
# 1. Via Get-Command
try {
    $cmd = Get-Command nmap -ErrorAction SilentlyContinue
    if ($cmd) { $nmapExe = $cmd.Source }
} catch {}
 
# 2. Recherche dans emplacements connus
if (-not $nmapExe) {
    $paths = @(
        "C:\Program Files (x86)\Nmap\nmap.exe",
        "C:\Program Files\Nmap\nmap.exe",
        "C:\ProgramData\chocolatey\lib\nmap\tools\nmap.exe"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) {
            $nmapExe = $p
            break
        }
    }
}
 
# 3. Installation si toujours non trouvé
if (-not $nmapExe) {
    Write-Host "Nmap non trouvé. Installation via Chocolatey..."
 
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "🛠 Installation de Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }
 
    choco install nmap -y --force
    Start-Sleep -Seconds 5
 
    # Recherche après install
    $paths += Get-ChildItem "C:\Program Files*" -Recurse -Filter "nmap.exe" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
    foreach ($p in $paths) {
        if (Test-Path $p) {
            $nmapExe = $p
            break
        }
    }
}
 
if (-not $nmapExe) {
    Write-Error "Nmap introuvable même après installation. Abandon."
    exit
}
 
# ========= CRÉATION DOSSIER RAPPORT =========
$reportDir = Join-Path $HOME "Documents\RapportsNmap"
New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
 
# ========= SCAN HÔTES ACTIFS =========
$liveFile = Join-Path $reportDir "live-hosts.txt"
Write-Host "Détection des hôtes actifs dans $ipRange..."
& $nmapExe -sn $ipRange -oG $liveFile
 
# Extraction des IPs "Up"
$targets = Select-String "Up" $liveFile | ForEach-Object {
    if ($_ -match "Host:\s+(\d{1,3}(\.\d{1,3}){3})") {
        $matches[1]
    }
}
 
 
if (-not $targets) {
    Write-Host "Aucun hôte actif détecté dans la plage."
    exit
}
 
# ========= SCAN RAPIDE DE CHAQUE HÔTE =========
foreach ($target in $targets) {
    Write-Host "`n➡ Scan rapide de $target"
    $dateStr = Get-Date -Format "yyyyMMdd-HHmmss"
    $xmlFile = Join-Path $reportDir "scan-$($target.Replace(':','-'))-$dateStr.xml"
 
    try {
& $nmapExe -F -T4 -Pn -oX $xmlFile $target
        Write-Host "Résultat enregistré : $xmlFile"
    } catch {
        Write-Warning "Échec du scan pour $target"
    }
}
 
# ========= OUVERTURE DU DOSSIER =========
Write-Host "Scan terminé. Tous les rapports sont enregistrés dans : $reportDir"
Start-Process "explorer.exe" -ArgumentList "`"$reportDir`""
