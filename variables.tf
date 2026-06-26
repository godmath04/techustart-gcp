variable "gcp_project" {
  type        = string
  description = "ID del proyecto en GCP"
}

variable "gcp_region" {
  type    = string
  default = "us-central1"
}

variable "tipo_instancia" {
  type    = string
  default = "e2-micro"
}

variable "ssh_public_key_path" {
  type        = string
  default     = "~/.ssh/id_rsa.pub"
  description = "Ruta a la llave publica SSH"
}