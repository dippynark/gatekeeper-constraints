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
  - name: opa
    image: dippynark/opa:0.25.2
    command:
    - sleep
    - infinity
  - name: helm
    image: dippynark/helm:3.4.2
    command:
    - sleep
    - infinity
"""
    }
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
        container('helm') {
          sh '''
            ls
            pwd
          '''
        }
      }
    }
  }
}
