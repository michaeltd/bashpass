#!/bin/bash
#
# bashpass/bashpass.sh Xdialog/dialog/terminal assisted password management.

if [[ ! -t 1 ]]; then
    msg="Error: You'll need to run ${0/*\/} in a terminal (or tty)!"
    notify-send "${msg}" || \
        Xdialog --title "Error" --infobox "${msg}" 0 0 30000 || \
        xmessage -nearmouse -timeout 30 "${msg}" ||
        echo -ne "${msg}\n" >&2
    exit 1
elif (( "${BASH_VERSINFO[0]}" < 4 )); then
    msg="Error: You'll need bash major version 4."
    notify-send "${msg}" || \
        Xdialog --title "Error" --infobox "${msg}" 0 0 30000 || \
        xmessage -nearmouse -timeout 30 "${msg}" ||
        echo -ne "${msg}\n" >&2
    exit 1
elif [[ ! $(command -v sqlite3) ]]; then
    msg="Error: You need SQLite3 installed."
    notify-send "${msg}" || \
        Xdialog --title "Error" --infobox "${msg}" 0 0 30000 || \
        xmessage -nearmouse -timeout 30 "${msg}" ||
        echo -ne "${msg}\n" >&2
    exit 1
elif [[ ! $(command -v gpg2) ]]; then
    msg="Error: You need GNU Privacy Guard v2 (gnupg) installed."
    notify-send "${msg}" || \
        Xdialog --title "Error" --infobox "${msg}" 0 0 30000 || \
        xmessage -nearmouse -timeout 30 "${msg}" ||
        echo -ne "${msg}\n" >&2
    exit 1
fi

# Xdialog/dialog
export XDIALOG_HIGH_DIALOG_COMPAT=1 XDIALOG_FORCE_AUTOSIZE=1 XDIALOG_INFOBOX_TIMEOUT=5000 XDIALOG_NO_GMSGS=1
export DIALOG_OK=0 DIALOG_CANCEL=1 DIALOG_HELP=2 DIALOG_EXTRA=3 DIALOG_ITEM_HELP=4 DIALOG_ESC=255
export SIG_NONE=0 SIG_HUP=1 SIG_INT=2 SIG_QUIT=3 SIG_KILL=9 SIG_TERM=15

#link free (S)cript: (D)ir(N)ame, (B)ase(N)ame.
declare SDN
SDN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
declare SBN
SBN="$(basename "$(realpath "${BASH_SOURCE[0]}")")"

declare BPUSAGE
BPUSAGE="Usage: ${SBN} [git.sqlite (default)] [Xdialog|dialog|terminal] (default: any available in that order) [debug] [help] (prints usage and quits)"

# Process optional arguments
while [[ -n ${1} ]]; do
    case "${1}" in
        *.sqlite)
            declare DB
            DB="${SDN}/${1}"
            ftout=( "$(file -b "${DB}.pgp")" )
            if ! [[ "${ftout[*]}" =~ ^PGP* ]]; then
                echo -ne "Error: ${1}.pgp, does not appear to be a valid PGP file.\n" >&2
                echo -ne "${BPUSAGE}\n" >&2
                exit 1
            fi ;;
        Xdialog|dialog|terminal) declare USRINTRFCE="${1}" ;;
        -d|--debug|debug) set -x ;;
        -h|--help|help) echo -ne "${BPUSAGE}\n" >&2; exit 1 ;;
        *) echo -ne "Unrecognized option: ${1}\n" >&2; exit 1 ;;
    esac
    shift
done

# Pick a default available UI ...
if [[ -x "$(command -v Xdialog)" && -n "${DISPLAY}" ]]; then # Check for X, Xdialog
    declare DIALOG L C
    DIALOG=$(command -v Xdialog) L="30" C="60"
elif [[ -x "$(command -v dialog)" ]]; then # Check for dialog
    declare DIALOG L C
    DIALOG=$(command -v dialog) L="0" C="0"
fi

# ... and try to accommodate optional preference.
if [[ "${USRINTRFCE}" == "Xdialog" && -x "$(command -v "${USRINTRFCE}")" && -n "${DISPLAY}" ]]; then # Check for X, Xdialog
    declare DIALOG L C
    DIALOG=$(command -v "${USRINTRFCE}") L="30" C="60"
elif [[ "${USRINTRFCE}" == "dialog" && -x "$(command -v "${USRINTRFCE}")" ]]; then # Check for dialog
    declare DIALOG L C
    DIALOG=$(command -v "${USRINTRFCE}") L="0" C="0"
