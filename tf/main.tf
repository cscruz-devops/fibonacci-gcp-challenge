terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.45"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

# ---------------- Providers ----------------
provider "google" {
  project = var.project_id
  region  = var.region
}

# Datos del proyecto (para obtener project number)
data "google_project" "current" {
  project_id = var.project_id
}

# ---------------- Habilitar APIs ----------------
resource "google_project_service" "run"        { service = "run.googleapis.com" }
resource "google_project_service" "cloudbuild" { service = "cloudbuild.googleapis.com" }
resource "google_project_service" "artifact"   { service = "artifactregistry.googleapis.com" }
resource "google_project_service" "iam"        { service = "iam.googleapis.com" }

# ---------------- Artifact Registry ----------------
resource "google_artifact_registry_repository" "repo" {
  location      = var.location
  repository_id = var.repo_id
  description   = "Repo Docker para ${var.service_name}"
  format        = "DOCKER"
  depends_on    = [google_project_service.artifact]
}

# Imagen destino
locals {
  image = "${var.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.repo.repository_id}/${var.service_name}:${var.image_tag}"
}

# ---------------- Permisos: Cloud Build → AR (push) ----------------
resource "google_project_iam_member" "cb_ar_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${data.google_project.current.number}@cloudbuild.gserviceaccount.com"
  depends_on = [
    google_project_service.cloudbuild,
    google_project_service.artifact
  ]
}

# ---------------- Build + push (usando gcloud) ----------------
# Requiere tener gcloud instalado y autenticado en tu máquina
resource "null_resource" "build_and_push" {
  # Si cambias el código o el tag, se reconstruye
  triggers = {
    image     = local.image
    app_hash  = sha1(join("", [for f in fileset(var.app_dir, "**") : filesha1("${var.app_dir}/${f}")]))
  }

  provisioner "local-exec" {
    working_dir = var.app_dir
    command     = "gcloud builds submit --region='${var.location}' --tag='${local.image}' ."
  }

  depends_on = [
    google_project_service.cloudbuild,
    google_artifact_registry_repository.repo,
    google_project_iam_member.cb_ar_writer
  ]
}

# ---------------- SA de runtime + permiso lectura AR ----------------
resource "google_service_account" "runtime" {
  account_id   = "crn-${var.service_name}"
  display_name = "Runtime SA for ${var.service_name}"
}

resource "google_artifact_registry_repository_iam_member" "repo_reader" {
  location   = google_artifact_registry_repository.repo.location
  repository = google_artifact_registry_repository.repo.repository_id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.runtime.email}"
}

# ---------------- Cloud Run v2 (ingress ALL, IAM requerido) ----------------
resource "google_cloud_run_v2_service" "svc" {
  name     = var.service_name
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.runtime.email
    containers {
      image = local.image
      ports { container_port = 8080 }
    }
    scaling {
      min_instance_count = 0
      max_instance_count = 10
    }
  }

  depends_on = [
    null_resource.build_and_push,
    google_project_service.run,
    google_project_service.iam
  ]
}

# ---------------- IAM invoker (NO público) ----------------
resource "google_cloud_run_v2_service_iam_binding" "invoker" {
  name     = google_cloud_run_v2_service.svc.name
  location = var.region
  role     = "roles/run.invoker"
  members  = var.invoker_members
}

# ---------------- Outputs ----------------
output "service_url" {
  description = "URL del servicio Cloud Run"
  value       = google_cloud_run_v2_service.svc.uri
}
