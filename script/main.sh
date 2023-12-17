#!/bin/sh

DATA_PATH=$1

pjcode="$3"
envcode="$4"
fssize=$5

# function usage {
#   echo "Usage:
#   ${SCRIPTNAME} <namespace> <project_code> <dev|st|uat|prd> [size]
#   - e.g.
#   # create_fs_hostpath.sh paas CLOUD dev 5
#   "
# }

# if [ $# -ne 5 ]; then
#   usage
#   exit 1
# fi
function get_last_item {
  # $1 is the prefix of the file name
  # $2 is file type
  # echo "Get the lastest file which is starting with $1"
  ls -t $DATA_PATH/$1*.$2 | head -n 1
}

function turn_json_to_table {
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
  if [ "$(jq length <<< $1)" -eq 0 ] ; then
    exit 0
  fi

  echo "$1" | jq -r \
  '(map(keys) | add | unique) as $cols | map(. as $row | $cols | map($row[.]?)) as $rows |  $rows[]? | @csv'\
  | sed 's/["\/]//g'
}
export -f turn_json_to_table

# pj_fs_code=`echo "${pjcode}" | tr '[:upper:]' '[:lower:]' | sed 's/[_-]//g'`
# pesize=`vgdisplay -c ${VGNAME} | awk -F":" '{print $13}'`
# freegb=`echo ${pesize} ${freepe} | awk '{ printf "%0.f", $1*$2/1024/1024 }'`
# totalgb=`echo ${pesize} ${totalpe} | awk '{ printf "%0.f", $1*$2/1024/1024 }'`
# percentage=$(($freegb * 100 / $totalgb))
timestamp=`date  +'%Y%m%d-%H%M%S'`
SCC_LIST_FILE_NAME="SCC-list-$timestamp.json"
SCC_LIST_RESULT_FILE_NAME="SCC-list-compare-$timestamp.log"
SCC_SETTINGS_FILE_NAME="SCC-settings-details-$timestamp.json"
SCC_SETTINGS_RESULT_FILE_NAME="SCC-settings-details-compare-$timestamp.log"
# Get the last item of SCC List
LAST_SCC_LIST_FILE_NAME=$( get_last_item "SCC-list-" "json")
LAST_SCC_SETTINGS_FILE_NAME=$( get_last_item "SCC-settings-details-" "json")
#Debug
echo "SCC_LIST_FILE_NAME: $SCC_LIST_FILE_NAME"
echo "SCC_SETTINGS_FILE_NAME: $SCC_SETTINGS_FILE_NAME"
echo "LAST_SCC_LIST_FILE_NAME: $LAST_SCC_LIST_FILE_NAME"
echo "LAST_SCC_SETTINGS_FILE_NAME: $LAST_SCC_SETTINGS_FILE_NAME"

touch $DATA_PATH/$SCC_LIST_FILE_NAME
oc get scc > /dev/null

oc get scc -ojson | jq '.items | [.[]  | {name: .metadata.name,users: .users, groups: .groups}] | sort_by(.name) | { SCClist: .}'  \
    > $DATA_PATH/$SCC_LIST_FILE_NAME

touch $DATA_PATH/$SCC_LIST_RESULT_FILE_NAME