elif [[ "${USRINTRFCE}" == "terminal" ]]; then # plain ol' terminal
    unset DIALOG
fi

# SQLite
declare DB ACT
DB="${DB:-${SDN}/git.sqlite}" ACT="ac"
declare -a DCM RCM CCM
DCM=("sqlite3" "${DB}") RCM=("sqlite3" "-line" "${DB}") CCM=("sqlite3" "-csv" "${DB}")
declare BNDB
BNDB="${DB/*\/}"

# Temp files
declare TF="${SDN}/.${SBN}.${BNDB}.${$}.TF"
declare MUTEX="${SDN}/.${SBN}.${BNDB}.MUTEX"

#clean_up() {
#    # Upon successfull encryption ONLY shred files
#    #gpg2 --batch --yes --default-recipient-self --output "${DB}.asc" --encrypt "${DB}" && shred --verbose --zero --remove {"${DB}","${TF}","${MUTEX}"}
#    exit "${1:-0}"
#}

do_quit() {
    # gpg2 --batch --yes --quiet --default-recipient-self --output "${DB}.asc" --encrypt "${DB}"
    # shred --verbose --zero --remove --iterations=30 {"${DB}","${TF}","${MUTEX}"}

    # Upon successfull encryption ONLY shred files
    # gpg2 --batch --yes --default-recipient-self --output "${DB}.gpg" --encrypt "${DB}" && shred --verbose --zero --remove {"${DB}","${TF}","${MUTEX}"}
    gpg2 --batch --yes --default-recipient-self --output "${DB}.pgp" --encrypt "${DB}" && shred --zero --remove {"${DB}","${TF}","${MUTEX}"}
    #reset
    exit "${1:-0}"
}

# No mutex or die.
check_mutex() {
    if [[ -f "${MUTEX}" ]]; then
        echo -ne "Error: You can only have one instance of ${SBN}.\n Follow the instructions from here:\n https://github.com/michaeltd/bashpass/ \n" >&2
        return 1
    fi
}

# Decrypt .sqlite, setup trap and mutex or die.
check_decrypt() {
    #if ! gpg2 --batch --yes --quiet --default-recipient-self --output "${DB}" --decrypt "${DB}.asc"; then
    if ! gpg2 --batch --yes --default-recipient-self --output "${DB}" --decrypt "${DB}.pgp"; then
        echo -ne "Error: Decryption failed.\n Follow the instructions from here:\n https://github.com/michaeltd/bashpass/ \n" >&2
        return 1
    else
        ftout=( "$(file -b "${DB}")" ) # We do have an decrypted $DB file so we might as well check it's validity.
        if ! [[ "${ftout[*]}" =~ ^SQLite\ 3.x\ database* ]]; then
            echo -ne "Error: $(basename "${DB}"), does not appear to be a valid SQLite 3.x database file.\n" >&2
            echo -ne "${BPUSAGE}\n" >&2
            exit 1
        fi
        touch "${MUTEX}"
        touch "${TF}"
        # trap needs to be here as we need at least a decrypted db and a mutex file to cleanup
        # trap clean_up $SIG_NONE $SIG_HUP $SIG_INT $SIG_QUIT $SIG_TERM
    fi
}

# SQL or die.
check_sql() {
    if ! "${DCM[@]}" "SELECT * FROM ${ACT} ORDER BY rowid ASC;" &> /dev/null; then
        echo -ne "Error: Need a working db to function.\n Follow the instructions from here:\n https://github.com/michaeltd/bashpass/ \n" >&2
        return 1
    fi
}

# Generate PassWord
gpw() {
    tr -dc '[:alnum:]~!@#$%^_+:?' < /dev/urandom|head -c "${1:-64}"
}

# RowID'S
rids() {
    "${DCM[@]}" "SELECT rowid FROM ${ACT} ORDER BY rowid ASC;"
}

# -.-
maxid() {
    local MAXID
    MAXID="$("${DCM[@]}" "SELECT MAX(rowid) FROM ${ACT};")"
    echo "${MAXID:-0}" # check null values
}

# Row count
rcount() {
    "${DCM[@]}" "SELECT COUNT(rowid) FROM ${ACT};"
}

# Build Row Lines (for (X)dialog check/radio lists)
brl() {

    local dm em rl

    for i in $(rids); do
        dm=$("${DCM[@]}" "SELECT dm FROM ${ACT} WHERE rowid = '${i}';"|sed 's/ /-/g')
        em=$("${DCM[@]}" "SELECT em FROM ${ACT} WHERE rowid = '${i}';"|sed 's/ /-/g')
        rl+="${i} ${dm:-null}_${em:-null} off "
    done
    echo "${rl[@]}"
}

