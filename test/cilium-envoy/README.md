https://github.com/cilium/cilium-service-mesh-beta/tree/main/l7-traffic-management
```bash
cilium -n cilium-system connectivity test --test egress-l7
kubectl get pods -n cilium-test --show-labels -o wide

kubectl get pods -n cilium-test -l name=client2 -o json | jq .items[0].status.podIP -r

kubectl exec -it -n cilium-test deployments/client2 -- curl -v echo-same-node:8080/
kubectl exec -it -n cilium-test deployments/client2 -- curl -v echo-other-node:8080/

kubectl exec -it -n cilium-test deployments/client2 -- curl -v echo-same-node:8080/foo
kubectl exec -it -n cilium-test deployments/client2 -- curl -v echo-other-node:8080/foo


kubectl apply -n cilium-test -f  https://raw.githubusercontent.com/cilium/cilium-cli/master/connectivity/manifests/client-egress-l7-http.yaml
kubectl apply -n cilium-test -f   https://raw.githubusercontent.com/cilium/cilium-cli/master/connectivity/manifests/client-egress-only-dns.yaml
```
