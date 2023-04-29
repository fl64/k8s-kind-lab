CLUSTER_NAME:=dev0
CONTEXT=kind-$(CLUSTER_NAME)

KIND_VER:=0.16.0
METALLB_VER:=0.13.5
CILIUM_VER:=1.12.7

ISTIO_VERSION:=1.16.1
# https://github.com/cilium/cilium-cli/commit/1c7c537aa2cb533f45d3e5917a53b27025c511c1
CILIUM_CLI_VER:=0.13.1
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
	helm pull cilium/cilium --untar --destination $(TMP_DIR) --version $(CILIUM_VER) || true

# init section =================================================================

init-hubble: ## install hubble binary
	@$(eval HUBBLE_VERSION=$(shell curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt))
	@$(call msg_green,Install hubble $(HUBBLE_VERSION))
	sudo bash -c "curl -Lsq https://github.com/cilium/hubble/releases/download/$(HUBBLE_VERSION)/hubble-linux-amd64.tar.gz | tar -xz -C /usr/local/bin/"

init-cilium-cli: ## install cilium binary
	@$(call msg_green,Install cilium-cli $(CILIUM_CLI_VER))
	sudo bash -c "curl -Lsq https://github.com/cilium/cilium-cli/releases/download/v$(CILIUM_CLI_VER)/cilium-linux-amd64.tar.gz | tar -xz -C /usr/local/bin/"

init-helm: ## add helm repos and update
	@$(call msg_green,Add helm repos and update)
	@helm repo add cilium https://helm.cilium.io/
	@helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	@helm repo add jetstack https://charts.jetstack.io
	@helm repo update

init-istio: tmp
	@$(call msg_green,Download istio $(ISTIO_VERSION) binary and manifests)
	@cd $(TMP_DIR) && curl -Lsq https://istio.io/downloadIstio | ISTIO_VERSION=$(ISTIO_VERSION) TARGET_ARCH=x86_64 sh -

init-sysctl: ## add some sysctl params (solves problem "too many opened files")
	sudo sysctl fs.inotify.max_user_instances=512
	sudo sysctl fs.inotify.max_user_watches=2097152

init-kind: ## install kind binary
	@$(call msg_green,Install Kind $(KIND_VER))
	@curl -Lsqo ./kind https://kind.sigs.k8s.io/dl/v$(KIND_VER)/kind-linux-amd64
	@chmod +x ./kind
	@sudo mv ./kind /usr/local/bin/kind

init: init-helm init-sysctl init-kind init-cilium init-hubble ## init all

# install section ==============================================================

cluster: ## create cluster $(CLUSTER_NAME) with kind
	$(call msg_red,Create cluster $(CLUSTER_NAME) with k8s version v$(K8S_VER))
	@kind create cluster --image=kindest/node:v$(K8S_VER) --name $(CLUSTER_NAME) --config k8s/$(CLUSTER_NAME)/kind/cluster.yaml

cluster-context:
	@kubectl config use-context $(CONTEXT) > /dev/null

# install system apps

pre-install-cilium:
	$(call msg_green,Pull cilium v$(CILIUM_VER) images to $(CLUSTER_NAME))
	@docker pull quay.io/cilium/cilium:v$(CILIUM_VER)
	@kind load docker-image quay.io/cilium/cilium:v$(CILIUM_VER) -n $(CLUSTER_NAME)

install-cilium: pre-install-cilium ## pull cilium images and install cilium chart for $(CLUSTER_NAME)
	$(call msg_green,Install cilium v$(CILIUM_VER) to $(CLUSTER_NAME))
	@helm upgrade \
		--kube-context $(CONTEXT) \
		--install cilium cilium/cilium \
		--version $(CILIUM_VER) \
		--create-namespace \
		--namespace cilium-system \
		--values k8s/common/helm/cilium-values.yaml \
		--values k8s/$(CLUSTER_NAME)/helm/cilium-values.yaml
	@kubectl --context $(CONTEXT)  wait pod -n cilium-system --for=condition=ready --timeout=10m -l k8s-app=cilium

install-metallb: ## install metallb for $(CLUSTER_NAME)
	$(call msg_green,Install metallb to $(CLUSTER_NAME))
	@kubectl --context $(CONTEXT) apply -f https://raw.githubusercontent.com/metallb/metallb/v$(METALLB_VER)/config/manifests/metallb-native.yaml
	@kubectl --context $(CONTEXT) wait pod -n metallb-system --for=condition=ready --timeout=10m -l app=metallb
	@docker network inspect -f '{{.IPAM.Config}}' kind
	@kubectl --context $(CONTEXT) apply -f k8s/$(CLUSTER_NAME)/metallb.yaml

