CLUSTER_NAME:=dev0
CONTEXT=kind-$(CLUSTER_NAME)

KIND_VER:=0.16.0
METALLB_VER:=0.13.5
CILIUM_VER:=1.12.3
# https://github.com/cilium/cilium-cli/commit/1c7c537aa2cb533f45d3e5917a53b27025c511c1
CILIUM_CLI_VER:=0.12.5
INGRESS_NGINX_CHART_VER:=4.3.0
CERTMANAGER_VER:=1.10.0

# https://kubernetes.io/releases/
# https://docs.cilium.io/en/v1.12/concepts/kubernetes/compatibility/
K8S_VER:=1.23.12

TMP_DIR:=./tmp

#msg_red = @echo "\033[91m$(1)\033[0m"
#msg_green = @echo "\033[92m$(1)\033[0m"

bold := $(shell tput bold)
red := $(shell tput setaf 1)
green := $(shell tput setaf 2)
sgr0 := $(shell tput sgr0)

msg_red = @echo "$(bold)$(red)$(1)$(sgr0)"
msg_green = @echo "$(bold)$(green)$(1)$(sgr0)"


.PHONY: help
# https://www.padok.fr/en/blog/beautiful-makefile-awk
help: ## display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

tmp:
	@mkdir -p $(TMP_DIR)

pull-helm-charts: # pull charts to $(TMP_DIR)
	helm pull cilium/cilium --untar --destination $(TMP_DIR) --version $(CILIUM_VER)

# init section =================================================================

init-hubble:
	$(eval HUBBLE_VERSION=$(shell curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt))
	echo $(HUBBLE_VERSION)
	sudo bash -c "curl -L https://github.com/cilium/hubble/releases/download/$(HUBBLE_VERSION)/hubble-linux-amd64.tar.gz | tar -xz -C /usr/local/bin/"


init-cilium: ## install cilium binary
	sudo bash -c "curl -L https://github.com/cilium/cilium-cli/releases/download/v$(CILIUM_CLI_VER)/cilium-linux-amd64.tar.gz | tar -xz -C /usr/local/bin/"

init-helm: ## add helm repos and update
	helm repo add cilium https://helm.cilium.io/
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo add jetstack https://charts.jetstack.io
	helm repo update

init-sysctl: ## add some sysctl params (solves problem "too many opened files")
	sudo sysctl fs.inotify.max_user_instances=512
	sudo sysctl fs.inotify.max_user_watches=2097152

init-kind: ## install kind binary
	curl -Lo ./kind https://kind.sigs.k8s.io/dl/v$(KIND_VER)/kind-linux-amd64
	chmod +x ./kind
	sudo mv ./kind /usr/local/bin/kind

init: init-helm init-sysctl init-kind init-cilium init-hubble ## init all

# install section ==============================================================

cluster: ## create cluster $(CLUSTER_NAME) with kind
	$(call msg_red,Create cluster $(CLUSTER_NAME) with k8s version v$(K8S_VER))
	@kind create cluster --image=kindest/node:v$(K8S_VER) --name $(CLUSTER_NAME) --config k8s/$(CLUSTER_NAME)/cluster.yaml

cluster-context:
	@kubectl config use-context $(CONTEXT) > /dev/null

install-cilium: cluster-context ## pull cilium images and install cilium chart for $(CLUSTER_NAME)
	$(call msg_green,Install cilium v$(CILIUM_VER) to $(CLUSTER_NAME))
	@docker pull quay.io/cilium/cilium:v$(CILIUM_VER)
	@kind load docker-image quay.io/cilium/cilium:v$(CILIUM_VER) -n $(CLUSTER_NAME)
	@helm upgrade --install cilium cilium/cilium \
	 --version $(CILIUM_VER) \
	 --create-namespace \
	 --namespace cilium-system \
	 --values k8s/common/cilium-values.yaml \
	 --values k8s/$(CLUSTER_NAME)/cilium-values.yaml
	@kubectl wait pod -n cilium-system --for=condition=ready --timeout=10m -l k8s-app=cilium

