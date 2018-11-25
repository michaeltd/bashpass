#!/usr/bin/env bash
# bashpass.sh password management in ~50 lines.

declare dm em un pw cm pr hm act="ac"
declare db="$(cd $(dirname ${BASH_SOURCE[0]})&& pwd)/${1:-git.db3}"
declare -a op=( "${grey}Quit${reset}" "${red}New${reset}" "${green}Find${reset}" "${magenta}All${reset}" "${yellow}sqlite${reset}" "${cyan}csv${reset}" "${blue}help${reset}") 
declare -a desc=( "exit." "gathter details to generate a new password." "search records by domain." "print all records." "start a sqlite session against your db." "prompt for a csv file to import." "print this message.") 
declare -a cmd="sqlite3 ${db}"

if [[ (! -x "$(which sha512sum 2> /dev/null)") || (! -x "$(which sqlite3 2> /dev/null)") || (! $(${cmd} "select * from ${act};" 2> /dev/null)) ]]; then
  printf "Need sha512sum, sqlite3 and a working db to function.\n"
  exit 1
fi

hm="\nUsage: $(basename ${BASH_SOURCE[0]}) [db file name]\n\n" # Build some prompts and help messages.
for ((x=0;x<${#op[@]};x++)); do
  pr+="${x}:${op[$x]} "
  hm+="Use: ${bold}${x}${reset}, for ${op[$x]}, which will ${bold}${desc[$x]}${reset}\n"
done
pr+="${bold}Choose[0-$((${#op[@]}-1))]:${reset}"
hm+="\naccounts table format is as follows:\n$(${cmd} .schema)\n"

function gatherdetails { # Get some data, hash a password
  while [[ -z "${dm}" || -z "${em}" || -z "${un}" || -z "${cm}" ]]; do
    if [[ -z "${dm}" ]]; then
      read -p "Domain? " dm
    elif [[ -z "${em}" ]]; then
      read -p "Email? " em
    elif [[ -z "${un}" ]]; then
      read -p "User? " un
    elif [[ -z "${cm}" ]]; then
      read -p "Comment? " cm
    fi
  done
  pw=$(echo "${RANDOM} ${dm} ${RANDOM} ${em} ${RANDOM} ${un} ${RANDOM} ${cm} ${RANDOM}"|sha512sum)
}

function writerecord {
  ${cmd} "insert into ${act} values('${dm//:/\:}', '${em}', '${un}', '${pw//[![:alnum:]]}', '${cm}');"
  sqlite3 -line "${db}" "select * from ${act} where dm like '${dm}';"
  unset dm em un pw cm
}

while :; do
  read -p "${pr}" ui
  case "${ui}" in
    0) break;;
    1) gatherdetails && writerecord;;
    2) read -p "Enter domain to look for: " dm; sqlite3 -line "${db}" "select * from ${act} where dm like '%${dm}%';"; unset dm;;
    3) sqlite3 -line "${db}" "select rowid as id, * from ${act};";;
    4) ${cmd};;
    5) read -p "Enter a csv file: " csvf; sqlite3 -csv "${db}" ".import ${csvf} ${act}";;
    6) printf "${hm[@]}\n";;
    *) printf "${red}Invalid${reset}: You chose ${red}%s${reset}. Choose again from 0 to %d\n" "${ui}" "$((${#op[@]}-1))";;
  esac
done
