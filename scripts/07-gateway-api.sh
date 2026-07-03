#!/usr/bin/env bash
set -euo pipefail

echo "=== 07 — Configure Gateway API Route ==="

TLS_SECRET="ai-api-phobos-cloudmunchers-net-tls-secret"
SERVICE="kimi-k2-inference"
NAMESPACE="mpi-inference"
HOST="ai.api.phobos.cloudmunchers.net"
GATEWAY="flex-gateway"

kubectl get secret "$TLS_SECRET" -n envoy-gateway &>/dev/null || {
  echo "TLS secret $TLS_SECRET not found in envoy-gateway namespace."
  echo "Available TLS secrets:"
  kubectl get secrets -n envoy-gateway -o custom-columns=NAME:metadata.name
  exit 1
}

EXISTING=$(kubectl get httproute -n "$NAMESPACE" -o name 2>/dev/null | grep -i kimi || true)

if [ -n "$EXISTING" ]; then
  echo "HTTPRoute already exists — updating..."
else
  echo "Creating HTTPRoute for $HOST..."
fi

cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: kimi-k2-inference-route
  namespace: $NAMESPACE
  labels:
    app: kimi-k2-inference
spec:
  hostnames:
    - $HOST
  parentRefs:
    - group: gateway.networking.k8s.io
      kind: Gateway
      name: $GATEWAY
      namespace: envoy-gateway
      sectionName: https
  rules:
    - backendRefs:
        - group: ""
          kind: Service
          name: $SERVICE
          namespace: $NAMESPACE
          port: 80
          weight: 1
      matches:
        - path:
            type: PathPrefix
            value: /
EOF

echo "Verify: kubectl get httproute -n $NAMESPACE"
echo "Gateway API route configured."
