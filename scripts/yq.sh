#!/bin/bash

set -euxo pipefail

STAGING_DIR=$1

curl -LO "https://github.com/jetstack/cert-manager/releases/download/v${CERT_MANAGER_VERSION}/cert-manager.yaml"
yq eval -i 'del(.status)' cert-manager.yaml
mv cert-manager.yaml "${STAGING_DIR}/cert-manager.yaml"
