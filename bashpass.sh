#!/usr/bin/env bash
#
# bashpass/bashpass.sh Xdialog/dialog/terminal assisted password management.

#link free (S)cript: (D)ir(N)ame, (B)ase(N)ame.
declare SDN="$(cd $(dirname $(realpath ${BASH_SOURCE[0]})) && pwd -P)"
declare SBN="$(basename $(realpath ${BASH_SOURCE[0]}))"

declare BPUSAGE="Usage: ${SBN} [example{.db3,.sqlite}] (default: git.db3) [Xdialog|dialog|terminal] (default: any available in that order) [debug] [help] (prints usage and quits)"

# Process optional arguments
while [[ -n ${1} ]]; do
    case "${1}" in
        *.db3|*.sqlite)
            declare DB="${SDN}/${1}"
            ftout=$(file -b ${DB}.asc)
            if ! [[ "${ftout[@]}" =~ ^PGP* ]]; then
                printf "%s.asc, does not appear to be a valid PGP file.\n" "${red}${1}${reset}" >&2
                printf "%s\n" "${BPUSAGE}" >&2
                exit 1
            fi ;;
        Xdialog|dialog|terminal) declare UI="${1}" ;;
        -d|--debug|debug) set -x ;;
        -h|--help|help) printf "%s\n" "${BPUSAGE}" >&2; exit 1 ;;
        *) printf "Unrecognized option: %s\n" "${red}${1}${reset}" >&2; exit 1 ;;
    esac
    shift
done

# Pick a default available UI ...
if [[ -x "$(which Xdialog 2> /dev/null)" && -n "${DISPLAY}" ]]; then # Check for X, Xdialog
    declare DIALOG=$(which Xdialog) L="30" C="60"
elif [[ -x "$(which dialog 2> /dev/null)" ]]; then # Check for dialog
    declare DIALOG=$(which dialog) L="0" C="0"
fi

# ... and try to accommodate optional preference.
if [[ "${UI}" == "Xdialog" && -x "$(which Xdialog 2> /dev/null)" && -n "${DISPLAY}" ]]; then # Check for X, Xdialog
    declare DIALOG=$(which Xdialog) L="30" C="60"
elif [[ "${UI}" == "dialog" && -x "$(which dialog 2> /dev/null)" ]]; then # Check for dialog
    declare DIALOG=$(which dialog) L="0" C="0"
elif [[ "${UI}" == "terminal" ]]; then
    unset DIALOG
fi

# Xdialog/dialog
export XDIALOG_HIGH_DIALOG_COMPAT=1 XDIALOG_FORCE_AUTOSIZE=1 XDIALOG_INFOBOX_TIMEOUT=5000 XDIALOG_NO_GMSGS=1
declare DIALOG_OK=0 DIALOG_CANCEL=1 DIALOG_HELP=2 DIALOG_EXTRA=3 DIALOG_ITEM_HELP=4 DIALOG_ESC=255
declare SIG_NONE=0 SIG_HUP=1 SIG_INT=2 SIG_QUIT=3 SIG_KILL=9 SIG_TERM=15

# Temp files
declare TF="${SDN}/.${RANDOM}.${$}"
declare MUTEX="${SDN}/.${SBN}.MUTEX"

# SQLite
declare DB="${DB:-${SDN}/git.db3}" ACT="ac"
declare -a DCM="sqlite3 ${DB}" RCM="sqlite3 -line ${DB}" CCM="sqlite3 -csv ${DB}"

# Build menus and help messages.
declare -a TUI_OPS=( "${red}Create  ${reset}" "${green}Retrieve${reset}" "${blue}Update  ${reset}" "${yellow}Delete  ${reset}" "${magenta}CSV     ${reset}" "${cyan}SQLite3 ${reset}" "${black}Help    ${reset}" "${grey}Quit    ${reset}" )

declare -a GUI_OPS=( "Create" "Retrieve" "Update" "Delete" "CSV" "SQLite3" "Help" "Quit" )

declare -a SDESC=( "New entry" "Find account" "Regen password" "Remove entry" "Import a file" "sqlite3 session" "Help screen" "Exit" )

