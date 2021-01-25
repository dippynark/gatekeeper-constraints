# docker

This directory contains the Docker images used to generate and validate ACM configs. Each image
contains a single tool.

## Images

Here we describe what each tool is used for in this repository:

- `gatekeeper_validate`: Validates ACM configs against Gatekeeper constraints
- `helm`: Templates Helm charts to be used as input to kfmt
- `istioctl`: Generates Istio configs to be used as input to kfmt
- `jx`: Configures Git to push to PR branch when using Jenkins to generate configs -- credentials
  are retrieved from a Kubernetes Secret
- `kfmt`: Formats configs into a canonical structure to be synced by ACM
- `konstraint`: Generates Gatekeeper constraints from Rego files to be used as input to kfmt
- `kpt`: Collects all configs into a single ResourceList to be validated by `gatekeeper_validate`
- `kubectl`: Patches a config to demonstrate a Gatekeeper constraint being invalidated
- `opa`: Runs Rego file unit tests
- `yq` : Strips the status field from configs to allow them to be synced by ACM
