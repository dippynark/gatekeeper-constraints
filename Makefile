REPOSITORY = dippynark

CONFIGS_DIR = configs
STAGING_DIR = staging

OPA_VERSION = 0.25.2
HELM_VERSION = 3.4.2
ISTIOCTL_VERSION = 1.8.0
CERT_MANAGER_VERSION = 1.1.0
YQ_VERSION = 4.4.1
KONSTRAINT_VERSION = 0.10.0
KFMT_VERSION = 0.2.1
KPT_VERSION = 0.37.0
GATEKEEPER_VALIDATE_VERSION = release-kpt-functions-v0.14.5
KUBECTL_VERSION = 1.19.6
JX_VERSION = 3.1.137
JENKINS_VERSION = 3.1.8

all: test generate validate

# Setup
opa/README.md:
	docker run -it \
		-v $(CURDIR):/workspace \
		$(REPOSITORY)/konstraint:$(KONSTRAINT_VERSION) doc opa --output opa/README.md

opa/lib:
	# Download rego library
	# https://github.com/plexsystems/konstraint/issues/86
	git clone https://github.com/plexsystems/konstraint && \
		cd konstraint && \
		git checkout 155be70e49aa1483be47437252bc847db13c31bf
	cp -a konstraint/examples/lib opa/lib
	rm -r konstraint

# Docker images
docker_build: docker_build_helm docker_build_istioctl docker_build_kfmt docker_build_konstraint docker_build_kpt docker_build_kubectl docker_build_opa docker_build_yq docker_build_jx

docker_build_%:
	docker build --build-arg $(shell echo $* | tr '[:lower:]' '[:upper:]')_VERSION=$($(shell echo $* | tr '[:lower:]' '[:upper:]')_VERSION) \
		-t $(REPOSITORY)/$*:$($(shell echo $* | tr '[:lower:]' '[:upper:]')_VERSION) \
		-f docker/Dockerfile.$* .

docker_push: docker_push_helm docker_push_istioctl docker_push_kfmt docker_push_konstraint docker_push_kpt docker_push_kubectl docker_push_opa docker_push_yq docker_push_jx

docker_push_%:
	docker push $(REPOSITORY)/$*:$($(shell echo $* | tr '[:lower:]' '[:upper:]')_VERSION)

# Steps
test:
	docker run -it \
		-v $(CURDIR):/workspace \
		opa:$(OPA_VERSION) test opa -v

generate:
	rm -rf $(CONFIGS_DIR) $(STAGING_DIR)
	mkdir -p $(CONFIGS_DIR) $(STAGING_DIR)
	# Generate configs
	docker run -it \
		-v $(CURDIR):/workspace \
		-e JENKINS_VERSION=$(JENKINS_VERSION) \
		--entrypoint=/workspace/scripts/helm.sh \
		$(REPOSITORY)/helm:$(HELM_VERSION) $(STAGING_DIR)
	docker run -it \
		-v $(CURDIR):/workspace \
		$(REPOSITORY)/istioctl:$(ISTIOCTL_VERSION) manifest generate | tr -d '\r' > $(STAGING_DIR)/istio.yaml
	docker run -it \
		-v $(CURDIR):/workspace \
		-e CERT_MANAGER_VERSION=$(CERT_MANAGER_VERSION) \
		--entrypoint=/workspace/scripts/yq.sh \
		$(REPOSITORY)/yq:$(YQ_VERSION) $(STAGING_DIR)
	cp -r raw $(STAGING_DIR)
	# Generate constraint configs
	docker run -it \
		-v $(CURDIR):/workspace \
		$(REPOSITORY)/konstraint:$(KONSTRAINT_VERSION) create opa --output $(STAGING_DIR)
	# Strucuture configs
	docker run -it \
		-v $(CURDIR):/workspace \
		$(REPOSITORY)/kfmt:$(KFMT_VERSION) --input $(STAGING_DIR) \
			--output $(CONFIGS_DIR) \
			--filter Secret \
			--create-missing-namespaces \
			--clean
	rm -r $(STAGING_DIR)
	jx gitops annotate --dir $(CONFIGS_DIR)/namespaces/nginx configmanagement.gke.io/managed=disabled

validate:
	# https://googlecontainertools.github.io/kpt/guides/consumer/function/
	# https://googlecontainertools.github.io/kpt/guides/consumer/function/catalog/validators/
	# https://cloud.google.com/anthos-config-management/docs/how-to/app-policy-validation-ci-pipeline
	# https://github.com/GoogleContainerTools/kpt-functions-sdk/tree/master/go/cmd/gatekeeper_validate
	docker run -it \
		-v $(CURDIR):/workspace \
		$(REPOSITORY)/kpt:$(KPT_VERSION) fn source $(CONFIGS_DIR) | \
		docker run -i \
			-v $(CURDIR):/workspace \
			$(REPOSITORY)/gatekeeper_validate:$(GATEKEEPER_VALIDATE_VERSION) >/dev/null

patch:
	docker run -it \
		-v $(CURDIR):/workspace \
		$(REPOSITORY)/kubectl:$(KUBECTL_VERSION) patch --local -f charts/nginx/templates/deployment.yaml -p "`cat patch.yaml`" -o yaml \
			| tr -d '\r' \
			> charts/nginx/templates/deployment-patch.yaml
	mv charts/nginx/templates/deployment-patch.yaml charts/nginx/templates/deployment.yaml
