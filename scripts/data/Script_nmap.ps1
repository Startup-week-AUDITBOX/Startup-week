# V1.6
# Script_nmap.ps1 – Scan Nmap consolidé sans rapport brut dans le HTML

# === CONFIGURATION ===
$nmapExe = $null
$dataCsvPath = "$PSScriptRoot\data_client.csv"
$ipListFile = "$HOME\Documents\ip-up-list.txt"
$outputDir = "$HOME\Documents\RapportsNmapVuln"
$htmlReportPath = Join-Path $outputDir "rapport-global.html"
$liveFile = "$env:TEMP\nmap-presence.gnmap"

# === VÉRIFICATION DE NMAP ===
Write-Host "`n🔍 Vérification de Nmap..."
$nmapExe = Get-Command nmap.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue

if (-not $nmapExe) {
    Write-Host "❌ Nmap non trouvé. Installation via Chocolatey..."

    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "🛠 Installation de Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }

    Write-Host "📦 Installation de Nmap..."
    choco install nmap -y --force
    Start-Sleep -Seconds 5

    $paths = Get-ChildItem "C:\Program Files*" -Recurse -Filter "nmap.exe" -ErrorAction SilentlyContinue |
             Select-Object -ExpandProperty FullName

    foreach ($p in $paths) {
        if (Test-Path $p) {
            $nmapExe = $p
            break
        }
    }
}

if (-not $nmapExe -or -not (Test-Path $nmapExe)) {
    Write-Error "❌ Nmap introuvable. Abandon."
    exit
}
Write-Host "✅ Nmap trouvé à : $nmapExe"

# === LECTURE CSV ===
if (-not (Test-Path $dataCsvPath)) {
    Write-Error "❌ Fichier CSV introuvable à $dataCsvPath"
    exit
}

Write-Host "`n📄 Lecture des plages IP depuis le CSV..."
$csv = Import-Csv -Path $dataCsvPath -Delimiter ','

$plagesIP = @()
foreach ($entry in $csv) {
    if ($entry."Plages IP") {
        $entry."Plages IP" -split ';' | ForEach-Object {
            $_.Trim('"') -replace '"$','' | ForEach-Object { $plagesIP += $_ }
        }
    }
}

if (-not $plagesIP) {
    Write-Error "❌ Aucune plage IP valide trouvée dans le CSV."
    exit
}

Write-Host "`n✅ Plages IP extraites :"
$plagesIP | ForEach-Object { Write-Host " - $_" }

# === SCAN DE PRÉSENCE ===
if (Test-Path $liveFile) { Remove-Item $liveFile -Force }
Write-Host "`n🔎 Scan de présence..."

foreach ($range in $plagesIP) {
    Write-Host " 🔄 Scan de $range ..."
    & $nmapExe -sn $range -oG $liveFile -append
}

$ipsUp = Select-String "Up" $liveFile | ForEach-Object {
    if ($_ -match "Host:\s+(\d{1,3}(\.\d{1,3}){3})") {
        $matches[1]
    }
}

if (-not $ipsUp) {
    Write-Error "❌ Aucune IP active détectée."
    exit
}
$ipsUp | Set-Content $ipListFile
Write-Host "`n✅ IPs actives : $($ipsUp.Count) enregistrées dans : $ipListFile"

# === DOSSIER DE SORTIE ===
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

# === INITIALISATION DU HTML FINAL ===
$htmlHeader = @"
<!DOCTYPE html>
<html lang='fr'>
<head>
<meta charset='UTF-8'>
<title>Rapport Nmap Global</title>
<style>
body { font-family: Arial, sans-serif; background-color: #f9f9f9; color: #333; padding: 20px; }
h1 { color: #0066cc; }
h2 { color: #003366; }
pre { background: #fff; padding: 15px; border: 1px solid #ccc; overflow-x: auto; white-space: pre-wrap; word-wrap: break-word; }
hr { margin: 30px 0; }
</style>
</head>
<body>
<h1>Rapport Nmap – Résultats consolidés</h1>
<p>Scan réalisé le $(Get-Date -Format "dd/MM/yyyy HH:mm")</p>
"@

$htmlBody = ""

# === SCAN PAR IP AVEC CONTENU HTML RÉDUIT ===
foreach ($ip in $ipsUp) {
    $ip = $ip.Trim()
    Write-Host "`n🛠 Scan avancé pour $ip..."
    $outFileTxt = Join-Path $outputDir "scan-$ip.txt"
    & $nmapExe -A -sV --script vuln -T4 -oN $outFileTxt $ip

    try {
        $txt = Get-Content $outFileTxt -Raw
        $openPorts = ($txt -split "`n") | Where-Object { $_ -match "^\d+/tcp\s+open" } | Out-String
        $vulns = ($txt -split "`n") | Where-Object { $_ -match "VULNERABLE|CVE" } | Out-String

        $htmlBody += @"
<hr>
<h2>Résultats pour $ip</h2>
<h3>Ports ouverts et services :</h3>
<pre>$openPorts</pre>
<h3>Vulnérabilités détectées :</h3>
<pre>$vulns</pre>
"@
    }
    catch {
        Write-Warning "⚠️ Erreur lors du traitement de $ip"
    }

    Write-Host "✔️ Scan terminé pour $ip"
}

$htmlFooter = @"
</body>
</html>
"@

$htmlFull = $htmlHeader + $htmlBody + $htmlFooter
Set-Content -Path $htmlReportPath -Value $htmlFull -Encoding UTF8

Write-Host "`n📄 Rapport HTML généré (sans rapport brut) : $htmlReportPath"