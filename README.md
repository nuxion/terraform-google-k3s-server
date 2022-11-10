# k3s main server module for google provider

It has two modules. One for the k3s server and other as a node template. 

Usually nodes will be used in pools, meanwhile the server in this setup is in standalone mode. 

Features:

- Registry configuration for Google Artifacts
- Nodes join automatically to the cluster
- Backup of the server
- Disk CSI Driver to integrate with google
- Configurable node labeling when setting up


For google csi driver usage checks: 
https://github.com/nuxion/gcp-compute-persistent-disk-csi-driver

## References
- [Terraform module creation](https://www.terraform.io/language/modules/develop/structure)
- [Terraform publishing](https://www.terraform.io/registry/modules/publish?_ga=2.132646471.838845338.1666208647-1520980583.1657402599)
- [custom credential provider](https://github.com/k3s-io/k3s/issues/2367)
