CONFIGS_DIR = configs
STAGING_DIR = staging

OPA_VERSION = 0.25.2
HELM_VERSION = 3.4.2
KONSTRAINT_VERSION = 0.10.0
JX_VERSION = 3.0.694
KPT_VERSION = 0.37.0
KUBECTL_VERSION = 1.19.6

all: test generate validate

# Setup
opa/README.md: docker_build_konstraint
	docker run -it \
		-v $(CURDIR):/workspace \
		konstraint doc opa --output opa/README.md

opa/lib:
	# Download rego library
	# https://github.com/plexsystems/konstraint/issues/86
	git clone https://github.com/plexsystems/konstraint && \
		cd konstraint && \
		git checkout 155be70e49aa1483be47437252bc847db13c31bf
	cp -a konstraint/examples/lib opa/lib
	rm -r konstraint

# Docker images
docker_build_opa:
	docker build --build-arg OPA_VERSION=$(OPA_VERSION) -t opa:$(OPA_VERSION) -f docker/Dockerfile.opa .

docker_build_helm:
	docker build --build-arg HELM_VERSION=$(HELM_VERSION) -t helm:$(HELM_VERSION) -f docker/Dockerfile.helm .

docker_build_konstraint:
	docker build --build-arg KONSTRAINT_VERSION=$(KONSTRAINT_VERSION) -t konstraint:$(KONSTRAINT_VERSION) -f docker/Dockerfile.konstraint .

docker_build_jx:
	docker build --build-arg JX_VERSION=$(JX_VERSION) -t jx:$(JX_VERSION) -f docker/Dockerfile.jx .

docker_build_kpt:
	docker build --build-arg KPT_VERSION=$(KPT_VERSION) -t kpt:$(KPT_VERSION) -f docker/Dockerfile.kpt .

docker_build_kubectl:
	docker build --build-arg KUBECTL_VERSION=$(KUBECTL_VERSION) -t kubectl:$(KUBECTL_VERSION) -f docker/Dockerfile.kubectl .

docker_build_move:
	docker build -t move -f docker/Dockerfile.move .

# Steps
test: docker_build_opa
	docker run -it \
		-v $(CURDIR):/workspace \
		opa:$(OPA_VERSION) test opa -v

generate: docker_build_helm docker_build_konstraint docker_build_jx docker_build_move
	rm -rf $(CONFIGS_DIR) $(STAGING_DIR)
	mkdir -p $(CONFIGS_DIR) $(STAGING_DIR)
	# Generate configs
	docker run -it \
		-v $(CURDIR):/workspace \
		helm:$(HELM_VERSION) template charts/nginx --output-dir $(STAGING_DIR)
	# Generate constraint configs
	docker run -it \
		-v $(CURDIR):/workspace \
		konstraint:$(KONSTRAINT_VERSION) create opa --output $(STAGING_DIR)
	# Strucuture configs
	docker run -it \
		-v $(CURDIR):/workspace \
		jx:$(JX_VERSION) gitops split -d $(STAGING_DIR)
	docker run -it \
		-v $(CURDIR):/workspace \
		jx:$(JX_VERSION) gitops rename -d $(STAGING_DIR)
	docker run -it \
		-v $(CURDIR):/workspace \
		move --input-dir $(STAGING_DIR) \
			--output-dir $(CONFIGS_DIR) \
			--ignore-kind Secret
	rm -r $(STAGING_DIR)

validate: docker_build_kpt
	# https://googlecontainertools.github.io/kpt/guides/consumer/function/
	# https://googlecontainertools.github.io/kpt/guides/consumer/function/catalog/validators/
	# Unfortunately the validation modifies the configs (slightly) so we validate a copy instead. An
	# alternative would be to pipe the input configs to kpt (using kpt) instead of referencing the
	# configs directory, but this is a bit tricky with the way we're running commands with Docker:
	# kpt fn source $(CONFIGS_DIR) | kpt fn run --image gcr.io/kpt-functions/gatekeeper-validate >/dev/null
	rm -rf $(CONFIGS_DIR)-validate
	cp -a $(CONFIGS_DIR) $(CONFIGS_DIR)-validate
	docker run -it \
		-v $(CURDIR):/workspace \
		-v /var/run/docker.sock:/var/run/docker.sock \
		kpt:$(KPT_VERSION) fn run $(CONFIGS_DIR)-validate --image gcr.io/kpt-functions/gatekeeper-validate
	rm -r $(CONFIGS_DIR)-validate

patch: docker_build_kubectl
	docker run -it \
		-v $(CURDIR):/workspace \
		kubectl:$(KUBECTL_VERSION) patch --local -f charts/nginx/templates/deployment.yaml -p "`cat patch.yaml`" -o yaml \
			| tr -d '\r' \
			> charts/nginx/templates/deployment-patch.yaml
	mv charts/nginx/templates/deployment-patch.yaml charts/nginx/templates/deployment.yaml
