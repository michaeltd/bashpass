#!/usr/bin/env bash
#
# import.sh common defs

declare DB="${1:-git.db3}" ACT="ac"

declare -a DCM="sqlite3 ${DB}" RCM="sqlite3 -line ${DB}" CCM="sqlite3 -csv ${DB}"

declare -a TOP=( "${red}Create  ${reset}" "${green}Retrieve${reset}" "${blue}Update  ${reset}" "${yellow}Delete  ${reset}" "${magenta}CSV     ${reset}" "${cyan}SQLite3 ${reset}" "${black}Help    ${reset}" "${grey}Quit    ${reset}" )
declare -a GOP=( "Create" "Retrieve" "Update" "Delete" "CSV" "SQLite3" "Help" "Quit" )
declare -a SDESC=( "New entry" "Find account" "Regen password" "Remove entry" "Import a file" "sqlite3 session" "Help screen" "Exit" )
declare -a DESC=( "gathter details to generate a new password." "search records by domain." "regenerate an existing password." "remove an account." "prompt for csv file to import(eg:test.csv)." "start an sqlite session against ${DB}." "Show this message" "Quit this application." )

if [[ -x "$(which Xdialog)" && -n "${DISPLAY}" ]]; then
  declare DIALOG=$(which Xdialog) L="30" C="80"
else
  declare DIALOG=$(which dialog) L="0" C="0"
fi

declare DIALOG_OK=0 DIALOG_CANCEL=1 DIALOG_HELP=2 DIALOG_EXTRA=3 DIALOG_ITEM_HELP=4 DIALOG_ESC=255
declare SIG_NONE=0 SIG_HUP=1 SIG_INT=2 SIG_QUIT=3 SIG_KILL=9 SIG_TERM=15

declare H="350" W="500" # H=$(( $(xwininfo -root | awk '$1=="Height:" {print $2}') / 3 )) W=$(( $(xwininfo -root | awk '$1=="Width:" {print $2}') / 3 ))

declare TF="${SDN}/.deleteme.${RANDOM}.${$}"

trap "rm -f ${TF}" $SIG_NONE $SIG_HUP $SIG_INT $SIG_QUIT $SIG_TERM

# Help message
declare -a PR=()
declare -a THM="\nUsage: ${SBN} [dbfile.db3]\n\n"
declare -a HM="\nUsage: ${SBN} [dbfile.db3]\n\n"
declare -a MT=()
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
