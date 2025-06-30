# 📁 Paramètres manuels
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputFolder = "$PSScriptRoot\ExploitGuardReport"
$inputFile = Get-ChildItem "$outputFolder\ExploitGuard_*.csv" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$htmlFile = "$outputFolder\ExploitGuard_Report_$timestamp.html"

if (-not $inputFile) {
    Write-Error "❌ Aucun fichier CSV trouvé dans $outputFolder"
    exit
}

# 📄 Chargement du fichier CSV
$results = Import-Csv $inputFile.FullName

# 💡 Ajout du niveau de risque
$results | ForEach-Object {
    $missing = 0
    foreach ($key in "Dep", "Aslr", "Cfg", "BinarySignature", "ChildProcess", "DynamicCode", "Sehop") {
        if ($_.($key) -match "Off|Absent|False|NOTSET") {
            $missing++
        }
    }
    Add-Member -InputObject $_ -MemberType NoteProperty -Name "RiskLevel" -Value $missing
}

# 🌐 Génération HTML
$html = @"
<html><head><style>
body { font-family: Arial; background: #f5f5f5; padding: 20px; }
table { border-collapse: collapse; width: 100%; background: #fff; }
th, td { border: 1px solid #ccc; padding: 6px 8px; text-align: center; }
th { background: #0078d4; color: white; }
tr:nth-child(even) { background-color: #f2f2f2; }
.risk-low { background-color: #d4edda; }
.risk-med { background-color: #fff3cd; }
.risk-high { background-color: #f8d7da; }
</style></head><body>
<h2>🛡️ Rapport Exploit Guard – $timestamp</h2>
<table>
<tr>
    <th>Processus</th>
    <th>DEP</th><th>ASLR</th><th>CFG</th><th>Signature</th>
    <th>Child Proc</th><th>Dyn Code</th><th>SEHOP</th>
    <th>Niveau de Risque</th>
</tr>
"@

foreach ($row in $results) {
    $risk = $row.RiskLevel
    $riskClass = if ($risk -le 2) { "risk-low" } elseif ($risk -le 5) { "risk-med" } else { "risk-high" }

    $html += "<tr class='$riskClass'><td>$($row.ProcessName)</td>"
    $html += "<td>$($row.Dep)</td><td>$($row.Aslr)</td><td>$($row.Cfg)</td><td>$($row.BinarySignature)</td>"
    $html += "<td>$($row.ChildProcess)</td><td>$($row.DynamicCode)</td><td>$($row.Sehop)</td>"
    $html += "<td><strong>$risk</strong></td></tr>"
}

$html += "</table></body></html>"

# 💾 Sauvegarde
$html | Out-File -Encoding utf8 -FilePath $htmlFile
Start-Process $htmlFile
Write-Host "✅ Rapport HTML généré : $htmlFile"