create() {
    local MAXID DM EM UN PW CM
    MAXID="$(maxid)"
    if [[ -n "${DIALOG}" ]]; then
        "${DIALOG}" --backtitle "${SBN}" --title dialog --inputbox "Enter a domain:" "${L}" "${C}" 2> "${TF}"
        (( $? == DIALOG_OK )) && DM=$(cat "${TF}") || return
        "${DIALOG}" --backtitle "${SBN}" --title dialog --inputbox "Enter an email:" "${L}" "${C}" 2> "${TF}"
        (( $? == DIALOG_OK )) && EM=$(cat "${TF}") || return
        "${DIALOG}" --backtitle "${SBN}" --title dialog --inputbox "Enter a username:" "${L}" "${C}" 2> "${TF}"
        (( $? == DIALOG_OK )) && UN=$(cat "${TF}") || return
        "${DIALOG}" --backtitle "${SBN}" --title dialog --passwordbox "Enter a password:" "${L}" "${C}" 2> "${TF}"
        (( $? == DIALOG_OK )) && PW=$(cat "${TF}") || return
        "${DIALOG}" --backtitle "${SBN}" --title dialog --inputbox "Enter comments:" "${L}" "${C}" 2> "${TF}"
        (( $? == DIALOG_OK )) && CM=$(cat "${TF}") || return
    else
        while [[ -z "${DM}" || -z "${EM}" || -z "${UN}" || -z "${PW}" || -z "${CM}" ]]; do
            if [[ -z "${DM}" ]]; then
                echo -ne "Enter a domain: "
                read -r DM
            elif [[ -z "${EM}" ]]; then
                echo -ne "Enter an email: "
                read -r EM
            elif [[ -z "${UN}" ]]; then
                echo -ne "Enter a username: "
                read -r UN
            elif [[ -z "${PW}" ]]; then
                echo -ne "Enter a password: "
                read -r PW
            elif [[ -z "${CM}" ]]; then
                echo -ne "Enter comment: "
                read -r CM
            fi
        done
    fi
    "${DCM[@]}" "INSERT INTO ${ACT} VALUES('${DM//:/\:}', '${EM}', '${UN}', '${PW}', '${CM}');"
    "${RCM[@]}" "SELECT rowid AS id,* FROM ${ACT} WHERE id = $(( ++MAXID ));" > "${TF}"
    if [[ "${DIALOG}" == "$(command -v Xdialog)" ]]; then
        [[ $(command -v xclip 2> /dev/null) ]] && echo "${PW}"|"$(command -v xclip 2> /dev/null)" "-r"
        "${DIALOG}" --backtitle "${SBN}" --title "results" --editbox "${TF}" "${L}" "${C}" 2>/dev/null
    else
        "${PAGER}" "${TF}"
    fi
}

retrieve() {
    local DM RC PW
    if [[ -n "${DIALOG}" ]]; then
        "${DIALOG}" --backtitle "${SBN}" --title "domain" --inputbox "Enter domain to look for (empty for All): " "${L}" "${C}" 2> "${TF}"
        (( $? != DIALOG_OK )) && return
    else
        echo -ne "Enter domain to look for (empty for All): "
        read -r DM
        echo "${DM}" > "${TF}"
    fi
    DM=$(cat "${TF}")

    # Record Set
    "${RCM[@]}" "SELECT rowid AS id,* FROM ${ACT} WHERE dm LIKE '%${DM}%';" > "${TF}"

    if [[ "${DIALOG}" == "$(command -v Xdialog)" ]]; then
        if [[ $(command -v xclip 2> /dev/null) ]]; then
            # Record Count
            RC="$("${RCM[@]}" "SELECT count(rowid) AS rc FROM ${ACT} WHERE dm LIKE '%${DM}%';")"
            if (( RC == 1 )); then
                #shellcheck disable=SC2207
                PW=( $("${RCM[@]}" "SELECT pw FROM ${ACT} WHERE dm LIKE '%${DM}%';") )
                echo "${PW[((${#PW[*]}-1))]}"|"$(command -v xclip 2> /dev/null)" "-r"
            fi
        fi
        "${DIALOG}" --backtitle "${SBN}" --title "results" --editbox "${TF}" "${L}" "${C}" 2>/dev/null
    else
        "${PAGER}" "${TF}"
    fi
}

