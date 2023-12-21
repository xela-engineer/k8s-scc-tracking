#!/bin/sh

DATA_PATH="$1"
export OCP_API_URL="$2"
export OCP_TOKEN="$3"

usage() {
  echo "Usage:
  ${SCRIPTNAME} <log and result path>
  - e.g.
  # source ./.env && ./main.sh "/root/scc-monitoring/backup-repo/scc-monitoring/" "ocp_url" "ocp_token"
  # source ./.env && ./k8s-scc "/root/scc-monitoring/backup-repo/scc-monitoring/" "ocp_url" "ocp_token"
  "
}

if [ $# -ne 3 ]; then
  usage
  exit 1
fi

get_last_item() {
  # $1 is the prefix of the file name
  # $2 is file type
  # echo "Get the lastest file which is starting with $1"
  ls -t "$DATA_PATH"/"$1"*."$2" | head -n 1
}

turn_json_to_table() {
  # $1 is the input variable JSON
  # The output of this function will return example like this:
  # Input : [ {"name": "pod1", "namespace": "ns1"}, {"name": "pod2", "namespace": "ns2"}]
  # Output : 
  # name namespace
  # pod1 ns1
  # pod2 ns2
  if [ -z "$1" ]
  then
    exit 0
  fi
  #echo "function input : $1"
  if [ "$(jq length <<< "$1")" -eq 0 ] ; then
    exit 0
  fi

  echo "$1" | jq -r \
  '(map(keys) | add | unique) as $cols | map(. as $row | $cols | map($row[.]?)) as $rows |  $rows[]? | @csv'\
  | sed 's/["\/]//g'
}
export -f turn_json_to_table

timestamp=$(date  +'%Y%m%d-%H%M%S')
SCC_LIST_FILE_NAME="SCC-list-$timestamp.json"
SCC_LIST_RESULT_FILE_NAME="SCC-list-compare-$timestamp.log"
SCC_SETTINGS_FILE_NAME="SCC-settings-details-$timestamp.json"
SCC_SETTINGS_RESULT_FILE_NAME="SCC-settings-details-compare-$timestamp.log"
SCC_WORKLOADS_FILE_NAME="SCC-Workloads-$timestamp.json"
SCC_WORKLOADS_RESULT_FILE_NAME="SCC-Workloads-compare-$timestamp.log"
# Get the last item of SCC List
LAST_SCC_LIST_FILE_NAME=$( get_last_item "SCC-list-" "json")
LAST_SCC_SETTINGS_FILE_NAME=$( get_last_item "SCC-settings-details-" "json")
LAST_SCC_WORKLOADS_FILE_NAME=$( get_last_item "SCC-Workloads-" "json")
#Debug
# echo "SCC_LIST_FILE_NAME: $SCC_LIST_FILE_NAME"
# echo "SCC_SETTINGS_FILE_NAME: $SCC_SETTINGS_FILE_NAME"
# echo "SCC_WORKLOADS_FILE_NAME: $SCC_WORKLOADS_FILE_NAME"
# echo "LAST_SCC_LIST_FILE_NAME: $LAST_SCC_LIST_FILE_NAME"
# echo "LAST_SCC_SETTINGS_FILE_NAME: $LAST_SCC_SETTINGS_FILE_NAME"
# echo "LAST_SCC_WORKLOADS_FILE_NAME: $LAST_SCC_WORKLOADS_FILE_NAME"

echo "[Start]"
touch "$DATA_PATH"/"$SCC_LIST_FILE_NAME"
oc get scc --server="$OCP_API_URL" --token="$OCP_TOKEN" --insecure-skip-tls-verify > /dev/null

oc get scc -ojson --server="$OCP_API_URL" --token="$OCP_TOKEN" --insecure-skip-tls-verify \
| jq '.items | [.[]  | {name: .metadata.name,users: .users, groups: .groups}] | sort_by(.name) | { SCClist: .}'\
> "$DATA_PATH"/"$SCC_LIST_FILE_NAME"

touch "$DATA_PATH"/"$SCC_LIST_RESULT_FILE_NAME"

# Job : diff the list of SCC
if [ ${#LAST_SCC_LIST_FILE_NAME} -gt 0 ]; then
  #echo "length of LAST_SCC_LIST_FILE_NAME: ${#LAST_SCC_LIST_FILE_NAME}"
  echo "$LAST_SCC_LIST_FILE_NAME V.S. $DATA_PATH/$SCC_LIST_FILE_NAME"> "$DATA_PATH"/"$SCC_LIST_RESULT_FILE_NAME"
  diff --context=10 "$LAST_SCC_LIST_FILE_NAME" "$DATA_PATH"/"$SCC_LIST_FILE_NAME" >> "$DATA_PATH"/"$SCC_LIST_RESULT_FILE_NAME"
  DIFF_RESULT=$?
  if [ "$DIFF_RESULT" -ne "0" ]; then
    echo "There are some different on SCC list. Please check $DATA_PATH/$SCC_LIST_RESULT_FILE_NAME"
    #cat $DATA_PATH/$SCC_LIST_RESULT_FILE_NAME | mail -s "[Alert] SCC list had changed in the $OCP_NAME" $t6_support_email
  fi
fi

touch "$DATA_PATH"/"$SCC_SETTINGS_FILE_NAME"
oc get scc -ojson --server="$OCP_API_URL" --token="$OCP_TOKEN" --insecure-skip-tls-verify \
| jq '.items | del(.[].users, .[].groups, .[].metadata.annotations, .[].metadata.creationTimestamp, .[].metadata.generation, .[].metadata.resourceVersion, .[].metadata.uid, .[].kind) | sort_by(.metadata.name)' \
    > "$DATA_PATH"/"$SCC_SETTINGS_FILE_NAME"

touch "$DATA_PATH"/"$SCC_SETTINGS_RESULT_FILE_NAME"
# Job : diff the list of SCC's permissions details
if [ ${#LAST_SCC_SETTINGS_FILE_NAME} -gt 0 ]; then
  #echo "length of LAST_SCC_SETTINGS_FILE_NAME: ${#LAST_SCC_SETTINGS_FILE_NAME}"
  echo "$LAST_SCC_SETTINGS_FILE_NAME V.S. $DATA_PATH/$SCC_SETTINGS_FILE_NAME"> "$DATA_PATH"/"$SCC_SETTINGS_RESULT_FILE_NAME"
  diff --context=10 "$LAST_SCC_SETTINGS_FILE_NAME" "$DATA_PATH"/"$SCC_SETTINGS_FILE_NAME" > /dev/null
  DIFF_RESULT=$?
  diff --context=10 "$LAST_SCC_SETTINGS_FILE_NAME" "$DATA_PATH"/"$SCC_SETTINGS_FILE_NAME" >> "$DATA_PATH"/"$SCC_SETTINGS_RESULT_FILE_NAME"
  if [ "$DIFF_RESULT" -ne "0" ]; then
    echo "There are some different on SCC settings. Please check $DATA_PATH/$SCC_SETTINGS_RESULT_FILE_NAME"
    #cat $DATA_PATH/$SCC_SETTINGS_RESULT_FILE_NAME | mail -s "[Alert] Some SCC settings had changed in the $OCP_NAME" $t6_support_email
  fi
fi

# Keep track on a list of workloads that use privileged Security Context Constraints
 
Get_SA_from_Clusterrolebinding() {
  # $1 is the name of Clusterrolebinding
  if [ -z "$1" ]
  then
    exit 0
  fi
  oc get clusterrolebinding -ojson --server="$OCP_API_URL" --token="$OCP_TOKEN" --insecure-skip-tls-verify \
  | jq --arg ROLE "$1" \
  '.items | [.[]? | select((.roleRef.name==$ROLE) and (.roleRef.kind=="ClusterRole") )]? | [ .[]?.subjects[]? | select(.kind=="ServiceAccount") ]? | (map(keys) | add | unique) as $cols | map(. as $row | $cols | map($row[.]?)) as $rows |  $rows[]? | @csv ' \
  | sed 's/["\/]//g' | sed 's/,/ /g'
}
export -f Get_SA_from_Clusterrolebinding

Get_SA_from_Rolebinding() {
  if [ -z "$1" ]
  then
    exit 0
  fi
  # $1 is the name of Rolebinding
  oc get rolebinding --all-namespaces -ojson --server="$OCP_API_URL" --token="$OCP_TOKEN" --insecure-skip-tls-verify \
  | jq --arg ROLE "$1" \
  '.items | [.[]? | select((.roleRef.name==$ROLE) and (.roleRef.kind=="Role") )]? | [ .[].subjects[]? | select(.kind=="ServiceAccount") ]? | (map(keys) | add | unique) as $cols | map(. as $row | $cols | map($row[.]?)) as $rows |  $rows[]? | @csv ' \
  | sed 's/["\/]//g' | sed 's/,/ /g'
}
export -f Get_SA_from_Rolebinding

Get_SA_Workloads() {
  # $1 is the name of Service  Account
  # this function helps to get a list of workloads of using a specific SA
  if [ -z "$1" ]
  then
    exit 0
  fi
  # Variable Service Account
  SA=$(echo "$1" | awk -F" " '{print $1}')
  # Variable Namespace
  NS=$(echo "$1" | awk -F" " '{print $2}')
  echo "SA: $SA, NS: $NS"
  # Deployment workloads
  deployment_json=$(oc get deployment -n "$NS" --server="$OCP_API_URL" --token="$OCP_TOKEN" --insecure-skip-tls-verify -ojson \
  | jq -c --arg SA "$SA" \
  '.items | [.[]? | select(.spec.template.spec.serviceAccountName==$SA)]? | [{ name: .[]?.metadata.name}]')
  deployment_table=$(turn_json_to_table "$deployment_json")
  echo "$deployment_table" | sed '/^$/d' |  awk '{print "Deployment: " $1}' | sort

  # deploymentConfig workloads
  deploymentConfig_json=$(oc get deploymentConfig -n "$NS" -ojson --server="$OCP_API_URL" --token="$OCP_TOKEN" --insecure-skip-tls-verify \
  | jq -c --arg SA "$SA" \
  '.items | [.[]? | select(.spec.template.spec.serviceAccountName==$SA)]? | [{ name: .[]?.metadata.name}]')
  deploymentConfig_table=$(turn_json_to_table "$deploymentConfig_json")
  echo "$deploymentConfig_table" | sed '/^$/d' |  awk '{print "DeploymentConfig: " $1}' | sort

  # StatefulSets workloads
  statefulSets_json=$(oc get statefulSets -n "$NS" -ojson --server="$OCP_API_URL" --token="$OCP_TOKEN" --insecure-skip-tls-verify \
  | jq -c --arg SA "$SA" \
  '.items | [.[]? | select(.spec.template.spec.serviceAccountName==$SA)]? | [{ name: .[]?.metadata.name}]')
  statefulSets_table=$(turn_json_to_table "$statefulSets_json")
  echo "$statefulSets_table" | sed '/^$/d' |  awk '{print "StatefulSet: " $1}' | sort

  # DaemonSets workloads
  daemonSets_json=$(oc get daemonSets -n "$NS" -ojson --server="$OCP_API_URL" --token="$OCP_TOKEN" --insecure-skip-tls-verify \
  | jq -c --arg SA "$SA" \
  '.items | [.[]? | select(.spec.template.spec.serviceAccountName==$SA)]? | [{ name: .[]?.metadata.name}]')
  daemonSets_table=$(turn_json_to_table "$daemonSets_json")
  echo "$daemonSets_table" | sed '/^$/d' |  awk '{print "DaemonSet: " $1}' | sort
  
  # CronJobs workloads
  cronjobs_json=$(oc get CronJobs -n "$NS" -ojson --server="$OCP_API_URL" --token="$OCP_TOKEN" --insecure-skip-tls-verify \
  | jq --arg SA "$SA" \
  '.items | [.[]? | select(.spec.jobTemplate.spec.template.spec.serviceAccountName==$SA)]? | [ { name: .[]?.metadata.name}]')
  cronjobs_table=$(turn_json_to_table "$cronjobs_json")
  echo "$cronjobs_table" | sed '/^$/d' |  awk '{print "CronJob: " $1}' | sort
}
export -f Get_SA_Workloads


touch "$DATA_PATH"/"$SCC_WORKLOADS_FILE_NAME"
#echo "LIST_of_Privileged_SCC: $LIST_of_Privileged_SCC" 
echo "Start scanning workloads that are in the list of LIST_of_Privileged_SCC..."
for x in $(echo "$LIST_of_Privileged_SCC" | sed 's/ /\n/g' | sort | uniq | tr '\n' ' ') ;
do
  echo -n "."
  echo "SCC: $x" >> "$DATA_PATH"/"$SCC_WORKLOADS_FILE_NAME"
  # Get a list of service account from list of privileged SCC
  clusterrole_list=$(oc get clusterrole --all-namespaces -ojson --server="$OCP_API_URL" --token="$OCP_TOKEN" --insecure-skip-tls-verify \
  | jq -r --arg SCC "$x" \
  '.items | [.[]? |select(.rules[]?.resourceNames[]?==$SCC)]? | .[]?.metadata.name' )
  #echo "clusterrole_list: $clusterrole_list"
  list_of_SA=$(echo "$clusterrole_list" \
  | xargs -I {} -n 1 bash -c 'Get_SA_from_Clusterrolebinding "$@"' _ {} )
  #echo "list_of_SA1:$list_of_SA"

  role_list=$(oc get role --all-namespaces -ojson --server="$OCP_API_URL" --token="$OCP_TOKEN" --insecure-skip-tls-verify \
  | jq -r --arg SCC "$x" \
  '.items | [.[]? |select(.rules[]?.resourceNames[]?==$SCC)]? | .[]?.metadata.name' )
  #echo "role_list: $role_list"
  list_of_SA+="
"
  list_of_SA+=$(echo "$role_list" | \
      xargs -I {} -n 1 bash -c 'Get_SA_from_Rolebinding "$@"' _ {})
  list_of_SA+="
"
  list_of_SA+=$(cat "$DATA_PATH"/"$SCC_LIST_FILE_NAME" | jq -r --arg SCC "$x" \
  ' .[] | .[] | select(.name==$SCC) | .users[]' | grep serviceaccount \
  | awk -F":" '{print $4" "$3}')

  Final_SA_List=$(echo "$list_of_SA" | sed '/^$/d' | sed 's/^ServiceAccount //g'| sort | uniq)
  #echo "$Final_SA_List"
  
  # Get the workload list
  echo "$Final_SA_List" | xargs -I {} -n 1 bash -c 'Get_SA_Workloads "$@"' _ {} \
    >> "$DATA_PATH"/"$SCC_WORKLOADS_FILE_NAME"
  echo "" >> "$DATA_PATH"/"$SCC_WORKLOADS_FILE_NAME"
done
echo "Completed scanning on workloads"
touch "$DATA_PATH"/"$SCC_WORKLOADS_RESULT_FILE_NAME"
# Job : diff the list of SCC's workloads
if [ ${#LAST_SCC_WORKLOADS_FILE_NAME} -gt 0 ]; then
  #echo "length of LAST_SCC_WORKLOADS_FILE_NAME: ${#LAST_SCC_WORKLOADS_FILE_NAME}"
  
  diff --context=10 "$LAST_SCC_WORKLOADS_FILE_NAME" "$DATA_PATH"/"$SCC_WORKLOADS_FILE_NAME" >> "$DATA_PATH/$SCC_WORKLOADS_RESULT_FILE_NAME"
  DIFF_RESULT=$?
  if [ "$DIFF_RESULT" -ne "0" ]; then
    echo "$LAST_SCC_WORKLOADS_FILE_NAME V.S. $DATA_PATH/$SCC_WORKLOADS_FILE_NAME"> "$DATA_PATH"/"$SCC_WORKLOADS_RESULT_FILE_NAME"
    echo "There are some different on SCC's workloads. Please check $DATA_PATH/$SCC_WORKLOADS_RESULT_FILE_NAME"
    #cat $DATA_PATH/$SCC_WORKLOADS_RESULT_FILE_NAME | mail -s "[Alert] The list of workloads using privileged SCC had changed in the $OCP_NAME" $t6_support_email
  fi
fi

echo "[Complete]"