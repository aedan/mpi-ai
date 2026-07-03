#!/usr/bin/env bash
set -euo pipefail

echo "=== 04 — Download Kimi-K2-Instruct int4 to CephFS ==="

cat <<'EOF' > /tmp/model-download-job.yaml
apiVersion: v1
kind: Pod
metadata:
  name: model-download
  namespace: mpi-inference
  labels:
    app: model-download
spec:
  nodeSelector:
    mpi-ai: "true"
  containers:
    - name: downloader
      image: python:3.11
      command: ["python3", "-c", "import huggingface_hub; huggingface_hub.snapshot_download('moonshotai/Kimi-K2-Instruct', repo_type='model', revision='int4', local_dir='/models/kimi-k2-instruct-int4')"]
      volumeMounts:
        - name: model-volume
          mountPath: /models
      resources:
        requests:
          cpu: "4"
          memory: "8Gi"
  volumes:
    - name: model-volume
      persistentVolumeClaim:
        claimName: kimi-k2-model-pvc
  restartPolicy: Never
EOF

kubectl apply -f /tmp/model-download-job.yaml
kubectl wait --for=condition=Ready pod/model-download -n mpi-inference --timeout=900s
kubectl wait --for=condition=Complete pod/model-download -n mpi-inference --timeout=7200s
kubectl delete pod/model-download -n mpi-inference

echo "Model download complete."
