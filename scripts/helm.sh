#!/bin/bash

set -euxo pipefail

STAGING_DIR=$1

DIR="$( cd "$( dirname "$0" )" && pwd )"

helm repo update

helm template charts/nginx --output-dir $STAGING_DIR
helm template jenkins jenkins/jenkins --namespace jenkins \
  -f $DIR/../charts/jenkins/values.yaml \
  --output-dir $STAGING_DIR
