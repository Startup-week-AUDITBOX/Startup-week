# V1.1
# URL et chemins
$pingCastleUrl = "https://github.com/netwrix/pingcastle/releases/download/3.3.0.1/PingCastle_3.3.0.1.zip"
$downloadPath = "C:\Users\Administrator\Downloads\PingCastle_3.3.0.1.zip"
$unzipPath = "C:\Users\Administrator\Downloads\PingCastle_3.3.0.1"
$outputDir = "$env:USERPROFILE\Documents\Rapports_PingCastle"

# Créer les dossiers si besoin
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# Supprimer l'ancien dossier s'il existe déjà
if (Test-Path $unzipPath) {
    Remove-Item -Path $unzipPath -Recurse -Force
}

# Télécharger PingCastle
Write-Host "Téléchargement de PingCastle..."
Invoke-WebRequest -Uri $pingCastleUrl -OutFile $downloadPath

# Décompresser dans le bon dossier
Expand-Archive -Path $downloadPath -DestinationPath $unzipPath -Force

# Vérification
if (-not (Test-Path "$unzipPath\PingCastle.exe")) {
    Write-Error "L’exécutable PingCastle n’a pas été trouvé après extraction."
    exit 1
}

# Exécuter PingCastle
Write-Host "Exécution de PingCastle..."
Set-Location $outputDir
& "$unzipPath\PingCastle.exe" --healthcheck --datefile


Write-Host "✅ Rapport généré dans : $outputDir"