install-ingress: ## install ingress-nginx for $(CLUSTER_NAME)
	$(call msg_green,Install ingress-ngins to $(CLUSTER_NAME))
	@helm upgrade \
		--kube-context $(CONTEXT) \
		--install nginx-ingress ingress-nginx/ingress-nginx \
		--version $(INGRESS_NGINX_CHART_VER) \
		--create-namespace \
		--namespace ingress-nginx-system
	@kubectl --context $(CONTEXT) wait pod -n ingress-nginx-system --for=condition=ready --timeout=10m -l app.kubernetes.io/component=controller
	@echo ingress ip:
	@kubectl --context $(CONTEXT) get svc -n ingress-nginx-system nginx-ingress-ingress-nginx-controller -o json | jq .status.loadBalancer.ingress[0].ip -r

# https://cert-manager.io/docs/installation/helm/#steps
install-certmanager: ## install cert-manager for $(CLUSTER_NAME)
	$(call msg_green,Install cert-manager to $(CLUSTER_NAME))
	# kubectl --context $(CONTEXT) apply -f https://github.com/cert-manager/cert-manager/releases/download/v$(CERTMANAGER_VER)/cert-manager.crds.yaml
	@helm upgrade \
		--kube-context $(CONTEXT) \
		--install cert-manager jetstack/cert-manager \
		--version v$(CERTMANAGER_VER) \
		--create-namespace \
		--namespace cert-manager-system \
		--set installCRDs=true

install: init-helm cluster install-cilium install-metallb install-ingress ## install all for $(CLUSTER_NAME)

# istio

install-istio-operator: init-istio cluster-context ## install cert-manager for $(CLUSTER_NAME)
	$(call msg_green,Install istio to $(CLUSTER_NAME))
	@helm upgrade \
		--kube-context $(CONTEXT) \
		--install istio-operator $(TMP_DIR)/istio-$(ISTIO_VERSION)/manifests/charts/istio-operator \
		--create-namespace \
		--namespace istio-system \
		--set installCRDs=true

install-istio-iop:
	$(call msg_green,Install iop resource $(CLUSTER_NAME))
	kubectl --context $(CONTEXT) \ apply -f k8s/$(CLUSTER_NAME)/istio-operator.yaml

install-istio-tools:
	$(call msg_green,Install istio tools to $(CLUSTER_NAME))
	kubectl --context $(CONTEXT) apply -f $(TMP_DIR)/istio-$(ISTIO_VERSION)/samples/addons/prometheus.yaml
	kubectl --context $(CONTEXT) apply -f $(TMP_DIR)/istio-$(ISTIO_VERSION)/samples/addons/kiali.yaml
	kubectl --context $(CONTEXT) apply -f $(TMP_DIR)/istio-$(ISTIO_VERSION)/samples/addons/jaeger.yaml
	# kubectl apply -f $(TMP_DIR)/istio-$(ISTIO_VERSION)/samples/addons/extras/zipkin.yaml
	kubectl --context $(CONTEXT) apply -f k8s/$(CLUSTER_NAME)/kiali-ingress.yaml
	kubectl --context $(CONTEXT) apply -f k8s/$(CLUSTER_NAME)/prom-ingress.yaml
	kubectl --context $(CONTEXT) apply -f k8s/$(CLUSTER_NAME)/jaeger-ingress.yaml


install-istio: install-istio-operator install-istio-iop install-istio-tools

# cleanup section ==============================================================

delete: ## delete cluster $(CLUSTER_NAME)
	kind delete cluster -n $(CLUSTER_NAME)

cleanup: delete
	@rm -rf $(TMP_DIR)

# info section =================================================================

hosts: cluster-context ## show records for /etc/hosts file
	@$(eval INGRESS_IP=$(shell 	kubectl --context $(CONTEXT) get svc -n ingress-nginx-system nginx-ingress-ingress-nginx-controller -o json | jq .status.loadBalancer.ingress[0].ip -r))
	@$(eval ISTIO_INGRESS_IP=$(shell kubectl --context $(CONTEXT) get svc -n istio-system istio-ingressgateway -o json | jq .status.loadBalancer.ingress[0].ip -r))
	@$(call msg_red,"## add this lines to for nginx ingress /etc/hosts")
	@echo hubble.$(CLUSTER_NAME).com $(INGRESS_IP)
	@echo kiali.$(CLUSTER_NAME).com $(INGRESS_IP)
	@echo prom.$(CLUSTER_NAME).com $(INGRESS_IP)
	@echo zipkin.$(CLUSTER_NAME).com $(INGRESS_IP)
	@$(call msg_red,"## add this lines to for istio ingress gateway /etc/hosts")
	@echo hubble.$(CLUSTER_NAME).com $(ISTIO_INGRESS_IP)
	@echo kiali.$(CLUSTER_NAME).com $(ISTIO_INGRESS_IP)

# cilium =======================================================================

cilium-status:
	cilium --context $(CONTEXT) -n cilium-system status
	cilium --context $(CONTEXT) -n cilium-system clustermesh status

cilium-template: tmp
	helm template cilium cilium/cilium \
		--kube-context $(CONTEXT) \
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
	kubectl --context $(CONTEXT) -n cilium-system get secret clustermesh-apiserver-client-cert -o json | jq '.data|=map(.|=@base64d)|.data'

# hubble =======================================================================

hubble-port-forward:
	cilium --context $(CONTEXT) -n cilium-system hubble port-forward&
