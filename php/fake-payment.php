<?php
session_start();

$data = $_SESSION['client_data'] ?? null;
if (!$data) {
    die("Aucune donnée de formulaire détectée.");
}

// Crée un répertoire temporaire
$tmpDir = sys_get_temp_dir() . "/audit_" . time();
mkdir($tmpDir . "/data", 0777, true);

// Copie les fichiers
copy("../scripts/Auditbox.ps1", "$tmpDir/Auditbox.ps1");
copy("../scripts/data/Script_nmap.ps1", "$tmpDir/data/Script_nmap.ps1");
copy("../scripts/data/Script_pingcastle.ps1", "$tmpDir/data/Script_pingcastle.ps1");
copy("../scripts/README.txt", "$tmpDir/README.txt");

// Crée le CSV
$csv = fopen("$tmpDir/data/data_client.csv", 'w');
fputcsv($csv, [
    "Entreprise",
    "Prénom du contact",
    "Nom du contact",
    "Email",
    "Plages IP",
    "Audit réseau",
    "Audit sécurité",
    "Audit infrastructure",
    "Date de génération"
]);

$ipRanges = is_array($data['ipRanges']) ? implode(" | ", $data['ipRanges']) : $data['ipRanges'];
fputcsv($csv, [
    $data['company'] ?? '',
    $data['firstName'] ?? '',
    $data['lastName'] ?? '',
    $data['email'] ?? '',
    $ipRanges,
    "Non",
    "Non",
    "Oui",
    date('c')
]);
fclose($csv);

// Création du ZIP
$zipPath = "$tmpDir/auditbox_kit.zip";
$zip = new ZipArchive();
$zip->open($zipPath, ZipArchive::CREATE);
$zip->addFile("$tmpDir/Auditbox.ps1", "Auditbox.ps1");
$zip->addFile("$tmpDir/README.txt", "README.txt");
$zip->addFile("$tmpDir/data/Script_nmap.ps1", "data/Script_nmap.ps1");
$zip->addFile("$tmpDir/data/Script_pingcastle.ps1", "data/Script_pingcastle.ps1");
$zip->addFile("$tmpDir/data/data_client.csv", "data/data_client.csv");
$zip->close();

// Téléchargement
header('Content-Type: application/zip');
header('Content-Disposition: attachment; filename="auditbox_kit.zip"');
readfile($zipPath);

// Nettoyage
unlink($zipPath);
array_map('unlink', glob("$tmpDir/data/*"));
rmdir("$tmpDir/data");
rmdir($tmpDir);
exit;
