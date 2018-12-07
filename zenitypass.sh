#!/usr/bin/env bash
#
# zenitypass.sh zenity assisted password management.

declare SDN="$(dirname ${BASH_SOURCE[0]})" SBN="$(basename ${BASH_SOURCE[0]})"

source "${SDN}/common.sh"

# Prerequisits
if [[ ! -x "$(which sqlite3 2> /dev/null)" ]]; then
  printf "Need sqlite3, install sqlite3 and try again.\n"
  exit 1
elif [[ ! -x "$(which zenity 2> /dev/null)" ]]; then
  printf "Need zenity, install zenity and try gain.\n"
  exit 1
elif [[ ! $(${DCM} "select * from ${ACT};" 2> /dev/null) ]]; then
  printf "Need a working db to function.\nRun 'sqlite3 my.db3 < ${ACT}.sql && ${SBN} my.db3'\nfrom this directory: $(pwd)\n"
  exit 1
fi

function create {

  zenity --height=$H --width=$W --forms --separator=',' \
    --add-entry="Domain" --add-entry="Email" \
    --add-entry="Uname" --add-entry="Password" \
    --add-entry="Comment" > ${TF}

  if (( $? == 0 )); then
    ${CCM} ".import ${TF} ${ACT}" 2> ${TF}
    if (( $? == 0 )); then
      zenity --height=$H --width=$W --text-info --title="New account" \
             --text=<<<$(${RCM} "select * from ${ACT} where rowid = $(( maxid + 1 ));")
    else
      zenity --height=$H --width=$W --text-info --title="Error" \
             --text=<<<$(cat ${TF})
    fi
  fi
}

function retrieve {

  DM=$(zenity --height=$H --width=$W --title="Enter domain" --text "Domain?" --entry-text="enter a domain" --entry)

  if (( ${?} == 0 )); then
    ${RCM} "select rowid as id,* from ${ACT} where dm like '%${DM}%';" > ${TF}
    zenity --height=$(( W + 200 )) --width=$(( W + 100 )) --text-info \
      --title="Results" --filename=${TF}
  fi
}

function update {
  local rec=$(sqlite3 -separator " " ${DB} "select 'FALSE' as state, rowid as id, dm as domain from ${ACT} order by rowid asc;")
  local zen=$(zenity --height=$H --width=$W --list --checklist --column "Update" --column "ID" --column "Domain" ${rec[@]})
  OFS=$IFS
  IFS=$'\|'
  for ID in $zen; do
    sqlite3 ${DB} "update ${ACT} set pw = '$(gpw)' where rowid = '${ID}';"
    zenity --height=$H --width=$W --text-info --title="New password" \
      --text=<<<$(sqlite3 -line ${DB} "select * from ${ACT} where rowid = '${ID}';")
  done
  IFS=$OFS
}

function delete {
  local REC=$(sqlite3 -separator " " ${DB} "select 'FALSE' as state, rowid as id, dm as domain, em as email from ${ACT} order by rowid asc;")
  local ZEN=$(zenity --height=$H --width=$W --list --checklist --column "Update" --column "ID" --column "Domain" --column "Email" ${REC[@]})

  local RES=""

  if [[ "x${ZEN}" != "x" ]]; then
    OFS=$IFS IFS=$'\|'
    for ID in ${ZEN}; do
      sqlite3 ${DB} "delete from ${ACT} where rowid = '${ID}';"
      RES+=$?
    done
    IFS=$OFS

    for ((x=0;x<${#RES};x++)); do
      if [[ "${RES:$x:1}" != "0" ]]; then
        zenity --error --title="Error." --text="Errors reported."
        return
      fi
    done
    zenity --info --title="Account(/s) deleted successfully." --text="No errors reported."
  fi
}

function import {

  local MAXID=$(maxid)

  local CSVF=$(zenity --title="Select a csv file to import:" --file-selection)

  if [[ -n ${CSVF} ]]; then
    ${CCM} ".import ${CSVF} ${ACT}" > ${TF}
    if (( $? == 0 )); then
      zenity --height=$H --width=$W --text-info --title="New account(/s)" \
             --text=<<<$(${RCM} "select * from ${ACT} where rowid > '${MAXID}';")
    else
      zenity --height=$H --width=$W --text-info --title="Error" \
             --text=<<<$(cat ${TF})
    fi
  fi
}

function usage {
  zenity --height=$H --width=$W --info \
    --title="Help screen" --text="${HM[@]}"
}

while true; do

  OFS=$IFS IFS=$'\|'

  RES=$(zenity --height=$H --width=$W --list --title="Select action" \
    --hide-header --column="Option" --column="Desc" --column="Description" ${MT})

  IFS=$OFS

  case "${RES}" in
    "${GOP[0]}") create ;;
    "${GOP[1]}") retrieve ;;
    "${GOP[2]}") update ;;
    "${GOP[3]}") delete ;;
    "${GOP[4]}") import ;;
    "${GOP[5]}") ${RCM} ;;
    "${GOP[6]}") usage ;;
    "${GOP[7]}") exit ;;
    *) exit;;
  esac
done
