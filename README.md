# Gatekeeper

This repository is an example of how to manage
[Gatekeeper](https://github.com/open-policy-agent/gatekeeper) constraints.

## Repository Structure

Here we give an overview of the repository structure -- some directories contain more specific
information.

```sh
# Helm charts (or any configuration to be hydrated)
charts/
# Hydrated configs in a structured format to be synced to a Kubernetes cluster
configs/
  # Non-namespaced resources separated into directories per resource kind
  cluster/
    cluster-roles/
    ...
  # Namespaced resources separated into directories per Namespace
  namespaces/
    kube-system/
    ...
# Docker images used for config generation and validation
docker/
# Rego files and unit tests
opa/
# Configs to be copied into the `configs` directory without hydration
raw/
# Scripts for config generation and validation
scripts/
# Ignored files
.gitignore
# Cached API Server discovery information used by kfmt
api-resources.txt
# ACM configuration
config-management.yaml
# Jenkinsfile for running generation and validation as part of CI
Jenkinsfile
# Orchestrates config generation and validation
Makefile
# Patch to invalidate Rego policy for demo purposes
patch.yaml
# This file
README.md
```

## Quickstart

Ensure Docker and make are installed.

```sh
# Build dependent Docker images
make docker_build
# Run Rego unit tests
make test
# Generate configs and Gatekeeper constraints and output them to the configs directory
make generate
# Validate configs against constraints
make validate
# Now try invalidating a constraint...
make patch
# ...and rerunning everything to show violations
make all
```
