# Manual install

```bash
cilium --context kind-dev0 install --helm-set cluster.name=dev0 --helm-set cluster.id=0
cilium --context kind-dev0 hubble enable
cilium --context kind-dev0 status
cilium --context kind-dev0 clustermesh enable  --service-type LoadBalancer
cilium --context kind-dev0 clustermesh status --wait

cilium --context kind-dev1 install --helm-set cluster.name=dev1 --helm-set cluster.id=1
cilium --context kind-dev1 hubble enable
cilium --context kind-dev1 status
cilium --context kind-dev1 clustermesh enable  --service-type LoadBalancer
cilium --context kind-dev1 clustermesh status --wait

```

# Cilium debug

```bash
kubectl exec -ti -n cilium-system ds/cilium -c cilium-agent -- cilium service list --clustermesh-affinity
kubectl exec -ti -n cilium-system ds/cilium -c cilium-agent -- cilium endpoint list
kubectl exec -ti -n cilium-system ds/cilium -c cilium-agent -- cilium endpoint get ( <endpoint identifier> | -l <endpoint labels> )  [flags]

```

# Hubble

```bash
hubble observe -n prober-00 -f -o jsonpb | jq .
hubble observe -n prober-00 -f --ip-translation
hubble record "0.0.0.0/0 0 0.0.0.0/0 63636 TCP"
```
