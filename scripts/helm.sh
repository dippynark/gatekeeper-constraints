#!/bin/bash

set -euxo pipefail

STAGING_DIR=$1

helm repo update

helm template charts/nginx --output-dir $STAGING_DIR
helm template jenkins jenkins/jenkins --namespace jenkins --output-dir $STAGING_DIR
