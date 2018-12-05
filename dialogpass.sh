#!/usr/bin/env bash
#
# dialogpass.sh dialog assisted terminal password management.

declare SDN="$(dirname ${BASH_SOURCE[0]})" SBN="$(basename ${BASH_SOURCE[0]})"

source "${SDN}/common.sh"

# Prerequisits
if [[ ! -x "$(which sqlite3 2> /dev/null)" ]]; then
  printf "Need sqlite3, install sqlite3 and try again.\n"
  exit 1
elif [[ ! -x "$(which ${DIALOG} 2> /dev/null)" ]]; then
  printf "Need ${DIALOG}, install ${DIALOG} and try gain.\n"
  exit 1
elif [[ ! $(${DCM} "select * from ${ACT};" 2> /dev/null) ]]; then
  printf "Need a working db to function.\nRun 'sqlite3 my.db3 < ${ACT}.sql && ${SBN} my.db3'\nfrom this directory: $(pwd)\n"
  exit 1
fi

function create {

  local MAXID=$(maxid)

  ${DIALOG} --backtitle ${SBN} --clear --title dialog --inputbox "Enter domain" $L $C 2> ${TF}
  (( $? == $DIALOG_OK )) && local DM=$(cat ${TF}) || return
  ${DIALOG} --backtitle ${SBN} --clear --title dialog --inputbox "Enter email" $L $C  2> ${TF}
  (( $? == $DIALOG_OK )) && local EM=$(cat ${TF}) || return
  ${DIALOG} --backtitle ${SBN} --clear --title dialog --inputbox "Enter username" $L $C 2> ${TF}
  (( $? == $DIALOG_OK )) && local UN=$(cat ${TF}) || return
  ${DIALOG} --backtitle ${SBN} --clear --title dialog --inputbox "Enter password" $L $C 2> ${TF}
  (( $? == $DIALOG_OK )) && local PW=$(cat ${TF}) || return
  ${DIALOG} --backtitle ${SBN} --clear --title dialog --inputbox "Enter comments" $L $C 2> ${TF}
  (( $? == $DIALOG_OK )) && local CM=$(cat ${TF}) || return

  ${DCM} "insert into ${ACT} (dm, em, un, pw, cm) values('${DM//:/\:}', '${EM}', '${UN}', '${PW}', '${CM}');"
  ${RCM} "select rowid as id,* from ${ACT} where id = $(( ++MAXID ));"|"${PAGER}"

}

function retrieve {
  ${DIALOG} --backtitle ${SBN} --clear --title "domain" --inputbox "search by domain" $L $C 2> ${TF}
  (( ${?} == ${DIALOG_OK} )) && ${RCM} "select rowid as id,* from ${ACT} where dm like '%$(cat ${TF})%';"|"${PAGER}"
}

function update {
  for R in $(rids); do
    local DM=$(${DCM} "select dm from ${ACT} where rowid = '${R}';")
    local EM=$(${DCM} "select em from ${ACT} where rowid = '${R}';")
    local RL+="${R} ${DM:-NULL}:${EM:-NULL} off "
  done

  ${DIALOG} --backtitle ${SBN} --clear --title "select accout" \
            --radiolist "Select accout for password update:" $L $C 5 ${RL[@]} 2> ${TF}

  if (( ${?} == ${DIALOG_OK} )); then
    local ID="$(cat ${TF})"
    ${DCM} "update ${ACT} set pw = '$(gpw)' where rowid = '${ID}';"
    ${RCM} "select rowid as id,* from ${ACT} where id = '${ID}';"|"${PAGER}"
  fi
}

function delete {
  for R in $(rids); do
    local DM=$(${DCM} "select dm from ${ACT} where rowid = '${R}';")
    local EM=$(${DCM} "select em from ${ACT} where rowid = '${R}';")
    local RL+="${R} ${DM:-NULL}:${EM:-NULL} off "
  done

  ${DIALOG} --backtitle ${SBN} --clear --title "delete account" \
            --radiolist "Select accout to delete:" $L $C 5 ${RL[@]} 2> ${TF}

  if (( ${?} == ${DIALOG_OK} )); then
    local ID="$(cat ${TF})"
    ${DCM} "delete from ${ACT} where rowid = '${ID}';"
    ${DIALOG} --backtitle ${SBN} --clear --title dialog --msgbox "Account ID #$ID deleted." $L $C
  fi
}

function import {

  local MAXID=$(maxid)

  ${DIALOG} --backtitle ${SBN} --clear --title "select file" --stdout --fselect "${SDN}/" $L $C 2> ${TF}
  (( ${?} != ${DIALOG_OK} )) && return

  local CSVF=$(cat ${TF})

  ${CCM} ".import ${CSVF} ${ACT}" 2> ${TF}

  if (( ${?} == 0 )); then
    ${RCM} "select rowid as id,* from ${ACT} where rowid > ${MAXID};"|"${PAGER}"
  else
    ${DIALOG} --backtitle ${SBN} --clear --title Error --msgbox "Error reported: $(cat ${TF})" $L $C
  fi
}

function usage {
  ${DIALOG} --backtitle ${SBN} --clear --title Help --msgbox "${HM[@]}" $L $C
}

while [[ true ]]; do

  OFS=$IFS IFS=$'\|'

  ${DIALOG} --backtitle ${SBN} --clear --title dialog \
            --help-button --item-help --cancel-label "Quit" \
            --menu "Menu:" $L $C $((${#GOP[@]})) ${MT} 2> ${TF}

  ERRLVL=$?

  IFS=$OFS

  case ${ERRLVL} in
    ${DIALOG_OK})
      case "$(cat ${TF})" in
        "${GOP[0]}") create ;;
        "${GOP[1]}") retrieve ;;
        "${GOP[2]}") update ;;
        "${GOP[3]}") delete ;;
        "${GOP[4]}") import ;;
        "${GOP[5]}") ${RCM} ;;
        "${GOP[6]}") usage ;;
        "${GOP[7]}") exit ;;
      esac ;;
    ${DIALOG_CANCEL}) exit ;;
    ${DIALOG_HELP}) usage;;
    ${DIALOG_ESC}) exit ;;
  esac
done
