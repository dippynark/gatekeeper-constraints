DOCKER_IMAGE = gatekeeper

CONFIGS_DIR = configs
STAGING_DIR = staging

JX_VERSION = 3.0.694
HELM_VERSION = 3.4.0
KPT_VERSION = 0.37.0
KUBECTL_VERSION = 1.19

all: test generate validate

test:
	opa test opa -v

docs:
	konstraint doc opa --output opa/README.md

opa/lib:
	# Download rego library
	# https://github.com/plexsystems/konstraint/issues/86
	git clone https://github.com/plexsystems/konstraint && \
		cd konstraint && \
		git checkout 155be70e49aa1483be47437252bc847db13c31bf
	cp -a konstraint/examples/lib opa/lib
	rm -rf konstraint

generate: opa/lib
	rm -rf $(CONFIGS_DIR) $(STAGING_DIR)
	mkdir -p $(CONFIGS_DIR) $(STAGING_DIR)
	# Generate configs
	helm template ./charts/nginx > $(STAGING_DIR)/nginx.yaml
	# Generate constraints
	konstraint create opa --output $(STAGING_DIR)
	jx gitops split -d $(STAGING_DIR)
	jx gitops rename -d $(STAGING_DIR)
	move --input-dir $(STAGING_DIR) \
		--output-dir $(CONFIGS_DIR) \
		--ignore-kind Secret
	rm -rf $(STAGING_DIR)

validate:
	# https://googlecontainertools.github.io/kpt/guides/consumer/function/
	# https://googlecontainertools.github.io/kpt/guides/consumer/function/catalog/validators/
	kpt fn source $(CONFIGS_DIR) | \
		kpt fn run --image gcr.io/kpt-functions/gatekeeper-validate >/dev/null

patch:
	kubectl patch --local -f charts/nginx/templates/deployment.yaml -p "`cat patch.yaml`" -o yaml \
		> charts/nginx/templates/deployment-patch.yaml
	mv charts/nginx/templates/deployment-patch.yaml charts/nginx/templates/deployment.yaml

docker_build:
	docker build \
		--build-arg JX_VERSION=$(JX_VERSION) \
		--build-arg HELM_VERSION=$(HELM_VERSION) \
		--build-arg KPT_VERSION=$(KPT_VERSION) \
		--build-arg KUBECTL_VERSION=$(KUBECTL_VERSION) \
		-t $(DOCKER_IMAGE) $(CURDIR)

docker_shell: docker_build
	docker run -it \
		-v $(CURDIR):/workspace \
		-v /var/run/docker.sock:/var/run/docker.sock \
		$(DOCKER_IMAGE)

docker_%: docker_build
	docker run -it \
		-v $(CURDIR):/workspace \
		-v /var/run/docker.sock:/var/run/docker.sock \
		$(DOCKER_IMAGE) \
		make $*
