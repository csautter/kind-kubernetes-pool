#!/usr/bin/env bash

# https://docs.cilium.io/en/stable/installation/kind/

KIND_CONFIG="kind-config.yaml"
KIND_CLUSTER_NAME=$(yq '.name' < $KIND_CONFIG)
KUBECONTEXT="kind-$KIND_CLUSTER_NAME"
HELM_KUBECONTEXT=$KUBECONTEXT

kind create cluster --config=$KIND_CONFIG
kubectl cluster-info --context $KUBECONTEXT

docker pull quay.io/cilium/cilium:v1.16.4
kind load docker-image quay.io/cilium/cilium:v1.16.4 --name "$KIND_CLUSTER_NAME"

helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --version 1.16.4 \
   --namespace kube-system \
   --set image.pullPolicy=IfNotPresent \
   --set ipam.mode=kubernetes

CGROUP_CP=$(docker exec $KIND_CLUSTER_NAME-control-plane ls -al /proc/self/ns/cgroup)

CGROUP_W=$(docker exec $KIND_CLUSTER_NAME-worker ls -al /proc/self/ns/cgroup)

if [ "$CGROUP_CP" == "$CGROUP_W" ]; then
  echo "Cgroup values are not different"
  exit 1
fi

ls -al /proc/self/ns/cgroup

brew install cilium-cli

cilium status --wait

# cilium connectivity test

cilium hubble enable

# cilium hubble port-forward&

hubble status

hubble observe

cilium hubble enable --ui

cilium status --wait

#cilium hubble ui&