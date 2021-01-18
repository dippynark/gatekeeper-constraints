// Prevent Jenkins reusing agent YAML
def UUID = UUID.randomUUID().toString()
pipeline {
  agent {
    kubernetes {
      label "generate-$UUID"
      defaultContainer 'jnlp'
      yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: busybox
    image: busybox:1.32
    command:
    - sleep
    - infinity
  - name: opa
    image: dippynark/opa:${OPA_VERSION}
    command:
    - sleep
    - infinity
  - name: helm
    image: dippynark/helm:3.4.2
    command:
    - sleep
    - infinity
  - name: istioctl
    image: dippynark/istioctl:1.8.0
    command:
    - sleep
    - infinity
  - name: yq
    image: dippynark/yq:4.4.1
    command:
    - sleep
    - infinity
  - name: konstraint
    image: dippynark/konstraint:0.10.0
    command:
    - sleep
    - infinity
  - name: jx
    image: dippynark/jx:3.0.694
    command:
    - sleep
    - infinity
  - name: move
    image: dippynark/move:0.0.1
    command:
    - sleep
    - infinity
"""
    }
  }
  environment {
    CONFIGS_DIR = 'configs'
    STAGING_DIR = 'staging'

    OPA_VERSION = 0.25.2
    HELM_VERSION = 3.4.2
    ISTIOCTL_VERSION = 1.8.0
    CERT_MANAGER_VERSION = 1.1.0
    YQ_VERSION = 4.4.1
  }
  stages {
    stage('test') {
      steps {
        container('opa') {
          sh "opa test opa -v"
        }
      }
    }
    stage('generate') {
      steps {
        container('busybox') {
          sh """
            rm -rf ${CONFIGS_DIR} ${STAGING_DIR}
            mkdir ${CONFIGS_DIR} ${STAGING_DIR}
          """
        }
        container('helm') {
          sh "scripts/helm.sh ${STAGING_DIR}"
        }
        container('istioctl') {
          sh "istioctl manifest generate > ${STAGING_DIR}/istio.yaml"
        }
        container('yq') {
          sh """
            curl -LO https://github.com/jetstack/cert-manager/releases/download/v${CERT_MANAGER_VERSION}/cert-manager.yaml
            yq eval -i 'del(.status)' cert-manager.yaml
            mv cert-manager.yaml ${STAGING_DIR}/cert-manager.yaml
          """
        }
        container('konstraint') {
          sh "konstraint create opa --output ${STAGING_DIR}"
        }
        container('jx') {
          sh """
            jx gitops split -d ${STAGING_DIR}
            jx gitops rename -d ${STAGING_DIR}
          """
        }
        container('move') {
          sh """
            move --input-dir ${STAGING_DIR} \
              --output-dir ${CONFIGS_DIR} \
              --ignore-kind Secret
          """
        }
        container('busybox') {
          sh "rm -r ${STAGING_DIR}"
        }
      }
    }
  }
}
