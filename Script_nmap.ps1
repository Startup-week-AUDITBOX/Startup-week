# V1.3
# Script_nmap.ps1 – Installation de Nmap via Chocolatey + scan automatique

# === CONFIGURATION ===
$nmapExe = $null
$ipListFile = "$HOME\Documents\ip-up-list.txt"
$outputDir = "$HOME\Documents\RapportsNmapVuln"
$htmlDir = Join-Path $outputDir "HTML"

# === VÉRIFICATION DE NMAP ===
Write-Host "Vérification de Nmap..."

# Chercher nmap dans le PATH
$nmapExe = Get-Command nmap.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue

# === INSTALLATION VIA CHOCOLATEY SI ABSENT ===
if (-not $nmapExe) {
    Write-Host "Nmap non trouvé. Installation via Chocolatey..."

    # Vérifier si choco est dispo
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "🛠 Chocolatey non trouvé. Installation de Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }

    # Installer nmap
    Write-Host "Installation de Nmap via Chocolatey..."
    choco install nmap -y --force
    Start-Sleep -Seconds 5

    # Rechercher nmap.exe sur le disque
    Write-Host "Recherche de nmap.exe après installation..."
    $paths = Get-ChildItem "C:\Program Files*" -Recurse -Filter "nmap.exe" -ErrorAction SilentlyContinue |
             Select-Object -ExpandProperty FullName

    foreach ($p in $paths) {
        if (Test-Path $p) {
            $nmapExe = $p
            break
        }
    }
}

# === ÉCHEC DÉFINITIF SI TOUJOURS INTROUVABLE ===
if (-not $nmapExe -or -not (Test-Path $nmapExe)) {
    Write-Error "Nmap introuvable même après installation. Abandon."
    exit
}

Write-Host "Nmap trouvé à : $nmapExe"

# === DEMANDER LA PLAGE IP ===
$ipRange = Read-Host "Entrez la plage IP à scanner (ex : 192.168.1.0/24)"

# === SCAN DE PRÉSENCE ===
Write-Host "Scan de présence..."
$liveFile = "$env:TEMP\nmap-presence.gnmap"
& $nmapExe -sn $ipRange -oG $liveFile

# === EXTRACTION IPs ACTIVES ===
$ipsUp = Select-String "Up" $liveFile | ForEach-Object {
    if ($_ -match "Host:\s+(\d{1,3}(\.\d{1,3}){3})") {
        $matches[1]
    }
}

if (-not $ipsUp) {
    Write-Error "Aucune IP active détectée."
    exit
}

$ipsUp | Set-Content $ipListFile
Write-Host "$($ipsUp.Count) IPs actives enregistrées dans : $ipListFile"

# === CRÉATION DES DOSSIERS ===
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
New-Item -ItemType Directory -Path $htmlDir -Force | Out-Null

# === SCAN AVANCÉ POUR CHAQUE IP ===
foreach ($ip in $ipsUp) {
    $ip = $ip.Trim()
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $outFileTxt = Join-Path $outputDir "scan-$ip-$timestamp.txt"
    $outFileHtml = Join-Path $htmlDir "rapport-$ip-$timestamp.html"

    Write-Host "`n🛠 Scan de ports, OS et vulnérabilités pour $ip..."
    & $nmapExe -A -sV --script vuln -T4 -oN $outFileTxt $ip

    try {
        $txt = Get-Content $outFileTxt -Raw
        $openPorts = ($txt -split "`n") | Where-Object { $_ -match "^\d+/tcp\s+open" } | Out-String
        $vulns = ($txt -split "`n") | Where-Object { $_ -match "VULNERABLE|CVE" } | Out-String

        $htmlContent = @"
<!DOCTYPE html>
<html lang='fr'>
<head>
<meta charset='UTF-8'>
<title>Rapport Nmap $ip</title>
<style>
body { font-family: Arial, sans-serif; background-color: #f9f9f9; color: #333; padding: 20px; }
h1 { color: #0066cc; }
h2 { color: #003366; }
pre { background: #fff; padding: 15px; border: 1px solid #ccc; overflow-x: auto; white-space: pre-wrap; word-wrap: break-word; }
</style>
</head>
<body>
<h1>Rapport de scan pour $ip</h1>
<h2>Ports ouverts et services :</h2>
<pre>$openPorts</pre>
<h2>Vulnérabilités détectées :</h2>
<pre>$vulns</pre>
<h2>Rapport complet brut :</h2>
<pre>$txt</pre>
</body>
</html>
"@

        Set-Content -Path $outFileHtml -Value $htmlContent -Encoding UTF8
        Write-Host "📄 Rapport HTML généré : $outFileHtml"
    }
    catch {
        Write-Warning "⚠Erreur lors de la génération HTML pour $ip"
    }

    Write-Host "✔Scan terminé pour $ip"
}

Write-Host "Tous les rapports sont dans : $outputDir"
Write-Host "HTML lisibles dans : $htmlDir"
