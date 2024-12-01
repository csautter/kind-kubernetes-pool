# Cilium cluster with kind
Based on the official docs: https://docs.cilium.io/en/stable/installation/kind/

## Intended use
If you like to set up a local k8s cluster with cilium for educational or testing purpose you can use the [install.sh](install.sh) to bootstrap a cluster in under 5 minutes.

## Dependencies
- docker, podman or nerdctl
- helm
- kubectl
- kind
- cilium cli
- hubble cli

Dependencies can be installed with the [install_dependencies.sh](install_dependencies.sh) script