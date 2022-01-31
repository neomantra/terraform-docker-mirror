# Copyright (c) 2019-2020 Neomantra BV.  All rights reserved.
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
# Terraform Requirements
###############################################################################

terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
    null = {
      source = "hashicorp/null"
    }
  }
  required_version = ">= 0.13"
}


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
  type        = bool
  default     = true
}

variable "no_rmi" {
  description = "If true, it will not issue a `docker rmi` of the local source tag"
  type        = bool
  default     = false
}

variable "dest_image" {
  description = "The destination image name, if its name differs from the source"
  type        = string
  default     = null
}



###############################################################################
# Locals
###############################################################################

locals {
  source      = "${var.source_prefix}${var.source_prefix == "" ? "" : "/"}"
  source_repo = "${local.source}${var.image_name}"
  source_full = "${local.source_repo}:${var.image_tag}"
  dest        = "${var.dest_prefix}${var.dest_prefix == "" ? "" : "/"}"
  dest_repo   = "${local.dest}${var.dest_image == null ? var.image_name : var.dest_image}"
  dest_full   = "${local.dest_repo}:${var.image_tag}"
}


###############################################################################
# Output
###############################################################################

output "dest_repo" {
  description = "Destination Repository without tag"
  value       = local.dest_repo
  depends_on = [
    docker_image.image
  ]
}

output "dest_full" {
  description = "Full Destination image path as dest/image_name:image_tag"
  value       = local.dest_full
  depends_on = [
    docker_image.image
  ]
}

output "dest_full_sha" {
  description = "Full Destination image path as dest/image_name@sha256"
  value       = "${local.dest_repo}@${data.docker_registry_image.source.sha256_digest}"
  depends_on = [
    docker_image.image
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
    docker_image.image
  ]
}


###############################################################################
# Implementation
###############################################################################

data "docker_registry_image" "source" {
  name = local.source_full
}

resource "null_resource" "remove-local-tag" {
  triggers = {
    source_sha = data.docker_registry_image.source.sha256_digest
  }
  provisioner "local-exec" {
    on_failure = continue
    command    = <<END_OF_COMMAND
if [ -n "${var.no_rmi ? "" : "rmi"}" ] ; then docker rmi --no-prune ${data.docker_registry_image.source.name} ; fi
END_OF_COMMAND
  }
}


resource "docker_image" "image" {
  name          = data.docker_registry_image.source.name
  keep_locally  = var.keep_locally
  pull_triggers = [data.docker_registry_image.source.sha256_digest]

  depends_on = [
    null_resource.remove-local-tag,
  ]

  provisioner "local-exec" {
    command = <<END_OF_COMMAND
docker tag ${replace(self.latest, "sha256:", "")} ${local.dest_full} && \
docker push ${local.dest_full}
END_OF_COMMAND
  }
}
