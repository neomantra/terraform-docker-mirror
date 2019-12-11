
# terraform-docker-mirror

This Terraform module ensures that a source Docker image is mirrored to the specified Docker registry,
copying image `source_prefix/image_name:image-tag` to `dest_prefix/image_name:image_tag`.

It requires a [Terraform Docker Provider](https://www.terraform.io/docs/providers/docker/index.html) to be configured, as well as a Docker daemon running on the Terraform-local machine.  Note you may need to setup  authentication or run `docker login` to access private registries.

### Motivation

If one uses Docker on a private network on the Google Cloud (GCP/GKE), the nodes will not be able to pull from the Docker Hub Registry.  However, the nodes *can* pull from the Google Container Registry (GCR).  Thus, mirroring the registries will facilitate the nodes' access to images.  This module enables this to be managed with Terraform.

### How It Works

This module works by first creating a `docker_image` resource, which pulls the "source" image to the Docker provider.  That pull will trigger a `local-exec` provisioner which performs a tag and `docker push` to the destination registry.

### Terraform Version Compatibility

Version `v0.1.0` of `terraform-docker-mirror` supports Terraform 0.11 and earlier.

Version `v0.2.0` and later support Terraform 0.12.

If unspecified, Terraform uses the latesst `master`.

You can specify the version with the `source` attribute, like so:

```
module "docker-mirror-vault" {
  source = "github.com/neomantra/terraform-docker-mirror?ref=v0.1.0"
  ...
}
```

### Example

The following will mirror the [HashiCorp Vault image](https://hub.docker.com/_/vault) (`vault:1.0.3`) to the GCR registry for `my-gcp-project`:

```
module "docker-mirror-vault" {
  source        = "github.com/neomantra/terraform-docker-mirror"
  image_name    = "vault"
  image_tag     = "1.0.3"
  dest_prefix   = "us.gcr.io/my-gcp-project"
}
```

Example with `source_prefix`, copying `openresty/openresty:xenial` to `us.gcr.io/my-gcp-project/openresty:xenial`:
```
module "docker-mirror-resty" {
  source        = "github.com/neomantra/terraform-docker-mirror"
  image_name    = "vault"
  image_tag     = "1.0.3"
  source_prefix = "openresty"
  dest_prefix   = "us.gcr.io/my-gcp-project"
}

```

### License

Authored by [Evan Wies](https://github.com/neomantra).

Copyright (c) 2019 Neomantra BV.

Released under the MIT License, see LICENSE.
