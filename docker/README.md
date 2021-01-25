# docker

This directory contains the Docker images used to generate ACM configs. Each image contains a single
tool.

## Images

Here we describe what each tool is used for in this repository:

- `gatekeeper_validate`: Validates ACM configs against Gatekeeper constraints
- `helm`: Templates Helm charts
- `istioctl`: Generates Istio configs
- `jx`: Configures Git to push to PR branch -- credentials are retrieved from a Kubernetes Secret.
  This tool could be replaced with `git` and environment variables
- `kfmt`: Formats configs into a canonical structure to be synced by ACM
- `konstraint`: Generates Gatekeeper constraints from Rego files
- `kpt`: Collects all configs into a single file to be validated by `gatekeeper_validate`
- `kubectl`: Patches a config to demonstrate a Gatekeeper constraint being invalidated
- `opa`: Unit tests Rego files
- `yq` : Strips the status field from configs to allow them to be picked up by ACM
