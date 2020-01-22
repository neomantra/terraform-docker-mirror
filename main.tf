# Copyright (c) 2019 Neomantra BV.  All rights reserved.
#
# main.tf   --   terraform-docker-mirror
#
# Ensures that a source Docker image is mirrored to the specified
# Docker registry, copying image `source_prefix/image_name:image-tag`
# to `dest_prefix/image_name:image_tag`.  See README.md
#
# Released under the MIT license, see LICENSE.
#

###############################################################################
# Variables
###############################################################################

variable "image_name" {
  description = "Docker image name"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "source_prefix" {
  description = "Source Docker Registry Path Prefix"
  type        = string
  default     = ""
}

variable "dest_prefix" {
  description = "Destination Docker Registry Path Prefix"
  type        = string
}

variable "keep_locally" {
  description = "If false, it will delete the image from the docker local storage on destroy operation."
  default     = true
}


###############################################################################
# Locals
###############################################################################

locals {
  source      = "${var.source_prefix}${var.source_prefix == "" ? "" : "/"}"
  source_repo = "${local.source}${var.image_name}"
  source_full = "${local.source_repo}:${var.image_tag}"
  dest        = "${var.dest_prefix}${var.dest_prefix == "" ? "" : "/"}"
  dest_repo   = "${local.dest}${var.image_name}"
  dest_full   = "${local.dest_repo}:${var.image_tag}"
}


###############################################################################
# Output
###############################################################################

output "dest_repo" {
  description = "Destination Repository without tag"
  value       = local.dest_repo
  depends_on = [
    docker_image.image.latest
  ]
}

output "dest_full" {
  description = "Full Destination image path as dest/image_name:image_tag"
  value       = local.dest_full
  depends_on = [
    docker_image.image.latest
  ]
}

output "dest_full_sha" {
  description = "Full Destination image path as dest/image_name@sha256"
  value       = "${local.dest_repo}@${data.docker_registry_image.source.sha256_digest}"
  depends_on = [
    docker_image.image.latest
  ]
}

output "sha256_digest" {
  description = "sha256 digest of the image"
  value       = data.docker_registry_image.source.sha256_digest

}

output "tag" {
  description = "Image tag"
  value       = var.image_tag
  depends_on = [
    docker_image.image.latest
  ]
}


###############################################################################
# Implementation
###############################################################################

data "docker_registry_image" "source" {
  name = local.source_full
}

resource "docker_image" "image" {
  name          = data.docker_registry_image.source.name
  keep_locally  = var.keep_locally
  pull_triggers = [data.docker_registry_image.source.sha256_digest]

  provisioner "local-exec" {
    command = <<END_OF_COMMAND
docker tag ${replace(self.latest, "sha256:", "")} ${local.dest_full} && \
docker push ${local.dest_full}
END_OF_COMMAND
  }
}
