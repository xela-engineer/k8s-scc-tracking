# k8s-scc-tracking

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