install-metallb: cluster-context ## install metallb for $(CLUSTER_NAME)
	$(call msg_green,Install metallb to $(CLUSTER_NAME))
	@kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v$(METALLB_VER)/config/manifests/metallb-native.yaml
	@kubectl wait pod -n metallb-system --for=condition=ready --timeout=10m -l app=metallb
	@docker network inspect -f '{{.IPAM.Config}}' kind
	@kubectl apply -f k8s/$(CLUSTER_NAME)/metallb.yaml

install-ingress: cluster-context ## install ingress-nginx for $(CLUSTER_NAME)
	$(call msg_green,Install ingress-ngins to $(CLUSTER_NAME))
	@helm upgrade --install nginx-ingress ingress-nginx/ingress-nginx \
	 --version $(INGRESS_NGINX_CHART_VER) \
	 --create-namespace \
   --namespace ingress-nginx-system
	@kubectl wait pod -n ingress-nginx-system --for=condition=ready --timeout=10m -l app.kubernetes.io/component=controller
	@echo ingress ip:
	@kubectl get svc -n ingress-nginx-system nginx-ingress-ingress-nginx-controller -o json | jq .status.loadBalancer.ingress[0].ip -r

# https://cert-manager.io/docs/installation/helm/#steps
install-certmanager: cluster-context ## install cert-manager for $(CLUSTER_NAME)
	$(call msg_green,Install cert-manager to $(CLUSTER_NAME))
	# kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v$(CERTMANAGER_VER)/cert-manager.crds.yaml
	@helm upgrade --install cert-manager jetstack/cert-manager \
	 --version v$(CERTMANAGER_VER) \
	 --create-namespace \
   --namespace cert-manager-system \
	 --set installCRDs=true

install: cluster install-cilium install-metallb install-ingress ## install all for $(CLUSTER_NAME)

# cleanup section ==============================================================

delete: ## delete cluster $(CLUSTER_NAME)
	kind delete cluster -n $(CLUSTER_NAME)

cleanup: delete
	@rm -rf $(TMP_DIR)

# info section =================================================================

hosts: cluster-context ## show records for /etc/hosts file
	@$(eval INGRESS_IP=$(shell 	kubectl get svc -n ingress-nginx-system nginx-ingress-ingress-nginx-controller -o json | jq .status.loadBalancer.ingress[0].ip -r))
	@$(call msg_red,"## add this lines to /etc/hosts")
	@echo hubble.$(CLUSTER_NAME).com $(INGRESS_IP)

cilium-status:
	cilium --context $(CONTEXT) -n cilium-system status
	cilium --context $(CONTEXT) -n cilium-system clustermesh status

cilium-template: tmp
	helm template cilium cilium/cilium \
	 --version $(CILIUM_VER) \
	 --create-namespace \
	 --namespace cilium-system \
	 --values k8s/common/cilium-values.yaml \
	 --values k8s/$(CLUSTER_NAME)/cilium-values.yaml \
	 > $(TMP_DIR)/cilium-$(CLUSTER_NAME)-debug.yaml

cilium-connect:
	cilium clustermesh connect --context kind-dev0 --destination-context kind-dev1 -n cilium-system

cilium-client-certs:
	#kubectl -n cilium-system get secret clustermesh-apiserver-client-cert -o json | jq '.data| ."tls.key" | @base64d'
	kubectl -n cilium-system get secret clustermesh-apiserver-client-cert -o json | jq '.data|=map(.|=@base64d)|.data'

# test section =================================================================

hubble-port-forward:
	cilium --context $(CONTEXT) -n cilium-system hubble port-forward&

install-test-app:
	kubectl --context $(CONTEXT) apply -k test/cilium/overlays/$(CLUSTER_NAME)

delete-test-app:
	kubectl --context $(CONTEXT) delete -k test/cilium/overlays/$(CLUSTER_NAME) --force --grace-period=0
