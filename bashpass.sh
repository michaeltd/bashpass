#!/usr/bin/env bash
# bashpass.sh terminal password management.

declare db="${1:-git.db3}"
declare dm em un cm pr hm act="ac"
declare -a op=( "${grey}Quit    ${reset}" "${red}Create  ${reset}" "${green}Retrieve${reset}" "${blue}Update  ${reset}" "${yellow}Delete  ${reset}" "${magenta}CSV     ${reset}" "${cyan}SQLite3 ${reset}" "${black}Help    ${reset}"
declare -a desc=( "exit this menu." "gathter details to generate a new password." "search records by domain." "regenerate an existing password." "remove an account." "prompt for csv file to import(eg:test.csv)." "start an sqlite session against your db." "print this message." )
declare -a cmd="sqlite3 -line ${db}"

if [[ (! -x "$(which sqlite3 2> /dev/null)") || (! $(${cmd} "select * from ${act};" 2> /dev/null)) ]]; then
  printf "Need sqlite3 and a working db to function.\nIf sqlite3 is in your path,\nRun 'sqlite3 my.db3 < ac.sql && bashpass.sh my.db3'\nfrom this directory: $(pwd)\n"
  exit 1
fi

hm="\nUsage: $(basename ${BASH_SOURCE[0]}) [dbfile.db3]\n\n" # Build some prompts and help messages.
for ((x=0;x<${#op[@]};x++)); do
  pr+="${x}:${op[$x]}"; (((x+1)%4==0)) && pr+="\n" || pr+="\t"
  hm+="Use ${bold}${x}${reset}, for ${op[$x]}, which will ${bold}${desc[$x]}${reset}\n"
done
pr+="${bold}Choose[0-$((${#op[@]}-1))]:${reset}"
hm+="\naccounts table format is as follows:\n$(${cmd} .schema)\n"

function gpw {
  echo $(tr -dc '[:alnum:]~!@#$%^&*()_=+,<.>/?;:[{]}\|-' < /dev/urandom|head -c "${1:-64}")
}

function create {
  while [[ -z "${dm}" || -z "${em}" || -z "${un}" || -z "${cm}" ]]; do
    if [[ -z "${dm}" ]]; then
      read -p "Enter Domain: " dm
    elif [[ -z "${em}" ]]; then
      read -p "Enter Email: " em
    elif [[ -z "${un}" ]]; then
      read -p "Enter Username: " un
    elif [[ -z "${cm}" ]]; then
      read -p "Enter Comment: " cm
    fi
  done
  ${cmd} "insert into ${act} values('${dm//:/\:}', '${em}', '${un}', '$(gpw)', '${cm}');"
  ${cmd} "select rowid as id,* from ${act} where dm like '${dm}';"|"${PAGER}"
  unset dm em un cm
}

function retrieve {
  read -p "Enter domain to look for (empty for All): " dm
  ${cmd} "select rowid as id,* from ${act} where dm like '%${dm}%';"|"${PAGER}"
  unset dm
}

function update {
  read -p "Select an id to update: " id
  ${cmd} "update ${act} set pw = '$(gpw)' where rowid = '${id}';"
  ${cmd} "select rowid as id,* from ${act} where id = '${id}';"|"${PAGER}"
  unset id
}

function delete {
  read -p "Select an id to delete: " id
  ${cmd} "delete from ${act} where rowid = '${id}';"
  unset id
}

function import {
  read -p "Enter a csv file: " csvf;
  sqlite3 -csv "${db}" ".import ${csvf} ${act}"
  unset csvf
}

function usage {
  printf "${hm[@]}\n"
}

for ((;;)) {
  printf "${pr}"
  read ui
  case "${ui}" in
    0) break ;;
    1) create ;;
    2) retrieve ;;
    3) update ;;
    4) delete ;;
    5) import ;;
    6) ${cmd} ;;
    7) usage ;;
    *) printf "${red}Invalid${reset}: You chose ${red}%s${reset}. Choose again from 0 to %d\n" "${ui}" "$((${#op[@]}-1))" ;;
  esac
}
