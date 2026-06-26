# Cambiamos nombre del proveedor y la version
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Proveedor GCP de Google. Requiere el project porque se organiza por poryecto
provider "google" {
  project = "techustart-luis-2026"
  region  = var.gcp_region
}

# Grupo de Recursos - En Azure se usaba azurerm_resource_group
# En GCP el proyecto ya actua como contenedor logico de todos los recursos
# por eso no se necesita este bloque, el project en el provider lo reemplaza


# Red Virtual - Azure usaba azurerm_virtual_network, false para crear manualmente la subred
resource "google_compute_network" "vpc_network" {
  name                    = "techustart-vpc"
  auto_create_subnetworks = false
}

# Subred - Azure usaba azurerm_subnet, aqui referenciamos la VPC por su id
resource "google_compute_subnetwork" "subnet" {
  name          = "techustart-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.gcp_region
  network       = google_compute_network.vpc_network.id
}

# IP Publica - Azure usaba azurerm_public_ip con allocation_method Static, aqui es Static por defecto
resource "google_compute_address" "public_ip" {
  name   = "techustart-public-ip"
  region = var.gcp_region
}


# Firewall - Azure usaba azurerm_network_security_group, aqui se asocia directo a la VPC
# target_tags vincula esta regla solo a VMs que tengan el tag http-server
resource "google_compute_firewall" "allow_http" {
  name    = "techustart-allow-http"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

# Maquina Virtual Linux - Azure usaba azurerm_linux_virtual_machine
# zone agrega el sufijo -a a la region porque GCP trabaja con zonas, no solo regiones
# network_interface va dentro de la VM, en Azure era un recurso azurerm_network_interface separado
# metadata_startup_script reemplaza al custom_data de Azure, GCP no requiere codificarlo en Base64


resource "google_compute_instance" "vm_linux" {
  name         = "techustart-dev-server"
  machine_type = var.tipo_instancia
  zone         = "${var.gcp_region}-a"

  # El tag debe coincidir con target_tags del firewall para aplicar la regla
  tags = ["http-server"]

  boot_disk {
    initialize_params {
        # Azure usaba publisher/offer/sku, GCP usa una sola imagen
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {
      nat_ip = google_compute_address.public_ip.address
    }
  }

  metadata_startup_script = "sudo apt update && sudo apt install apache2 -y"

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa_gcp_techustart.pub")}"
  }
}

# Output - Imprime la IP publica en terminal al terminar terraform apply
output "public_ip_address" {
  value = google_compute_address.public_ip.address
}