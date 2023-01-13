# k3s main server module for google provider

This repo contains modules for running a k3s cluster on [Google Cloud Platform](https://cloud.google.com/)

The other module could be used as a node template for the agents. In this way, and because nodes usually will be used in pools, it's possible to combine different templates with the [instance group manager option](https://cloud.google.com/compute/docs/instance-groups) of GCP. Check [examples/](examples/).

Features:

- Registry configuration for Google Artifacts
- Nodes join automatically to the cluster
- Backup of configuration files to the google object storage
- Disk CSI Driver to integrate with google
- Configurable node labeling when setting up
- Ingress controller selection between `nginx` and `traefik`

For google csi driver usage checks: 
https://github.com/nuxion/gcp-compute-persistent-disk-csi-driver

For my use case one main server is ok. In addition the server is capable to run workloads. If you are interest in a HA version of the module, let me know and we can work together. You can send me an email or open a issue in the github repo. 

The same, if you are interest in another cloud provider. 

## Quickstart

For a quick start you can go to [examples/](examples/). 

For native google cloud disk storage support you should add service account for disk managment as:

`$BUCKET/k3s/cloud-sa.json`

## Pendings

- [ ] Restore configuration
- [ ] Backup at disk level 
- [ ] Evaluate backup using SQLiteStream from Fly.to. 
- [ ] Better documentation for CSI Google driver
- [ ] Check variable documentation of `bucket` param. gs:// prefix is a MUST

## Example use case

This module is being used in production as crawling platform for [algorinfo](https://algorinfo.com), where different pools are created by zones:

![k3s diagram](/docs/crawling.jpg)

## References
- [Terraform module creation](https://www.terraform.io/language/modules/develop/structure)
- [Terraform publishing](https://www.terraform.io/registry/modules/publish?_ga=2.132646471.838845338.1666208647-1520980583.1657402599)
- [custom credential provider](https://github.com/k3s-io/k3s/issues/2367)
