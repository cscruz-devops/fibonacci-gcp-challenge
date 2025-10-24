variable "project_id" {
  description = "ID del proyecto GCP (ej: visby-coding-challenge-<tu-nombre>)"
  type        = string
}

variable "region" {
  description = "Región de Cloud Run"
  type        = string
  default     = "us-central1"
}

variable "location" {
  description = "Ubicación para Artifact Registry / GCS"
  type        = string
  default     = "us-central1"
}

variable "service_name" {
  description = "Nombre del servicio Cloud Run (según el enunciado)"
  type        = string
  default     = "fibonnaci-service"
}

variable "repo_id" {
  description = "ID del repositorio en Artifact Registry"
  type        = string
  default     = "apps"
}

variable "app_dir" {
  description = "Ruta al código fuente de la app (relativo a esta carpeta tf/)"
  type        = string
  default     = "../app"
}

variable "image_tag" {
  description = "Tag de la imagen docker"
  type        = string
  default     = "1.0.0"
}

variable "invoker_members" {
  description = "Principals que pueden invocar Cloud Run (rol roles/run.invoker)"
  type        = list(string)
  default     = []
}
