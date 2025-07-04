// Empêche les lettres dans le champ téléphone
document.addEventListener("DOMContentLoaded", function () {
  const phoneInput = document.getElementById("phone");
  if (phoneInput) {
    phoneInput.addEventListener("input", function () {
      this.value = this.value.replace(/[^0-9+\.]/g, "");
    });
  }

  // Empêche les lettres et caractères non CIDR dans les plages IP
  document.querySelectorAll('input[name="ipRanges[]"]').forEach((input) => {
    input.addEventListener("input", function () {
      this.value = this.value.replace(/[^0-9./]/g, "");
    });
  });
});

// Fonction pour ajouter un champ de saisie réseau IP
function addIpField() {
  const container = document.getElementById("ipContainer");

  const newInput = document.createElement("input");
  newInput.type = "text";
  newInput.name = "ipRanges[]";
  newInput.required = true;
  newInput.pattern = "^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$";
  newInput.title = "Format requis : x.x.x.x/xx (ex: 192.168.1.0/24)";
  newInput.placeholder = "192.168.1.0/24";
  newInput.style.marginTop = "0.5rem";
  newInput.addEventListener("input", function () {
    this.value = this.value.replace(/[^0-9./]/g, "");
  });

  container.appendChild(newInput);
}
// Fonction pour supprimer le dernier champ de saisie réseau IP SAUF LE PREMIER CHAMP
function removeLastIpField() {
  const container = document.getElementById("ipContainer");
  const ipInputs = container.querySelectorAll('input[name="ipRanges[]"]');

  // On ne supprime pas le tout premier champ
  if (ipInputs.length > 1) {
    container.removeChild(ipInputs[ipInputs.length - 1]);
  }
}
