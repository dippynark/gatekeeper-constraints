#!/bin/bash

set -euxo pipefail

STAGING_DIR=$1

DIR="$( cd "$( dirname "$0" )" && pwd )"

helm repo update

helm template charts/nginx --output-dir $STAGING_DIR
# https://github.com/jenkinsci/helm-charts
helm template jenkins jenkins/jenkins --namespace jenkins \
  --version $JENKINS_VERSION \
  -f $DIR/../charts/jenkins/values.yaml \
  --output-dir $STAGING_DIR
