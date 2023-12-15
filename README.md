# k8s-scc-tracking
This is a project for keep tacking the OpenShift's SCC changes.
SCC is the permission setting for workloads in K8S world.
Admin keep tracking the SCC may helps on security defences aspect of Kubernetes.

## Core concept of SCC

### What is SCC?

### How SCC attach to workloads?

1. SCC config YAML direct attach to users, ServiceAccount, groups
    1. SCC -> SA
2. SCC attach to roles, then ServiceAccount bind to clusterRole/Role by clusterEoleBinding/roleBinding
        2. SCC -> Role -> ClusterRoleBinding/RoleBinding -> SA


## Development 

Execute the script:
``` sh
cd /root/scc-monitoring/k8s-scc-tracking/script
source ./.env && ./main.sh "/root/scc-monitoring/backup-repo/scc-monitoring/"
```

Check the result:
``` sh
cd /root/scc-monitoring/backup-repo/scc-monitoring
ll

#get the list of priviledge scc's clusterrole
oc get clusterrole --all-namespaces -ojson | jq '.items | [.[] |select(.rules[]?.resourceNames[]?=="privileged")] | [.[] | {name: .metadata.name}]'


#E.G.
oc get clusterrolebinding -ojson | jq '.items | [.[]? | select((.roleRef.name=="vmware-vsphere-privileged-role") and (.roleRef.kind=="ClusterRole") )] | [ .[].subjects[]? | select(.kind=="ServiceAccount") ] | (map(keys) | add | unique) as $cols | map(. as $row | $cols | map($row[.])) as $rows |  $rows[] | @csv ' | sed 's/["\/]//g' | sed 's/,/ /g'

```
