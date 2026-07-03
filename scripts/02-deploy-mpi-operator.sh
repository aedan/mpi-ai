#!/usr/bin/env bash
set -euo pipefail

echo "=== 02 — Deploy MPI Operator ==="

# Download operator YAML and extract resources, stripping annotations that cause
# "metadata.annotations: Too long" errors on older API servers
curl -sL "https://github.com/kubeflow/mpi-operator/releases/download/v0.8.0/mpi-operator.yaml" \
  -o /tmp/mpi-operator.yaml

python3 -c "
import yaml
with open('/tmp/mpi-operator.yaml') as f:
    docs = list(yaml.safe_load_all(f))
targets = {'ServiceAccount', 'ClusterRole', 'ClusterRoleBinding', 'Deployment', 'Namespace'}
output = []
for doc in docs:
    if doc and doc.get('kind') in targets:
        meta = doc.get('metadata', {})
        if 'annotations' in meta:
            del meta['annotations']
        if doc.get('kind') == 'Namespace':
            if 'name' not in doc:
                doc['metadata']['name'] = 'mpi-operator'
        output.append(doc)
with open('/tmp/mpi-operator-rest.yaml', 'w') as f:
    for i, doc in enumerate(output):
        if i > 0:
            f.write('---\n')
        yaml.dump(doc, f)
# Extract and clean CRD
crd = None
for doc in docs:
    if doc and doc.get('kind') == 'CustomResourceDefinition':
        crd = doc
        break
if crd and 'annotations' in crd.get('metadata', {}):
    del crd['metadata']['annotations']
with open('/tmp/mpi-crd.yaml', 'w') as f:
    yaml.dump(crd, f)
"

kubectl create -f /tmp/mpi-crd.yaml 2>/dev/null || kubectl replace -f /tmp/mpi-crd.yaml 2>/dev/null || true

kubectl create -f /tmp/mpi-operator-rest.yaml 2>/dev/null || true

kubectl wait --for=condition=Available deployment/mpi-operator \
  --namespace mpi-operator --timeout=120s

echo "MPI Operator deployed."