declare -a DESC=( "gather details for a new account." "search records by domain. (empty for all)" "regenerate an existing password." "remove an account." "prompt for csv file to import(eg:test.csv)." "start an sqlite session against ${DB/*\/}." "Show this message" "Quit this application." )

declare -a TUI_MENU=() # PRompt
declare -a TUI_HMSG="\nUsage: ${SBN} [example{.db3,.sqlite}] (default: git.db3) [Xdialog|dialog|terminal] (default: any available in that order) [debug] [help] (prints usage and quits)\n\n"
declare -a GUI_MENU=() # Menu Text
declare -a GUI_HMSG="\nUsage: ${SBN} [example{.db3,.sqlite}] (default: git.db3) [Xdialog|dialog|terminal] (default: any available in that order) [debug] [help] (prints usage and quits)\n\n"

for (( x = 0; x < ${#TUI_OPS[@]}; x++ )); do
    TUI_MENU+="${x}:${TUI_OPS[$x]}"; (( ( x + 1 ) % 4 == 0 )) && TUI_MENU+="\n" || TUI_MENU+="\t"
    TUI_HMSG+="Use ${bold}${x}${reset}, for ${TUI_OPS[$x]}, which will ${bold}${DESC[$x]}${reset}\n"
    GUI_MENU+="${GUI_OPS[$x]}|${SDESC[$x]}|${DESC[$x]}|"
    GUI_HMSG+="Use ${GUI_OPS[$x]}, to ${DESC[$x]}\n"
done

TUI_MENU+="${bold}Choose[0-$((${#TUI_OPS[@]}-1))]:${reset}"
TUI_HMSG+="\naccounts table format is as follows:\nCREATE TABLE ac(dm VARCHAR(100),em VARCHAR(100),un VARCHAR(100),pw VARCHAR(256),cm VARCHAR(100));\n"
GUI_HMSG+="\naccounts table format is as follows:\nCREATE TABLE ac(dm VARCHAR(100),em VARCHAR(100),un VARCHAR(100),pw VARCHAR(256),cm VARCHAR(100));\n"

clean_up() {
    gpg2 --batch --yes --quiet --default-recipient-self --output "${DB}.asc" --encrypt "${DB}"
    shred --verbose --zero --remove --iterations=30 "${DB}"
    shred --verbose --zero --remove --iterations=30 "${TF}"
    rm -f "${MUTEX}"
}

# No mutex or die.
check_mutex() {
    if [[ -f "${MUTEX}" ]]; then
        printf "${bold} You can only have one instance of ${SBN}.${reset}\n Follow the instructions from here:\n ${underline}https://github.com/michaeltd/bashpass${reset}\n" >&2
        return 1
    fi
}

# Decrypt db3, setup trap and mutex or die.
check_decrypt() {
    if ! gpg2 --batch --yes --quiet --default-recipient-self --output "${DB}" --decrypt "${DB}.asc"; then
        printf "${bold} Decryption failed.${reset}\n Follow the instructions from here:\n ${underline}https://github.com/michaeltd/bashpass${reset}\n" >&2
        return 1
    else
        touch "${MUTEX}"
        # trap needs to be here as we need at least a decrypted db and a mutex file to cleanup
        trap clean_up $SIG_NONE $SIG_HUP $SIG_INT $SIG_QUIT $SIG_TERM
    fi
}

# SQL or die.
check_sql() {
    if ! ${DCM[@]} "SELECT * FROM ${ACT} ORDER BY rowid ASC;" &> /dev/null; then
        printf "${bold}Need a working db to function.${reset}\n Follow the instructions from here:\n ${underline}https://github.com/michaeltd/bashpass${reset}\n" >&2
        return 1
    fi
}

# Generate PassWord
gpw() {
    echo $(tr -dc '[:alnum:]~!@#$%^_+:?' < /dev/urandom|head -c "${1:-64}")
}

#RowID'S
rids() {
    echo $(${DCM[@]} "SELECT rowid FROM ${ACT} ORDER BY rowid ASC;")
}

# -.-
maxid() {
    echo $(${DCM[@]} "SELECT MAX(rowid) FROM ${ACT};")
}

#Row count
rcount() {
    echo $(${DCM[@]} "SELECT COUNT(rowid) FROM ${ACT};")
}

#Build Row Lines (for (X)dialog check/radio lists)
brl() {
    for i in $(rids); do
        local dm=$(${DCM[@]} "SELECT dm FROM ${ACT} WHERE rowid = '${i}';"|sed 's/ /-/g')
        local em=$(${DCM[@]} "SELECT em FROM ${ACT} WHERE rowid = '${i}';"|sed 's/ /-/g')
        local rl+="${i} ${dm:-null}:${em:-null} off "
    done
    echo ${rl[@]}
}

create() {
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

    ${DCM[@]} "INSERT INTO ${ACT} VALUES('${DM//:/\:}', '${EM}', '${UN}', '${PW}', '${CM}');"
    ${RCM[@]} "SELECT rowid AS id,* FROM ${ACT} WHERE id = $(( ++MAXID ));" > ${TF}

    if [[ "${DIALOG}" == "$(which Xdialog)" ]]; then
        ${DIALOG} --backtitle ${SBN} --title "results" --editbox "${TF}" $L $C 2>/dev/null
    else
        cat ${TF}|${PAGER}
    fi
}

retrieve() {
    local DM
    if [[ -n "${DIALOG}" ]]; then
        ${DIALOG} --backtitle ${SBN} --title "domain" --inputbox "Enter domain to look for (empty for All): " $L $C 2> ${TF}
        (( ${?} != ${DIALOG_OK} )) && return
    else
        read -p "Enter domain to look for (empty for All): " DM
        echo "${DM}" > ${TF}
    fi
    DM=$(cat ${TF})
    ${RCM[@]} "SELECT rowid AS id,* FROM ${ACT} WHERE dm LIKE '%${DM}%';" > ${TF}

    if [[ "${DIALOG}" == "$(which Xdialog)" ]]; then
        ${DIALOG} --backtitle ${SBN} --title "results" --editbox "${TF}" $L $C 2>/dev/null
    else
        cat ${TF}|${PAGER}
    fi
}

update() {
    local ID ERRLVL PW
    if [[ -n "${DIALOG}" ]]; then
        ${DIALOG} --backtitle ${SBN} --title "update accout:" --radiolist "Select an id to update: " $L $C 5 $(brl) 2> ${TF}
        ERRLVL=${?} ID="$(cat ${TF})"
        (( ${ERRLVL} != ${DIALOG_OK} )) || [[ -z ${ID} ]] && return
    else
        read -p "Select an id to update (empty to cancel): " ID
        ERRLVL=${?}
        (( ${ERRLVL} != ${DIALOG_OK} )) || [[ -z ${ID} ]] && return
    fi
    if [[ -n "${DIALOG}" ]]; then
        ${DIALOG} --backtitle ${SBN} --title "password" --inputbox "Enter a password or a password length (1-64) or empty for auto (max length): " $L $C 2> ${TF}
        ERRLVL=${?} PW="$(cat ${TF})"
        (( ${ERRLVL} != ${DIALOG_OK} )) && return
    else
        read -p "Enter a password or a password length (1-64) or empty for auto (max length): " PW
        ERRLVL=${?}
        (( ${ERRLVL} != ${DIALOG_OK} )) && return
    fi
    [[ "${PW}" =~ ^[0-9]+$ ]] && (( PW >= 1 && PW <= 64 )) && PW="$(gpw ${PW})"
    [[ -z ${PW} ]] && PW="$(gpw)"
    ${DCM[@]} "UPDATE ${ACT} SET pw = '${PW}' WHERE rowid = '${ID}';"
    ${RCM[@]} "SELECT rowid AS id,* FROM ${ACT} WHERE id = '${ID}';" > ${TF}
    if [[ "${DIALOG}" == "$(which Xdialog)" ]]; then
        ${DIALOG} --backtitle ${SBN} --title "results" --editbox "${TF}" $L $C 2> /dev/null
    else
        cat ${TF}|${PAGER}
    fi
}

delete() {
    local ID
    if [[ -n "${DIALOG}" ]]; then
        ${DIALOG} --backtitle ${SBN} --title "delete account:" --radiolist "Select an id to delete: " $L $C 5 $(brl) 2> ${TF}
        local ERRLVL=${?} ID="$(cat ${TF})"
        (( ${ERRLVL} != ${DIALOG_OK} )) || [[ -z ${ID} ]] && return
    else
        read -p "Select an id to delete (empty to cancel): " ID
        echo "${ID}" > ${TF}
    fi
    ${DCM[@]} "DELETE FROM ${ACT} WHERE rowid = '$(cat ${TF})';"
    [[ -n "${DIALOG}" ]] && ${DIALOG} --backtitle ${SBN} --title dialog --msgbox "Account ID: $ID deleted." $L $C || printf "Account ID: $ID deleted.\n"
}

import() {
    local MAXID=$(maxid) CSVF
    if [[ -n "${DIALOG}" ]]; then
        ${DIALOG} --backtitle ${SBN} --title "Enter a csv file:" --fselect "${SDN}/" $L $C 2> ${TF}
        (( ${?} != ${DIALOG_OK} )) && return
        CSVF=$(cat ${TF})
    else
        read -p "Enter a csv file: " CSVF;
        echo "${CSVF}" > ${TF}
    fi
    ${CCM[@]} ".import ${CSVF} ${ACT}" 2> ${TF}
    if (( ${?} != 0 )); then
        if [[ -n "${DIALOG}" ]]; then
            ${DIALOG} --backtitle ${SBN} --title Error --msgbox "Error reported: $(cat ${TF})" $L $C
        fi
        echo "Error: $(cat ${TF})"
        return
    fi
    ${RCM[@]} "SELECT rowid AS id,* FROM ${ACT} WHERE rowid > ${MAXID};" > ${TF}
    if [[ "${DIALOG}" == "$(which Xdialog)" ]]; then
        ${DIALOG} --backtitle ${SBN} --title "results" --editbox "${TF}" $L $C 2>/dev/null
    else
        cat ${TF}|${PAGER}
    fi
}

usage() {
    [[ -n "${DIALOG}" ]] && ${DIALOG} $([[ "${DIALOG}" == "Xdialog" ]] && echo "--fill") --backtitle ${SBN} --title Help --msgbox "${GUI_HMSG[@]}" $L $C || printf "${TUI_HMSG[@]}\n"
}

main() {

    check_mutex || exit $?
    check_decrypt || exit $?
    check_sql || exit $?

    while :; do
        if [[ -n "${DIALOG}" ]]; then # Xdialog, dialog menu
            OFS=$IFS IFS=$'\|'
            ${DIALOG} --backtitle ${SBN} --title dialog --help-button --item-help --cancel-label "Quit" --menu "Menu:" $L $C $((${#GUI_OPS[@]})) ${GUI_MENU} 2> ${TF}
            ERRLVL=$?
            IFS=$OFS
        else # Just terminal menu.
            printf "${TUI_MENU}"
            read UI
            ERRLVL=$?
            echo ${UI} > ${TF}
        fi

        case ${ERRLVL} in
            ${DIALOG_OK})
                case "$(cat ${TF})" in
                    "${GUI_OPS[0]}"|"0") create ;;
                    "${GUI_OPS[1]}"|"1") retrieve ;;
                    "${GUI_OPS[2]}"|"2") update ;;
                    "${GUI_OPS[3]}"|"3") delete ;;
                    "${GUI_OPS[4]}"|"4") import ;;
                    "${GUI_OPS[5]}"|"5") ${RCM[@]} ;;
                    "${GUI_OPS[6]}"|"6") usage ;;
                    "${GUI_OPS[7]}"|"7") exit ;;
                    *) printf "${red}Invalid responce: %s${reset}. Choose again from 0 to %d\n" "${UI}" "$((${#TUI_OPS[@]}-1))" >&2;;
                esac ;;
            ${DIALOG_CANCEL}) exit ;;
            ${DIALOG_HELP}) usage ;;
            ${DIALOG_ESC}) exit ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
