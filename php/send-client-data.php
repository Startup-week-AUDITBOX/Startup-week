<?php
session_start();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo "Méthode non autorisée";
    exit;
}

// Récupération des champs
$company = $_POST['company'] ?? '';
$firstName = $_POST['firstName'] ?? '';
$lastName = $_POST['lastName'] ?? '';
$email = $_POST['email'] ?? '';
$phone = $_POST['phone'] ?? '';
$ipRanges = $_POST['ipRanges'] ?? [];

// Stockage en session
$_SESSION['client_data'] = [
    'company' => $company,
    'firstName' => $firstName,
    'lastName' => $lastName,
    'email' => $email,
    'phone' => $phone,
    'ipRanges' => $ipRanges
];

// Envoi email
$to = "auditbox74@gmail.com";
$subject = "🛡️ Nouvelle demande d’audit – $company";
$message = "Entreprise: $company\nNom: $firstName $lastName\nEmail: $email\nTéléphone: $phone\nPlages IP:\n" . implode("\n", $ipRanges);
$headers = "From: contact@auditbox.fr";

mail($to, $subject, $message, $headers);

// Redirection vers la fausse page de paiement
header("Location: ../audit/paiement/index.html");
exit;
