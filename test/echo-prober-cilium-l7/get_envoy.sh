node=$(kubectl -n echo-cilium get pods -l app=echo -o json | jq .items[0].spec.nodeName -r )
pod=$(kubectl -n cilium-system get pods -l k8s-app=cilium -o json | jq -r ".items[] | select(.spec.nodeName==\"${node}\") | .metadata.name" |  tail -1)
kubectl exec -n cilium-system -c cilium-agent -it ${pod} -- apt update -q > /dev/null
kubectl exec -n cilium-system -c cilium-agent -it ${pod} -- apt install -yq curl > /dev/null

# kubectl exec -n cilium-system -c cilium-agent -it ${pod} --  curl -L https://github.com/fullstorydev/grpcurl/releases/download/v1.8.7/grpcurl_1.8.7_linux_x86_64.tar.gz | tar -xzv -C /usr/local/bin/

# kubectl exec -n cilium-system -c cilium-agent -it ${pod} -- curl -s --unix-socket /var/run/cilium/envoy-admin.sock http://localhost/listeners

# kubectl exec -n cilium-system -c cilium-agent -it ${pod} -- curl -s --unix-socket /var/run/cilium/envoy-admin.sock http://localhost/clusters

# # echo kubectl exec -n cilium-system -c cilium-agent -it ${pod} -- curl -s --unix-socket /var/run/cilium/envoy-admin.sock http://localhost/config_dump
# #kubectl exec -n cilium-system -c cilium-agent -it ${pod} -- curl -s --unix-socket /var/run/cilium/envoy-admin.sock http://localhost/config_dump
# #kubectl exec -n cilium-system -c cilium-agent -it ${pod} -- curl -s --unix-socket /var/run/cilium/envoy-admin.sock http://localhost/server_info

# kubectl exec -n cilium-system -c cilium-agent -it ${pod} -- curl -s --unix-socket /var/run/cilium/envoy-admin.sock http://localhost/listeners123123

#kubectl exec -n cilium-system -c cilium-agent -it ${pod} -- curl -s --unix-socket /var/run/cilium/envoy-admin.sock http:/admin/config_dump?include_eds

echo -n cilium-system ${pod}
