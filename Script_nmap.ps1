# V1.2
# === CONFIGURATION ===
$nmapPath = "C:\Program Files (x86)\Nmap\nmap.exe"
$ipListFile = "$HOME\Documents\ip-up-list.txt"
$outputDir = "$HOME\Documents\RapportsNmapVuln"
$htmlDir = Join-Path $outputDir "HTML"

# === VÉRIFICATION NMAP ===
if (-not (Test-Path $nmapPath)) {
    Write-Error "Nmap introuvable à : $nmapPath"
    exit
}

# === DEMANDE PLAGE IP ===
$ipRange = Read-Host "Entrez la plage IP à scanner (ex : 192.168.1.0/24)"

# === SCAN DE PRÉSENCE ===
Write-Host "Scan de présence..."
$liveFile = "$env:TEMP\nmap-presence.gnmap"
& $nmapPath -sn $ipRange -oG $liveFile

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
Write-Host "$($ipsUp.Count) IPs actives enregistrées dans $ipListFile"

# === CRÉATION DES DOSSIERS ===
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
New-Item -ItemType Directory -Path $htmlDir -Force | Out-Null

# === SCAN COMPLET POUR CHAQUE IP ===
foreach ($ip in $ipsUp) {
    $ip = $ip.Trim()
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $outFileTxt = Join-Path $outputDir "scan-$ip-$timestamp.txt"
    $outFileHtml = Join-Path $htmlDir "rapport-$ip-$timestamp.html"

    Write-Host "Scan de ports, OS et vulnérabilités pour $ip..."
    & $nmapPath -A -sV --script vuln -T4 -oN $outFileTxt $ip

    try {
        $txt = Get-Content $outFileTxt -Raw
        $openPorts = ($txt -split "\n") | Where-Object { $_ -match "^\d+/tcp\s+open" } | Out-String
        $vulns = ($txt -split "\n") | Where-Object { $_ -match "VULNERABLE|CVE" } | Out-String

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
        Write-Host "Rapport client lisible : $outFileHtml"
    } catch {
        Write-Warning "Échec génération HTML pour $ip"
    }

    Write-Host "Scan terminé pour $ip"
}

Write-Host "Tous les rapports sont disponibles dans : $outputDir"
Write-Host "HTML lisibles dans : $htmlDir"
