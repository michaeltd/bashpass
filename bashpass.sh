#!/usr/bin/env bash
# bashpass.sh terminal password management.

declare db="${1:-git.db3}" dm em un pw cm pr hm act="ac"
declare -a op=( "${grey}Quit${reset}" "${red}New${reset}" "${green}Find${reset}" "${blue}Edit${reset}" "${yellow}Del${reset}" "${magenta}sqlite${reset}" "${cyan}csv${reset}" "${black}help${reset}" ) desc=( "exit this menu." "gathter details to generate a new password." "search records by domain." "update an existing password." "remove an account." "start an sqlite session against your db." "prompt for a csv file to import (eg: test.csv)." "print this message." ) cmd="sqlite3 -line ${db}"

if [[ (! -x "$(which sqlite3 2> /dev/null)") || (! $(${cmd} "select * from ${act};" 2> /dev/null)) ]]; then
  printf "Need sqlite3 and a working db to function.\nIf sqlite3 is in your path,\nRun 'sqlite3 my.db3 < ac.sql && bashpass.sh my.db3'\nfrom this directory: $(pwd)\n"
  exit 1
fi

hm="\nUsage: $(basename ${BASH_SOURCE[0]}) [dbfile.db3]\n\n" # Build some prompts and help messages.
for ((x=0;x<${#op[@]};x++)); do
  pr+="${x}:${op[$x]} "
  hm+="Use ${bold}${x}${reset}, for ${op[$x]}, which will ${bold}${desc[$x]}${reset}\n"
done
pr+="\n${bold}Choose[0-$((${#op[@]}-1))]:${reset}"
hm+="\naccounts table format is as follows:\n$(${cmd} .schema)\n"

while :; do
  read -p "${pr}" ui
  case "${ui}" in
    0) break;;
    1)
      while [[ -z "${dm}" || -z "${em}" || -z "${un}" || -z "${cm}" ]]; do
        if [[ -z "${dm}" ]]; then read -p "Domain? " dm
        elif [[ -z "${em}" ]]; then read -p "Email? " em
        elif [[ -z "${un}" ]]; then read -p "Username? " un
        elif [[ -z "${cm}" ]]; then read -p "Comment? " cm
        fi
      done
      pw="$(head /dev/urandom|tr -dc 'a-zA-Z0-9~!@#$%^&*_-'|head -c 64)"
      ${cmd} "insert into ${act} values('${dm//:/\:}', '${em}', '${un}', '${pw}', '${cm}');"
      ${cmd} "select rowid as id,* from ${act} where dm like '${dm}';"
      unset dm em un pw cm;;
    2) read -p "Enter domain to look for (empty for All): " dm;${cmd} "select rowid as id,* from ${act} where dm like '%${dm}%';";unset dm;;
    3) read -p "Select an id to update: " id;pw="$(head /dev/urandom|tr -dc 'a-zA-Z0-9~!@#$%^&*_-'|head -c 64)";${cmd} "update ac set pw = '${pw}' where rowid = '${id}';";${cmd} "select rowid as id,* from ${act} where id = '${id}';";unset id rp pw;;
    4) read -p "Select an id to delete: " id;${cmd} "delete from ac where rowid = '${id}';";unset id rp;;
    5) ${cmd};;
    6) read -p "Enter a csv file: " csvf;sqlite3 -csv "${db}" ".import ${csvf} ${act}";;
    7) printf "${hm[@]}\n";;
    *) printf "${red}Invalid${reset}: You chose ${red}%s${reset}. Choose again from 0 to %d\n" "${ui}" "$((${#op[@]}-1))";;
  esac
done
