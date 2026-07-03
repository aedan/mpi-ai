#!/usr/bin/env bash
set -euo pipefail

echo "=== 01 — Label MPI-AI nodes ==="

count=0
for node in $(kubectl get nodes --no-headers -o custom-columns=NAME:metadata.name | grep -vE '(control|master|cp)\s' | head -n 63); do
  kubectl label node "$node" mpi-ai=true --overwrite
  echo "  Labeled: $node"
  count=$((count + 1))
done

echo "=== Verified nodes ==="
labeled=$(kubectl get nodes -l mpi-ai=true --no-headers -o custom-columns=NAME:metadata.name | wc -l)
echo "$labeled nodes labeled with mpi-ai=true"
