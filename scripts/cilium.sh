#!/usr/bin/env
CILIUM_PODS=$(kubectl get pods -n cilium-system -l k8s-app=cilium -o json | jq .items[].metadata.name -r)
for pod in ${CILIUM_PODS}; do
  kubectl exec -ti -n cilium-system -c cilium-agent "${pod}" -- "${@}"
done
