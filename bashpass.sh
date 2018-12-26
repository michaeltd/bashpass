#!/usr/bin/env bash
#
# bashpass.sh Xdialog/dialog/terminal assisted password management.

declare SDN="$(cd $(dirname ${BASH_SOURCE[0]})&& pwd)" SBN="$(basename ${BASH_SOURCE[0]})" 
declare DB="${1:-git.db3}" ACT="ac"
declare -a DCM="sqlite3 ${DB}" RCM="sqlite3 -line ${DB}" CCM="sqlite3 -csv ${DB}"

cd ${SDN}

# Prerequisits
if [[ ! -x "$(which sqlite3 2> /dev/null)" ]]; then
  printf "Need sqlite3, install sqlite3 and try again.\n"
  exit 1
elif [[ ! $(${DCM} "select * from ${ACT};" 2> /dev/null) ]]; then
  printf "Need a working db to function.\nRun 'sqlite3 my.db3 < ${ACT}.sql && ${SBN} my.db3'\nfrom this directory: $(pwd)\n"
  exit 1
elif [[ -x "$(which Xdialog 2> /dev/null)" && -n "${DISPLAY}" ]]; then # Check for X, Xdialog
  declare DIALOG=$(which Xdialog) L="30" C="60"
elif [[ -x "$(which dialog 2> /dev/null)" ]]; then # Check for dialog
  declare DIALOG=$(which dialog) L="0" C="0"
fi

export XDIALOG_HIGH_DIALOG_COMPAT=1 XDIALOG_FORCE_AUTOSIZE=1 XDIALOG_INFOBOX_TIMEOUT=5000 XDIALOG_NO_GMSGS=1

declare DIALOG_OK=0 DIALOG_CANCEL=1 DIALOG_HELP=2 DIALOG_EXTRA=3 DIALOG_ITEM_HELP=4 DIALOG_ESC=255
declare SIG_NONE=0 SIG_HUP=1 SIG_INT=2 SIG_QUIT=3 SIG_KILL=9 SIG_TERM=15

declare TF="${SDN}/.deleteme.${RANDOM}.${$}"
trap "rm -f ${TF}" $SIG_NONE $SIG_HUP $SIG_INT $SIG_QUIT $SIG_TERM

declare -a TOP=( "${red}Create  ${reset}" "${green}Retrieve${reset}" "${blue}Update  ${reset}" "${yellow}Delete  ${reset}" "${magenta}CSV     ${reset}" "${cyan}SQLite3 ${reset}" "${black}Help    ${reset}" "${grey}Quit    ${reset}" )
declare -a GOP=( "Create" "Retrieve" "Update" "Delete" "CSV" "SQLite3" "Help" "Quit" )
declare -a SDESC=( "New entry" "Find account" "Regen password" "Remove entry" "Import a file" "sqlite3 session" "Help screen" "Exit" )
declare -a DESC=( "gathter details to generate a new password." "search records by domain." "regenerate an existing password." "remove an account." "prompt for csv file to import(eg:test.csv)." "start an sqlite session against ${DB}." "Show this message" "Quit this application." )

