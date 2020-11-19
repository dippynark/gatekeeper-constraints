# Policies

## Violations

* [P1006: Pods must not run with access to the host networking](#p1006-pods-must-not-run-with-access-to-the-host-networking)

## P1006: Pods must not run with access to the host networking

**Severity:** Violation

**Resources:** apps/DaemonSet apps/Deployment apps/StatefulSet core/Pod

Pods that can access the host's network interfaces can potentially
access and tamper with traffic the pod should not have access to.

### Rego

```rego
package pod_deny_host_network

import data.lib.core
import data.lib.pods

policyID := "P1006"

violation[msg] {
    pod_has_hostnetwork

    msg := core.format_with_id(sprintf("%s/%s: Pod allows for accessing the host network", [core.kind, core.name]), policyID)
}

pod_has_hostnetwork {
    pods.pod.spec.hostNetwork
}
```

_source: [pod-deny-host-network](pod-deny-host-network)_
