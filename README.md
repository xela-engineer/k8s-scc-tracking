# k8s-scc-tracking #
This is a project for keep tacking the OpenShift's SCC changes.
SCC is the permission setting for workloads in K8S world.
Admin keep tracking the SCC may helps on security defences aspect of Kubernetes.

## Core concept of SCC ##

### What is SCC? ###

SCC is permissions determine the actions that a pod can perform and what resources it can access.
We can just think SCC as Selinux.

### How SCC attach to workloads? ###

1. SCC config YAML direct attach to users, ServiceAccount, groups
    1. SCC -> SA
    2. SCC -> User
    3. SCC -> Group

2. SCC attach to roles, then ServiceAccount bind to clusterRole/Role by clusterEoleBinding/roleBinding
    1. SCC -> Role -> ClusterRoleBinding/RoleBinding -> SA

## Quick Start ##

``` sh
cd ./script
# review and edit .env if needed
source ./.env && ./main.sh "/root/scc-monitoring/backup-repo/scc-monitoring/" "https://api.das2.expert.com:6443" "OCP API token"
```

## Development ##

Execute the script:
``` sh
cd /root/scc-monitoring/k8s-scc-tracking/script
source ./.env && ./main.sh "/root/scc-monitoring/backup-repo/scc-monitoring/" "https://api.das2.expert.com:6443" "OCP API token"
```

Check the result:
``` sh
cd /root/scc-monitoring/backup-repo/scc-monitoring
ll

# get the list of priviledge scc's clusterrole
oc get clusterrole --all-namespaces -ojson | jq '.items | [.[] |select(.rules[]?.resourceNames[]?=="privileged")] | [.[] | {name: .metadata.name}]'

# It will return
# [
#   {
#     "name": "cluster-node-tuning:tuned"
#   },
#   {
#     "name": "file-integrity-operator.v1.3.2-file-integrity-daemon-5799d9948"
#   },
#   {
#     "name": "file-integrity-operator.v1.3.2-file-integrity-operator-8989b4ccd"
#   },
#   {
#     "name": "machine-config-daemon"
#   },
#   {
#     "name": "openshift-ovn-kubernetes-controller"
#   },
#   {
#     "name": "system:openshift:scc:privileged"
#   },
#   {
#     "name": "vmware-vsphere-csi-driver-operator-clusterrole"
#   },
#   {
#     "name": "vmware-vsphere-privileged-role"
#   }
# ]

# get clusterrolebinding for the role vmware-vsphere-privileged-role
oc get clusterrolebinding -ojson | jq '.items | [.[]? | select((.roleRef.name=="vmware-vsphere-privileged-role") and (.roleRef.kind=="ClusterRole") )] | [ .[].subjects[]? | select(.kind=="ServiceAccount") ] | (map(keys) | add | unique) as $cols | map(. as $row | $cols | map($row[.])) as $rows |  $rows[] | @csv ' | sed 's/["\/]//g' | sed 's/,/ /g'

# It will return
# ServiceAccount "SA Name" "SA namespace"
# ServiceAccount vmware-vsphere-csi-driver-controller-sa openshift-cluster-csi-drivers
# ServiceAccount vmware-vsphere-csi-driver-node-sa openshift-cluster-csi-drivers
```

### jq commands ###

1. change json to table
    ``` sh
    cat "..." | jq -r '(map(keys) | add | unique) as $cols | map(. as $row | $cols | map($row[.])) as $rows |  $col,$rows[] | @csv '
    ```
## CICD ##

A jenkins CICD helps to do the bash quality code scan.
