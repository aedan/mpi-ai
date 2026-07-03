#!/usr/bin/env bash
set -euo pipefail

echo "=== 03 — Provision CephFS Storage ==="

cat <<'EOF' | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: cephfs
provisioner: cephfs.csi.ceph.com
parameters:
  fsName: mpi-ai
  monitors: 172.20.0.60:6789,172.20.0.57:6789,172.20.0.51:6789
secretRef:
  name: cephfs-secret
  namespace: mpi-inference
EOF

CEPHFS_USER=$(kubectl get secret -n rook-ceph -l "rook.io/cephfs-csi-cephfs.com=csi-cephfs" \
  --no-headers -o custom-columns=NAME:metadata.name -o jsonpath='{.items[0].metadata.name}' \
  2>/dev/null || echo "rook-csi-cephfs-provisioner")

cat <<EOF > /tmp/cephfs-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: cephfs-secret
  namespace: mpi-inference
type: kubernetes.io/opaque
data:
  username: $(kubectl get secret "$CEPHFS_USER" -n rook-ceph -o jsonpath='{.data.username}' | base64 -d)
  key: $(kubectl get secret "$CEPHFS_USER" -n rook-ceph -o jsonpath='{.data.key}' | base64 -d)
EOF

kubectl apply -f /tmp/cephfs-secret.yaml
echo "StorageClass and secret created."
