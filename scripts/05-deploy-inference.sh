#!/usr/bin/env bash
set -euo pipefail

echo "=== 05 — Deploy Inference MPIJob ==="

kubectl apply -f ../k8s/namespace.yaml
kubectl apply -f ../k8s/storage-claim.yaml
kubectl apply -f ../k8s/mpijob.yaml

echo "Waiting for MPIJob pods to become Ready..."
kubectl rollout status mpijob/kimi-k2-inference -n mpi-inference --timeout=900s

echo "MPIJob pods:"
kubectl get pods -n mpi-inference -l mpioperator.xinli.com.cn/mpiReplicaRole=Worker \
  -o custom-columns=NAME:metadata.name,STATUS:status.phase \
  --no-headers

echo "Inference service ready."
