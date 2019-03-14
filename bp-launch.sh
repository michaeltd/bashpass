#!/usr/bin/env bash
#
# bp-launch.sh - launch bashpass.sh conditionally depending on environment and invocation.

# link free (S)cript (D)ir(N)ame, (B)ase(N)ame, (F)ull (N)ame.
if [[ -L "${BASH_SOURCE[0]}" ]]; then
    declare SDN="$(cd $(dirname $(readlink ${BASH_SOURCE[0]}))&& pwd -P)" SBN="$(basename $(readlink ${BASH_SOURCE[0]}))"
    declare SFN=${SDN}/${SBN}
else
    declare SDN="$(cd $(dirname ${BASH_SOURCE[0]})&& pwd -P)" SBN="$(basename ${BASH_SOURCE[0]})"
    declare SFN="${SDN}/${SBN}"
fi

cd ${SDN}

if [[ -n "${DISPLAY}" ]]; then
    TRM=$(which terminology||which konsole||which gnome-terminal||which xfce-4-terminal||which terminator||which sakura||which termite||which tilix||which st||which urxvt||which xterm)
    ${TRM} --hold -e "${SDN}/bashpass.sh" "${@}"
else
    "${SDN}/bashpass.sh" "${@}"
fi
