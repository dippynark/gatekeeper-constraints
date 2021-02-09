// Ordinal to select DinD cache PVC
def PVC_ORDINAL = "${currentBuild.number.toInteger() % 3}"
// Prevent jenkins reusing agent yaml
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
  initContainers:
    - name: install-docker-bin
      command:
        - /bin/sh
        - -e
        - -x
        - -c
        - |
          cp -a \$(which docker) /opt/docker/bin
      image: docker:19.03-dind
      volumeMounts:
        - mountPath: /opt/docker/bin
          name: docker-bin
  containers:
    - name: dind
      image: docker:19.03-dind
      command:
        - dockerd
        - --host=unix:///var/run/docker-sock/docker.sock
        - --storage-driver=overlay
      securityContext:
        privileged: true
        capabilities:
          add: ["SYS_ADMIN"]
      volumeMounts:
        - mountPath: /lib/modules
          name: modules
          readOnly: true
        - mountPath: /sys/fs/cgroup
          name: cgroup
        - mountPath: /var/lib/docker
          name: var-lib-docker
        - mountPath: /var/run/docker-sock
          name: docker-sock
  volumes:
    - name: modules
      hostPath:
        path: /lib/modules
        type: Directory
    - name: cgroup
      hostPath:
        path: /sys/fs/cgroup
        type: Directory
    - name: var-lib-docker
      persistentVolumeClaim:
        claimName: dind-$PVC_ORDINAL
    - name: docker-bin
      emptyDir: {}
    - name: docker-sock
      emptyDir: {}
"""
    }
  }

  options {
    skipDefaultCheckout()
  }

  stages {
    stage('checkout') {
      steps {
        // TODO: checkout master and merge PR
        git url: 'https://github.com/dippynark/gatekeeper.git', branch: "${ghprbSourceBranch}"
      }
    }
  }
}
