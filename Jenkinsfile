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
  - name: busybox
    image: busybox
    command:
    - sh
    - -c
    - |
      tail -f /dev/null
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