# Various Arrays
declare -a PR=() # PRompt
declare -a THM="\nUsage: ${SBN} [dbfile.db3]\n\n" # Terminal Help Message
declare -a HM="\nUsage: ${SBN} [dbfile.db3]\n\n" # Help Message
declare -a MT=() # Menu Text
for ((x=0;x<${#TOP[@]};x++)); do
  PR+="${x}:${TOP[$x]}"; (( ( x + 1 ) % 4 == 0 )) && PR+="\n" || PR+="\t"
  THM+="Use ${bold}${x}${reset}, for ${TOP[$x]}, which will ${bold}${DESC[$x]}${reset}\n"
  HM+="Use ${GOP[$x]}, to ${DESC[$x]}\n"
  MT+="${GOP[$x]}|${SDESC[$x]}|${DESC[$x]}|"
done
PR+="${bold}Choose[0-$((${#TOP[@]}-1))]:${reset}"
THM+="\naccounts table format is as follows:\n$(${DCM} .schema)\n"
HM+="\naccounts table format is as follows:\n$(${DCM} .schema)\n"

function gpw {  # single/double quotes for strings, vertical bar for sqlite output field seperator
  echo $(tr -dc [:graph:] < /dev/urandom|tr -d [=\|=][=\"=][=\'=]|head -c "${1:-64}")
}

function rids {
  echo $(${DCM} "select rowid from ${ACT} order by rowid asc;")
}

function maxid {
  echo $(${DCM} "select max(rowid) from ${ACT};")
}

function rcount {
  echo $(${DCM} "select count(rowid) from ${ACT};")
}

function brl {
  for R in $(rids); do
    local DM=$(${DCM} "select dm from ${ACT} where rowid = '${R}';"|sed 's/ /-/g')
    local EM=$(${DCM} "select em from ${ACT} where rowid = '${R}';"|sed 's/ /-/g')
    local RL+="${R} ${DM:-null}:${EM:-null} off "
  done
  echo ${RL[@]}
}

function create {
  local MAXID=$(maxid) DM EM UN PW CM
  if [[ -n "${DIALOG}" ]]; then
    ${DIALOG} --backtitle ${SBN} --title dialog --inputbox "Enter domain:" $L $C 2> ${TF}
    (( $? == $DIALOG_OK )) && local DM=$(cat ${TF}) || return
    ${DIALOG} --backtitle ${SBN} --title dialog --inputbox "Enter email:" $L $C  2> ${TF}
    (( $? == $DIALOG_OK )) && local EM=$(cat ${TF}) || return
    ${DIALOG} --backtitle ${SBN} --title dialog --inputbox "Enter username:" $L $C 2> ${TF}
    (( $? == $DIALOG_OK )) && local UN=$(cat ${TF}) || return
    ${DIALOG} --backtitle ${SBN} --title dialog --passwordbox "Enter password:" $L $C 2> ${TF}
    (( $? == $DIALOG_OK )) && local PW=$(cat ${TF}) || return
    ${DIALOG} --backtitle ${SBN} --title dialog --inputbox "Enter comments:" $L $C 2> ${TF}
    (( $? == $DIALOG_OK )) && local CM=$(cat ${TF}) || return
  else
    while [[ -z "${DM}" || -z "${EM}" || -z "${UN}" || -z "${PW}" || -z "${CM}" ]]; do
      if [[ -z "${DM}" ]]; then
        read -p "Enter Domain: " DM
      elif [[ -z "${EM}" ]]; then
        read -p "Enter Email: " EM
      elif [[ -z "${UN}" ]]; then
        read -p "Enter Username: " UN
      elif [[ -z "${PW}" ]]; then
        read -p "Enter Password: " PW
      elif [[ -z "${CM}" ]]; then
        read -p "Enter Comment: " CM
      fi
    done
  fi

  ${DCM} "insert into ${ACT} values('${DM//:/\:}', '${EM}', '${UN}', '${PW}', '${CM}');"

  ${RCM} "select rowid as id,* from ${ACT} where id = $(( ++MAXID ));" > ${TF}

  if [[ "${DIALOG}" == "$(which Xdialog)" ]]; then
    ${DIALOG} --backtitle ${SBN} --title "results" --editbox "${TF}" $L $C 2>/dev/null
  else
    cat ${TF}|${PAGER}
  fi

}

function retrieve {
  local DM
  if [[ -n "${DIALOG}" ]]; then
    ${DIALOG} --backtitle ${SBN} --title "domain" --inputbox "Enter domain to look for (empty for All): " $L $C 2> ${TF}
    (( ${?} != ${DIALOG_OK} )) && return
  else
    read -p "Enter domain to look for (empty for All): " DM
    echo "${DM}" > ${TF}
  fi

  DM=$(cat ${TF})

  ${RCM} "select rowid as id,* from ${ACT} where dm like '%${DM}%';" > ${TF}

  if [[ "${DIALOG}" == "$(which Xdialog)" ]]; then
    ${DIALOG} --backtitle ${SBN} --title "results" --editbox "${TF}" $L $C 2>/dev/null
  else
    cat ${TF}|${PAGER}
  fi
}

function update {
  local ID
  if [[ -n "${DIALOG}" ]]; then
    ${DIALOG} --backtitle ${SBN} --title "update accout:" --radiolist "Select an id to update: " $L $C 5 $(brl) 2> ${TF}
    local ERRLVL=${?} ID="$(cat ${TF})"
    if (( ${ERRLVL} != ${DIALOG_OK} )) || [[ -z ${ID} ]]; then
      return
    fi
  else 
    read -p "Select an id to update (empty to cancel): " ID
    echo "${ID}" > ${TF}
  fi

  ${DCM} "update ${ACT} set pw = '$(gpw)' where rowid = '$(cat ${TF})';"

  ID=$(cat ${TF})

  ${RCM} "select rowid as id,* from ${ACT} where id = '${ID}';" > ${TF}

  if [[ "${DIALOG}" == "$(which Xdialog)" ]]; then
    ${DIALOG} --backtitle ${SBN} --title "results" --editbox "${TF}" $L $C 2>/dev/null
  else
    cat ${TF}|${PAGER}
  fi

}

function delete {
  local ID
  if [[ -n "${DIALOG}" ]]; then
    ${DIALOG} --backtitle ${SBN} --title "delete account:" --radiolist "Select an id to delete: " $L $C 5 $(brl) 2> ${TF}
    local ERRLVL=${?} ID="$(cat ${TF})"
    if (( ${ERRLVL} != ${DIALOG_OK} )) || [[ -z ${ID} ]]; then
      return
    fi
  else
    read -p "Select an id to delete (empty to cancel): " ID
    echo "${ID}" > ${TF}
  fi
  ${DCM} "delete from ${ACT} where rowid = '$(cat ${TF})';"
  [[ -n "${DIALOG}" ]] && ${DIALOG} --backtitle ${SBN} --title dialog --msgbox "Account ID #$ID deleted." $L $C || echo "Account ID #$ID deleted."
}

function import {
  local MAXID=$(maxid) CSVF
  if [[ -n "${DIALOG}" ]]; then
    ${DIALOG} --backtitle ${SBN} --title "Enter a csv file:" --fselect "${SDN}/" $L $C 2> ${TF}
    (( ${?} != ${DIALOG_OK} )) && return
    CSVF=$(cat ${TF})
  else 
    read -p "Enter a csv file: " CSVF;
    echo "${CSVF}" > ${TF}
  fi
  ${CCM} ".import ${CSVF} ${ACT}" 2> ${TF}
  if (( ${?} != 0 )); then
    if [[ -n "${DIALOG}" ]]; then 
      ${DIALOG} --backtitle ${SBN} --title Error --msgbox "Error reported: $(cat ${TF})" $L $C
    fi
    echo "Error: $(cat ${TF})"
    return
  fi

  ${RCM} "select rowid as id,* from ${ACT} where rowid > ${MAXID};" > ${TF}

  if [[ "${DIALOG}" == "$(which Xdialog)" ]]; then
    ${DIALOG} --backtitle ${SBN} --title "results" --editbox "${TF}" $L $C 2>/dev/null
  else
    cat ${TF}|${PAGER}
  fi

}

function usage {
  [[ -n "${DIALOG}" ]] && ${DIALOG} $([[ ${DIALOG} =~ "Xdialog" ]]&& echo "--fill") --backtitle ${SBN} --title Help --msgbox "${HM[@]}" $L $C || printf "${THM[@]}\n"
}

for ((;;)) {
  if [[ -n "${DIALOG}" ]]; then # Xdialog, dialog menu
    OFS=$IFS IFS=$'\|'
    ${DIALOG} --backtitle ${SBN} --title dialog --help-button --item-help --cancel-label "Quit" --menu "Menu:" $L $C $((${#GOP[@]})) ${MT} 2> ${TF}
    ERRLVL=$?
    IFS=$OFS
  else # Just terminal menu.
    printf "${PR}"
    read UI
    ERRLVL=$?
    echo ${UI} > ${TF}
  fi

  case ${ERRLVL} in
    ${DIALOG_OK})
      case "$(cat ${TF})" in
        "${GOP[0]}"|"0") create ;;
        "${GOP[1]}"|"1") retrieve ;;
        "${GOP[2]}"|"2") update ;;
        "${GOP[3]}"|"3") delete ;;
        "${GOP[4]}"|"4") import ;;
        "${GOP[5]}"|"5") ${RCM} ;;
        "${GOP[6]}"|"6") usage ;;
        "${GOP[7]}"|"7") exit ;;
        *) printf "${red}Invalid responce: %s${reset}. Choose again from 0 to %d\n" "${UI}" "$((${#TOP[@]}-1))" ;;
      esac ;;
    ${DIALOG_CANCEL}) exit ;;
    ${DIALOG_HELP}) usage ;;
    ${DIALOG_ESC}) exit ;;
  esac
}
