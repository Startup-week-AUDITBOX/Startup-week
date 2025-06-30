# V1.1
# ========= ADMIN CHECK =========
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "🔐 Redémarrage en mode administrateur..."
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}
 
# ========= DEMANDE PLAGE IP =========
$ipRange = Read-Host "Entrez la plage d'adresses IP à scanner (ex: 192.168.1.0/24)"
 
# ========= DÉTECTION / INSTALLATION NMAP =========
$nmapExe = $null
 
try {
    $cmd = Get-Command nmap -ErrorAction SilentlyContinue
    if ($cmd) { $nmapExe = $cmd.Source }
} catch {}
 
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
 
# ========= DOSSIER DE RAPPORT =========
$reportDir = Join-Path $HOME "Documents\RapportsNmap"
New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
 
# ========= SCAN DES HÔTES ACTIFS =========
$liveFile = Join-Path $reportDir "hosts-up.txt"
Write-Host "`Détection des hôtes actifs dans $ipRange..."
& $nmapExe -sn $ipRange -oG $liveFile
 
# ========= EXTRACTION DES IP's UP =========
$targets = Select-String "Up" $liveFile | ForEach-Object {
    if ($_ -match "Host:\s+(\d{1,3}(\.\d{1,3}){3})") {
        $matches[1]
    }
}
 
if (-not $targets) {
    Write-Host "Aucun hôte actif détecté dans la plage."
    exit
}
 
# Enregistre les IP's UP dans un fichier TXT propre
$upList = Join-Path $reportDir "ip-up-list.txt"
$targets | Out-File -Encoding ascii $upList
 
# ========= SCAN GLOBAL DE TOUS LES HÔTES UP =========
$dateStr = Get-Date -Format "yyyyMMdd-HHmmss"
$xmlFile = Join-Path $reportDir "nmap-result-$dateStr.xml"
$htmlFile = Join-Path $reportDir "nmap-report-$dateStr.html"
 
Write-Host "Scan rapide global en cours..."
& $nmapExe -F -T4 -Pn -oX $xmlFile $targets
 
# ========= CONVERSION XML VERS HTML =========
$xslPath = Join-Path (Split-Path $nmapExe) "nmap.xsl"
 
if ((Test-Path $xslPath) -and (Test-Path $xmlFile)) {
    try {
        $readerSettings = New-Object System.Xml.XmlReaderSettings
        $readerSettings.DtdProcessing = "Parse"
        $reader = [System.Xml.XmlReader]::Create($xmlFile, $readerSettings)
 
        $writer = New-Object System.IO.StreamWriter($htmlFile)
        $xslt = New-Object System.Xml.Xsl.XslCompiledTransform
        $xslt.Load($xslPath)
        $xslt.Transform($reader, $null, $writer)
        $writer.Close()
        $reader.Close()
 
        Write-Host "Rapport HTML généré : $htmlFile"
        Start-Process $htmlFile
    } catch {
        Write-Warning "Erreur lors de la conversion HTML : $($_.Exception.Message)"
    }
} else {
    Write-Warning "Impossible de générer le rapport HTML (XSL ou XML manquant)."
}
 
# ========= FIN =========
Write-Host "Tous les rapports sont disponibles dans : $reportDir"
