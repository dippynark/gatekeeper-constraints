# Gatekeeper

This repository is an example of how to manage
[Gatekeeper](https://github.com/open-policy-agent/gatekeeper) constraints.

## Quickstart

Ensure Docker and make are installed.

```sh
# Test OPA policies
make docker_test
# Generate configs and constraints
make docker_generate
# Validate configs against constraints
make docker_validate
# Now try invalidating a constraint...
make docker_patch
# ...and rerunning everything to show violations
make docker_all
```
