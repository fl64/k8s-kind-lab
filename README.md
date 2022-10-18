```
make CLUSTER_NAME=dev0 install

make CLUSTER_NAME=dev1 install

cilium clustermesh connect --context kind-dev0 --destination-context kind-dev1 -n cilium-system
cilium connectivity test --context kind-dev0 --multi-cluster kind-dev1 -n cilium-system

cilium connectivity test --test ingress-l7 -n cilium-system
cilium connectivity test --test egress-l7 -n cilium-system
```

Links:
- istio ingress supported annotations: https://docs.cilium.io/en/v1.12/gettingstarted/servicemesh/ingress/#supported-ingress-annotations
- https://docs.cilium.io/en/v1.12/gettingstarted/clustermesh/affinity/#enabling-global-service-affinity
