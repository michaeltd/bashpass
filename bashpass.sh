#!/usr/bin/env bash
#
# bashpass.sh terminal password management.

declare SDN="$(dirname ${BASH_SOURCE[0]})" SBN="$(basename ${BASH_SOURCE[0]})"

source "${SDN}/common.sh"

# Prerequisits
if [[ ! -x "$(which sqlite3 2> /dev/null)" ]]; then
  printf "Need sqlite3, install sqlite3 and try again.\n"
  exit 1
#
#
#
elif [[ ! $(${DCM} "select * from ${ACT};" 2> /dev/null) ]]; then
  printf "Need a working db to function.\nRun 'sqlite3 my.db3 < ${ACT}.sql && ${SBN} my.db3'\nfrom this directory: $(pwd)\n"
  exit 1
fi

function create {
  local DM EM UN PW CM RDM REM RUN RPW RCM
  while [[ "${RDM}" != "y" || "${REM}" != "y" || "${RUN}" != "y" || "${RPW}" != "y" || "${RCM}" != "y" ]]; do
    while [[ -z "${DM}" || -z "${EM}" || -z "${UN}" || -z "${PW}" || -z "${CM}" ]]; do
      if [[ -z "${DM}" || "${RDM}" != "y" ]]; then
        read -p "Enter Domain: " DM
        read -p "Is this Domain ok with you? ${DM} [y/n]: " RDM
      elif [[ -z "${EM}" || "${REM}" != "y" ]]; then
        read -p "Enter Email: " EM
        read -p "Is this Email ok with you? ${EM} [y/n]: " REM
      elif [[ -z "${UN}" || "${RUN}" != "y" ]]; then
        read -p "Enter Username: " UN
        read -p "Is this Username ok with you? ${UN} [y/n]: " RUN
      elif [[ -z "${PW}" || "${RPW}" != "y" ]]; then
        read -p "Enter Password: " PW
        read -p "Is this Password ok with you? ${PW} [y/n]: " RPW
      elif [[ -z "${CM}" || "${RCM}" != "y" ]]; then
        read -p "Enter Comment: " CM
        read -p "Is this Comment ok with you? ${CM} [y/n]: " RCM
      fi
    done
  done
  ${DCM} "insert into ${ACT} values('${DM//:/\:}', '${EM}', '${UN}', '${PW}', '${CM}');"
  ${RCM} "select rowid as id,* from ${ACT} where id = (select max(rowid) from ${ACT});"|"${PAGER}"
}

function retrieve {
  local DM
  read -p "Enter domain to look for (empty for All): " DM
  ${RCM} "select rowid as id,* from ${ACT} where dm like '%${DM}%';"|"${PAGER}"
}

function update {
  local ID
  read -p "Select an id to update: " ID
  ${DCM} "update ${ACT} set pw = '$(gpw)' where rowid = '${ID}';"
  ${RCM} "select rowid as id,* from ${ACT} where id = '${ID}';"|"${PAGER}"
}

function delete {
  local ID
  read -p "Select an id to delete: " ID
  ${DCM} "delete from ${ACT} where rowid = '${ID}';"
}

function import {
  local CSVF
  read -p "Enter a csv file: " CSVF;
  ${CCM} ".import ${CSVF} ${ACT}"
  ${RCM} "select rowid as id,* from ${ACT};"|"${PAGER}"
}

function usage {
  printf "${THM[@]}\n"
}

while [[ true ]]; do
  printf "${PR}"
  read UI
  case "${UI}" in
    0) create ;;
    1) retrieve ;;
    2) update ;;
    3) delete ;;
    4) import ;;
    5) ${RCM} ;;
    6) usage ;;
    7) break ;;
    *) printf "${red}Invalid responce: %s${reset}. Choose again from 0 to %d\n" "${UI}" "$((${#TOP[@]}-1))" ;;
  esac
done
