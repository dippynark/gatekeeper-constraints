# Gatekeeper

This repository is an example of how to manage
[Gatekeeper](https://github.com/open-policy-agent/gatekeeper) constraints.

## Repository Structure

Here we give an overview of the repository structure -- some directories contain more specific
information.

```sh
# Helm charts (or any configuration to be hydrated)
charts/
cmd/
  # Binary that takes an input directory of hydrated configs and outputs them to the configs structure
  move/
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
# Rego files and unit tests
opa/
# Docker image containing dependecies for testing, generating and validating policies and configs
Dockerfile
# Golang depencies for `cmd` binaries
go.mod
go.sum
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