# Job : diff the list of SCC
if [ ${#LAST_SCC_LIST_FILE_NAME} -gt 0 ]; then
  #echo "length of LAST_SCC_LIST_FILE_NAME: ${#LAST_SCC_LIST_FILE_NAME}"
  echo "$LAST_SCC_LIST_FILE_NAME V.S. $DATA_PATH/$SCC_LIST_FILE_NAME"> $DATA_PATH/$SCC_LIST_RESULT_FILE_NAME
  diff $LAST_SCC_LIST_FILE_NAME $DATA_PATH/$SCC_LIST_FILE_NAME >> $DATA_PATH/$SCC_LIST_RESULT_FILE_NAME
  DIFF_RESULT=$?
  if [ "$DIFF_RESULT" -ne "0" ]; then
    echo "There are some different on SCC list DIFF_RESULT: $DIFF_RESULT"

  fi
fi

touch $DATA_PATH/$SCC_SETTINGS_FILE_NAME
oc get scc -ojson | jq '.items | del(.[].users, .[].groups, .[].metadata.annotations, .[].metadata.creationTimestamp, .[].metadata.generation, .[].metadata.resourceVersion, .[].metadata.uid, .[].kind) | sort_by(.metadata.name)' \
    > $DATA_PATH/$SCC_SETTINGS_FILE_NAME

touch $DATA_PATH/$SCC_SETTINGS_RESULT_FILE_NAME
# Job : diff the list of SCC's permissions details
if [ ${#LAST_SCC_SETTINGS_FILE_NAME} -gt 0 ]; then
  #echo "length of LAST_SCC_SETTINGS_FILE_NAME: ${#LAST_SCC_SETTINGS_FILE_NAME}"
  echo "$LAST_SCC_SETTINGS_FILE_NAME V.S. $DATA_PATH/$SCC_SETTINGS_FILE_NAME"> $DATA_PATH/$SCC_SETTINGS_RESULT_FILE_NAME
  diff $LAST_SCC_SETTINGS_FILE_NAME $DATA_PATH/$SCC_SETTINGS_FILE_NAME > /dev/null
  DIFF_RESULT=$?
  diff $LAST_SCC_SETTINGS_FILE_NAME $DATA_PATH/$SCC_SETTINGS_FILE_NAME >> $DATA_PATH/$SCC_SETTINGS_RESULT_FILE_NAME
  if [ "$DIFF_RESULT" -ne "0" ]; then
    echo "There are some different on SCC settings DIFF_RESULT: $DIFF_RESULT"

  fi
fi

# TODO: Keep track on a list of workloads that use privileged Security Context Constraints
 
function Get_SA_from_Clusterrolebinding {
  # $1 is the name of Clusterrolebinding
  if [ -z "$1" ]
  then
    exit 0
  fi
  oc get clusterrolebinding -ojson | jq --arg ROLE "$1" \
    '.items | [.[]? | select((.roleRef.name==$ROLE) and (.roleRef.kind=="ClusterRole") )]? | [ .[]?.subjects[]? | select(.kind=="ServiceAccount") ]? | (map(keys) | add | unique) as $cols | map(. as $row | $cols | map($row[.]?)) as $rows |  $rows[]? | @csv ' \
    | sed 's/["\/]//g' | sed 's/,/ /g'
}
export -f Get_SA_from_Clusterrolebinding

function Get_SA_from_Rolebinding {
  if [ -z "$1" ]
  then
    exit 0
  fi
  # $1 is the name of Rolebinding
  oc get rolebinding --all-namespaces -ojson | jq --arg ROLE "$1" \
    '.items | [.[]? | select((.roleRef.name==$ROLE) and (.roleRef.kind=="Role") )]? | [ .[].subjects[]? | select(.kind=="ServiceAccount") ]? | (map(keys) | add | unique) as $cols | map(. as $row | $cols | map($row[.]?)) as $rows |  $rows[]? | @csv ' \
    | sed 's/["\/]//g' | sed 's/,/ /g'
}
export -f Get_SA_from_Rolebinding

function Get_SA_Workloads {
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
  deployment_json=$(oc get deployment -n $NS -ojson | jq -c --arg SA "$SA" \
  '.items | [.[]? | select(.spec.template.spec.serviceAccountName==$SA)]? | [{ name: .[]?.metadata.name}]')
  deployment_table=$(turn_json_to_table $deployment_json)
  echo "$deployment_table" | sed '/^$/d' |  awk '{print "Deployment: " $1}' | sort

  # deploymentConfig workloads
  deploymentConfig_json=$(oc get deploymentConfig -n $NS -ojson | jq -c --arg SA "$SA" \
  '.items | [.[]? | select(.spec.template.spec.serviceAccountName==$SA)]? | [{ name: .[]?.metadata.name}]')
  deploymentConfig_table=$(turn_json_to_table $deploymentConfig_json)
  echo "$deploymentConfig_table" | sed '/^$/d' |  awk '{print "DeploymentConfig: " $1}' | sort

  # TODO: StatefulSets workloads

  # TODO: DaemonSets workloads

  # CronJobs workloads
  cronjobs_json=$(oc get CronJobs -n $NS -ojson | jq --arg SA "$SA" \
  '.items | [.[]? | select(.spec.jobTemplate.spec.template.spec.serviceAccountName==$SA)]? | [ { name: .[]?.metadata.name}]')
  cronjobs_table=$(turn_json_to_table $cronjobs_json)
  echo "$cronjobs_table" | sed '/^$/d' |  awk '{print "CronJob: " $1}' | sort
}
export -f Get_SA_Workloads


#echo $LIST_of_Privileged_SCC
for x in $LIST_of_Privileged_SCC ;
do
  echo "SCC: $x"
  # TODO: Get a list of service account from list of privileged SCC
  clusterrole_list=$(oc get clusterrole --all-namespaces -ojson | jq -r --arg SCC "$x" \
    '.items | [.[]? |select(.rules[]?.resourceNames[]?==$SCC)]? | .[]?.metadata.name' )
  #echo "clusterrole_list: $clusterrole_list"
  list_of_SA=$(echo "$clusterrole_list" | \
      xargs -I {} -n 1 bash -c 'Get_SA_from_Clusterrolebinding "$@"' _ {} )
  #echo "$list_of_SA"

  role_list=$(oc get role --all-namespaces -ojson | jq -r --arg SCC "$x" \
    '.items | [.[]? |select(.rules[]?.resourceNames[]?==$SCC)]? | .[]?.metadata.name' )
  #echo "role_list: $role_list"
  list_of_SA+="
"
  list_of_SA+=$(echo "$role_list" | \
      xargs -I {} -n 1 bash -c 'Get_SA_from_Rolebinding "$@"' _ {})
  Final_SA_List=$(echo "$list_of_SA" | sort | uniq | sed '/^$/d' | sed 's/^ServiceAccount //g')
  #echo "$Final_SA_List"
  
  # TODO: get the workload list
  echo "$Final_SA_List" | xargs -I {} -n 1 bash -c 'Get_SA_Workloads "$@"' _ {}
  echo ""
done

# if [ -z `lvdisplay -c "/dev/${VGNAME}/${pj_fs_code}_cldlog_${HOST#${HOST%??}}1" 2>/dev/null` ]; then
#   # Case: Create
#   aftergb=$(expr $freegb - $fssize)
#   afterpercentage=$(($aftergb * 100 / $totalgb))
#   echo "$freegb/$totalgb ($percentage%)    $aftergb/$totalgb ($afterpercentage%)"
# else
#   # Case: Expand
#   current_lv_size=$(lvdisplay --units g "/dev/${VGNAME}/${pj_fs_code}_cldlog_${HOST#${HOST%??}}1" | grep "LV Size" | awk '{printf "%d\n", $3}')
#   diff_lv_size=$(expr $fssize - $current_lv_size )
#   # echo "fssize : $fssize"
#   # echo "current_lv_size : $current_lv_size"
#   # echo "diff_lv_size : $diff_lv_size"
#   if [ $fssize -le $current_lv_size ]
#   then
#     # echo "diff_lv_size : $diff_lv_size"
#     diff_lv_size=0
#   fi
#   aftergb=$(expr $freegb - $diff_lv_size)
#   afterpercentage=$(($aftergb * 100 / $totalgb))
#   echo "$freegb/$totalgb ($percentage%)    $aftergb/$totalgb ($afterpercentage%)"
# fi