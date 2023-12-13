#!/bin/sh

DATA_PATH=$1
nscode=`echo "$2" | sed 's/-//g'`
pjcode="$3"
envcode="$4"
fssize=$5

# function usage {
#   echo "Usage:
#   ${SCRIPTNAME} <namespace> <project_code> <dev|st|uat|pot|sit|lpt|ppm|aat|ppt|prd> [size]
#   - e.g.
#   # create_fs_hostpath.sh paas-corp-poc-dev2 CLOUD dev 5
#   "
# }

# if [ $# -ne 5 ]; then
#   usage
#   exit 1
# fi

# pj_fs_code=`echo "${pjcode}" | tr '[:upper:]' '[:lower:]' | sed 's/[_-]//g'`
# pesize=`vgdisplay -c ${VGNAME} | awk -F":" '{print $13}'`
# totalpe=`vgdisplay -c ${VGNAME} | awk -F":" '{print $14}'`
# freepe=`vgdisplay -c ${VGNAME} | awk -F":" '{print $16}'`
# freegb=`echo ${pesize} ${freepe} | awk '{ printf "%0.f", $1*$2/1024/1024 }'`
# totalgb=`echo ${pesize} ${totalpe} | awk '{ printf "%0.f", $1*$2/1024/1024 }'`
# percentage=$(($freegb * 100 / $totalgb))
SCC_LIST_FILE_NAME="SCC-list-`date  +'%Y%m%d%H%M%S'`.json"
SCC_SETTINGS_FILE_NAME="SCC-settings-details-`date  +'%Y%m%d%H%M%S'`.json"
#Debug
echo "SCC_LIST_FILE_NAME: $SCC_LIST_FILE_NAME"
echo "SCC_SETTINGS_FILE_NAME: $SCC_SETTINGS_FILE_NAME"
# echo "pesize: $pesize"
# echo "totalpe: $totalpe"
# echo "freepe: $freepe"
# echo "freegb: $freegb"
# echo "totalgb: $totalgb"
# echo "percentage: $percentage"


touch $DATA_PATH/$SCC_LIST_FILE_NAME
oc get scc > /dev/null
echo "$?"

oc get scc -ojson | jq '.items | [.[]  | {name: .metadata.name,users: .users, groups: .groups}] | sort_by(.name) | { SCClist: .}'  \
    > $DATA_PATH/$SCC_LIST_FILE_NAME

touch $DATA_PATH/$SCC_SETTINGS_FILE_NAME
oc get scc -ojson | jq '.items | del(.[].users, .[].groups, .[].metadata.annotations, .[].metadata.creationTimestamp, .[].metadata.generation, .[].metadata.resourceVersion, .[].metadata.uid, .[].kind) | sort_by(.metadata.name)' \
    > $DATA_PATH/$SCC_SETTINGS_FILE_NAME

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