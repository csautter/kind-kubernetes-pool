#!/usr/bin/env bash

set -e

# https://docs.cilium.io/en/stable/installation/kind/

KIND_CLUSTER_NAME=$(yq '.name' < kind-config.yaml)

kind delete cluster --name "$KIND_CLUSTER_NAME"
kind get clusters