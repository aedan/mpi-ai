#!/usr/bin/env bash
set -euo pipefail

echo "=== 02 — Deploy MPI Operator ==="

kubectl apply -f https://raw.githubusercontent.com/mpi-operators/mpi-operator/v0.5.0/deploy/v6-1-0/mpi-operator.yaml \
  --namespace mpi-inference

kubectl wait --for=condition=Available deployment/mpi-operator \
  --namespace mpi-inference --timeout=120s

echo "MPI Operator deployed."
