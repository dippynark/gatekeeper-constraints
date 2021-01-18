// Prevent Jenkins reusing agent YAML
def UUID = UUID.randomUUID().toString()
pipeline {
  agent {
    kubernetes {
      label "kind-$UUID"
      defaultContainer 'jnlp'
      yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: opa
    image: busybox
    command:
    - sleep
    - infinity
"""
    }
  }
  stages {
    stage('test') {
      steps {
        container('busybox') {
          echo 'test'
        }        
      }
    }
  }
}
