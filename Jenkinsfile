def BUSYBOX_VERSION = "1.32"
def OPA_VERSION = "0.25.2"
def HELM_VERSION = "3.4.2"
def ISTIOCTL_VERSION = "1.8.0"
def YQ_VERSION = "4.4.1"
def KONSTRAINT_VERSION = "0.10.0"
def KFMT_VERSION = "14aeb39f569fb311338b467ac0ebbfd7b929ea8c"
def MOVE_VERSION = "0.0.1"
def KPT_VERSION = "0.37.0"
def GATEKEEPER_VALIDATE_VERSION = "release-kpt-functions-v0.14.5"
def JX_VERSION = "3.1.137"
def JENKINS_VERSION = "3.0.14"

// Prevent Jenkins reusing agent YAML
def UUID = UUID.randomUUID().toString()
pipeline {
  agent {
    kubernetes {
      defaultContainer 'jnlp'
      yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    name: generate-${UUID}
spec:
  serviceAccountName: generate
  containers:
  - name: busybox
    image: busybox:${BUSYBOX_VERSION}
    command:
    - sleep
    - infinity
  - name: opa
    image: dippynark/opa:${OPA_VERSION}
    command:
    - sleep
    - infinity
  - name: helm
    image: dippynark/helm:${HELM_VERSION}
    env:
    - name: JENKINS_VERSION
      value: ${JENKINS_VERSION}
    command:
    - sleep
    - infinity
  - name: istioctl
    image: dippynark/istioctl:${ISTIOCTL_VERSION}
    command:
    - sleep
    - infinity
  - name: yq
    image: dippynark/yq:${YQ_VERSION}
    command:
    - sleep
    - infinity
  - name: konstraint
    image: dippynark/konstraint:${KONSTRAINT_VERSION}
    command:
    - sleep
    - infinity
  - name: kfmt
    image: dippynark/kfmt:${KFMT_VERSION}
    command:
    - sleep
    - infinity
  - name: kpt
    image: dippynark/kpt:${KPT_VERSION}
    command:
    - sleep
    - infinity
  - name: gatekeeper-validate
    image: dippynark/gatekeeper_validate:${GATEKEEPER_VALIDATE_VERSION}
    command:
    - sleep
    - infinity
  - name: jx
    image: dippynark/jx:${JX_VERSION}
    imagePullPolicy: Always
    env:
    - name: XDG_CONFIG_HOME
      value: /home/jenkins/agent
    command:
    - sleep
    - infinity
"""
    }
  }
  environment {
    CONFIGS_DIR = 'configs'
    STAGING_DIR = 'staging'

    CERT_MANAGER_VERSION = "1.1.0"
  }

  options {
    skipDefaultCheckout()
  }

  stages {
    stage('checkout') {
      steps {
        git url: 'https://github.com/dippynark/gatekeeper.git', branch: "${ghprbSourceBranch}"
      }
    }
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
        container('busybox') {
          sh "cp -r raw ${STAGING_DIR}"
        }
        container('konstraint') {
          sh "konstraint create opa --output ${STAGING_DIR}"
        }
        container('kfmt') {
          sh """
            kfmt --input-dir ${STAGING_DIR} \
              --output-dir ${CONFIGS_DIR} \
              --filter-kind-group Secret \
			        --clean
          """
        }
        container('busybox') {
          sh "rm -r ${STAGING_DIR}"
        }
      }
    }
    stage('validate') {
      steps {
        container('kpt') {
          sh "kpt fn source ${CONFIGS_DIR} > configs.yaml"
        }
        container('gatekeeper-validate') {
          sh "gatekeeper_validate --input configs.yaml >/dev/null"
        }
        container('busybox') {
          sh "rm configs.yaml"
        }
      }
    }
    stage('push') {
      steps {
        container('jx') {
          sh """
            jx gitops git setup --secret git-auth --email lukeaddison.785@gmail.com
            git add --all
	          git status
	          git commit -m "Generated" || true
            git pull origin ${ghprbSourceBranch} --rebase
            git push origin ${ghprbSourceBranch}
          """
        }
      }
    }
  }
}
