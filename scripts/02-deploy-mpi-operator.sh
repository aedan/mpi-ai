#!/usr/bin/env bash
set -euo pipefail

echo "=== 02 — Deploy MPI Operator ==="

kubectl apply -f https://raw.githubusercontent.com/kubeflow/mpi-operator/master/deploy/v2beta1/mpi-operator.yaml

kubectl wait --for=condition=Available deployment/mpi-operator \
  --namespace mpi-operator --timeout=120s

echo "MPI Operator deployed."
