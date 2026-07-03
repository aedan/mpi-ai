#!/usr/bin/env bash
set -euo pipefail

echo "=== 06 — Health Checks ==="

PENDING=$(kubectl get pods -n mpi-inference -l mpioperator.xinli.com.cn/mpiReplicaRole=Worker \
  --no-headers -o custom-columns=STATUS:status.phase \
  | grep -c Pending || true)
FAILED=$(kubectl get pods -n mpi-inference -l mpioperator.xinli.com.cn/mpiReplicaRole=Worker \
  --no-headers -o custom-columns=STATUS:status.phase \
  | grep -c Failed || true)
READY=$(kubectl get pods -n mpi-inference -l mpioperator.xinli.com.cn/mpiReplicaRole=Worker \
  --no-headers -o custom-columns=STATUS:status.phase \
  | grep -c Running || true)

echo "  Running: $READY  |  Pending: $PENDING  |  Failed: $FAILED"

if [ "$FAILED" -gt 0 ]; then
  echo "⚠️  Failed pods detected:"
  kubectl get pods -n mpi-inference -l mpioperator.xinli.com.cn/mpiReplicaRole=Worker \
    --no-headers -o custom-columns=NAME:metadata.name,STATUS:status.phase,RESTARTS:status.restartCount
fi

FIRST_POD=$(kubectl get pods -n mpi-inference -l mpioperator.xinli.com.cn/mpiReplicaRole=Worker \
  --no-headers -o custom-columns=NAME:metadata.name | head -1)

if [ -n "$FIRST_POD" ]; then
  echo "Testing health endpoint on $FIRST_POD..."
  kubectl exec -n mpi-inference "$FIRST_POD" -- python3 -c \
    "import urllib.request; r=urllib.request.urlopen('http://localhost:8080/health'); print(r.read().decode())"
fi

echo "Health check complete."
