cilium-logs:
	stern -n cilium-system -l k8s-app=cilium --tail=0

prober-logs:
	stern -n prober-cilium -l app=prober --tail=0

deploy:
	kubectl apply -k .

undeploy:
	kubectl delete -k .

delete-cnp:
	k delete -n echo-cilium ciliumnetworkpolicies.cilium.io cnp-test

hubble-port-forward:
	kubectl port-forward -n cilium-system svc/hubble-relay 4245:80 &



NODE_NAME:=dev0-worker
CILIUM_POD=$(shell kubectl -n cilium-system get pods -l k8s-app=cilium -o json | jq -r --arg node_name ${NODE_NAME} '.items[] | select(.spec.nodeName==$$node_name) | .metadata.name' |  tail -1 )
cilium-pod:
	@echo ">>>${NODE_NAME} ${CILIUM_POD}<<<"


cilium-debuginfo: cilium-pod
	kubectl -n cilium-system exec ${CILIUM_POD} -c cilium-agent -it -- cilium debuginfo

cilium-policy:
	kubectl -n cilium-system exec ${CILIUM_POD} -c cilium-agent -it -- cilium policy get

cilium-svc:
	kubectl -n cilium-system exec ${CILIUM_POD} -c cilium-agent -it -- cilium service list

cilium-ep:
	kubectl -n cilium-system exec ${CILIUM_POD} -c cilium-agent -it -- cilium endpoint list


EP:=1
cilium-get-ep:
	kubectl -n cilium-system exec ${CILIUM_POD} -c cilium-agent -it -- cilium endpoint get ${EP}

debug:
	kubectl debug -n cilium-system ${CILIUM_POD} -it --image=fl64/prober