update() {
    local ID ERRLVL PW
    if [[ -n "${DIALOG}" ]]; then
        #shellcheck disable=SC2046
        "${DIALOG}" --backtitle "${SBN}" --title "update accout:" --radiolist "Select an id to update: " "${L}" "${C}" 5 $(brl) 2> "${TF}"
        ERRLVL="${?}" ID="$(cat "${TF}")"
        (( ERRLVL != DIALOG_OK )) || [[ -z "${ID}" ]] && return
    else
        echo -ne "Select an id to update (empty to cancel): "
        read -r ID
        ERRLVL="${?}"
        (( ERRLVL != DIALOG_OK )) || [[ -z "${ID}" ]] && return
    fi
    if [[ -n "${DIALOG}" ]]; then
        "${DIALOG}" --backtitle "${SBN}" --title "password" --inputbox "Enter a password or a password length (8-64) or empty for auto (max length): " "${L}" "${C}" 2> "${TF}"
        ERRLVL="${?}" PW="$(cat "${TF}")"
        (( ERRLVL != DIALOG_OK )) && return
    else
        echo -ne "Enter a password or a password length (8-64) or empty for auto (max length): "
        read -r PW
        ERRLVL="${?}"
        (( ERRLVL != DIALOG_OK )) && return
    fi
    [[ "${PW}" =~ ^[0-9]+$ ]] && (( PW >= 8 && PW <= 64 )) && PW="$(gpw "${PW}")"
    [[ -z "${PW}" ]] || (( ${#PW} < 8 )) && PW="$(gpw)"
    "${DCM[@]}" "UPDATE ${ACT} SET pw = '${PW}' WHERE rowid = '${ID}';"
    "${RCM[@]}" "SELECT rowid AS id,* FROM ${ACT} WHERE id = '${ID}';" > "${TF}"
    if [[ "${DIALOG}" == "$(command -v Xdialog)" ]]; then
        [[ $(command -v xclip 2> /dev/null) ]] && echo "${PW}"|"$(command -v xclip 2> /dev/null)" "-r"
        "${DIALOG}" --backtitle "${SBN}" --title "results" --editbox "${TF}" "${L}" "${C}" 2> /dev/null
    else
        "${PAGER}" "${TF}"
    fi
}

delete() {
    local ERRLVL ID
    if [[ -n "${DIALOG}" ]]; then
        #shellcheck disable=SC2046
        "${DIALOG}" --backtitle "${SBN}" --title "delete account:" --radiolist "Select an id to delete: " "${L}" "${C}" 5 $(brl) 2> "${TF}"
        ERRLVL="${?}" ID="$(cat "${TF}")"
        (( ERRLVL != DIALOG_OK )) || [[ -z "${ID}" ]] && return
    else
        echo -ne "Select an id to delete (empty to cancel): "
        read -r ID
        echo "${ID}" > "${TF}"
        [[ -z "${ID}" ]] && return
    fi
    "${DCM[@]}" "DELETE FROM ${ACT} WHERE rowid = '$(cat "${TF}")';"
    [[ -n "${DIALOG}" ]] && "${DIALOG}" --backtitle "${SBN}" --title dialog --msgbox "Account ID: #${ID} deleted." "${L}" "${C}" || echo -ne "Account ID: #${ID} deleted.\n" ""
}

import() {
    local MAXID CSVF ERRLVL
    MAXID="$(maxid)"
    if [[ -n "${DIALOG}" ]]; then
        "${DIALOG}" --backtitle "${SBN}" --title "Enter a csv file:" --fselect "${SDN}/" "${L}" "${C}" 2> "${TF}"
        (( $? != DIALOG_OK )) && return
        CSVF=$(cat "${TF}")
        [[ -z "${CSVF}" ]] && return
    else
        echo -ne "Enter a csv file (empty to cancel): "
        read -r CSVF
        echo "${CSVF}" > "${TF}"
        [[ -z "${CSVF}" ]] && return
    fi
    "${CCM[@]}" ".import ${CSVF} ${ACT}" 2> "${TF}"
    ERRLVL="${?}"
    if (( ERRLVL != 0 )); then
        if [[ -n "${DIALOG}" ]]; then
            "${DIALOG}" --backtitle "${SBN}" --title Error --msgbox "Error reported: $(cat "${TF}")" "${L}" "${C}"
        fi
        echo "Error: $(cat "${TF}")"
        return
    fi
    "${RCM[@]}" "SELECT rowid AS id,* FROM ${ACT} WHERE rowid > ${MAXID};" > "${TF}"
    if [[ "${DIALOG}" == "$(command -v Xdialog)" ]]; then
        "${DIALOG}" --backtitle "${SBN}" --title "results" --editbox "${TF}" "${L}" "${C}" 2> /dev/null
    else
        "${PAGER}" "${TF}"
    fi
}

usage() {
    if [[ -n "${DIALOG}" ]]; then
        #${DIALOG} $([[ "${DIALOG}" == "Xdialog" ]] && echo "--fill") --backtitle ${SBN} --title Help --msgbox "${GUI_HMSG[@]}" $L $C
        "${DIALOG}" --backtitle "${SBN}" --title Help --msgbox "${GUI_HMSG[*]}" "${L}" "${C}"
    else
        echo -e "${TUI_HMSG[*]}"
    fi
}

main() {

    check_mutex || exit $?
    check_decrypt || exit $? # Have password .sqlite, $TF and $MUTEX so from now on, instead of exiting, we're do_quit for propper housekeeping.
    check_sql || do_quit $?

    # Build menus and help messages.
    declare -a TUI_OPS=("${red}Create  ${reset}" "${green}Retrieve${reset}" "${blue}Update  ${reset}" "${cyan}Delete  ${reset}" "${yellow}CSV     ${reset}" "${magenta}SQLite3 ${reset}" "${white}Help    ${reset}" "${black}Quit    ${reset}")
    declare -a GUI_OPS=("Create" "Retrieve" "Update" "Delete" "CSV" "SQLite3" "Help" "Quit")
    declare -a SDESC=("New entry" "Find account" "Regen password" "Remove entry" "Import a file" "sqlite3 session" "Help screen" "Exit")
    declare -a DESC=("gather details for a new account." "search records by domain. (empty for all)" "regenerate an existing password." "remove an account." "prompt for csv file to import(eg:test.csv)." "start an sqlite session against ${BNDB}." "Show this message" "Quit this script.")

    declare -a TUI_MENU=()
    declare -a TUI_HMSG=("\n${BPUSAGE[*]}}\n\n")
    declare GUI_MENU
    declare -a GUI_HMSG=("\n${BPUSAGE[*]}}\n\n")

    for (( x = 0; x < ${#TUI_OPS[@]}; x++ )); do
        TUI_MENU+=("${x}:${TUI_OPS[$x]}"); (( ( x + 1 ) % 4 == 0 )) && TUI_MENU+=("\n") || TUI_MENU+=("\t")
        TUI_HMSG+=("Use ${x}, for ${TUI_OPS[$x]}, which will ${DESC[$x]}\n")
        GUI_MENU+="${GUI_OPS[$x]}|${SDESC[$x]}|${DESC[$x]}|"
        GUI_HMSG+=("Use ${GUI_OPS[$x]}, to ${DESC[$x]}\n")
    done

    TUI_MENU+=("Choose[0-$((${#TUI_OPS[@]}-1))]:")
    TUI_HMSG+=("\naccounts table format is as follows:\n$(${DCM[*]} ".schema ${ACT}")\n\n")
    GUI_HMSG+=("\naccounts table format is as follows:\n$(${DCM[*]} ".schema ${ACT}")\n\n")

    while :; do
        if [[ -n "${DIALOG}" ]]; then # Xdialog, dialog menu
            OFS="${IFS}" IFS=$'\|'
            #shellcheck disable=SC2086
            "${DIALOG}" --backtitle "${SBN}" --title dialog --help-button --item-help --cancel-label "Quit" --menu "Menu:" "${L}" "${C}" $((${#GUI_OPS[*]})) ${GUI_MENU} 2> "${TF}"
            ERRLVL="${?}"
            IFS="${OFS}"
        else # Just terminal menu.
            echo -ne " ${TUI_MENU[*]}"
            read -r USRINPT
            ERRLVL="${?}"
            echo "${USRINPT}" > "${TF}"
        fi

        case "${ERRLVL}" in
            "${DIALOG_OK}")
                case "$(cat "${TF}")" in
                    "${GUI_OPS[0]}"|"0") create ;;
                    "${GUI_OPS[1]}"|"1") retrieve ;;
                    "${GUI_OPS[2]}"|"2") update ;;
                    "${GUI_OPS[3]}"|"3") delete ;;
                    "${GUI_OPS[4]}"|"4") import ;;
                    "${GUI_OPS[5]}"|"5") "${RCM[@]}" ;;
                    "${GUI_OPS[6]}"|"6") usage ;;
                    "${GUI_OPS[7]}"|"7") do_quit ;;
                    *) echo -ne "Invalid responce: ${USRINPT}. Choose from 0 to $((${#TUI_OPS[*]}-1))\n" >&2;;
                esac ;;
            "${DIALOG_CANCEL}") do_quit ;;
            "${DIALOG_HELP}") usage ;;
            "${DIALOG_ESC}") do_quit ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
