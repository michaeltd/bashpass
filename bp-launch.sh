#!/usr/bin/env bash
#
# bp-launch.sh - launch bashpass.sh conditionally depending on environment and invocation.

TERMINOLOGY=( "terminology" "--hold" "-e" ) URXVT=( "urxvt" "-depth" "32" "-bg" "rgba:0000/0000/0000/aaaa" "-hold" "-e" ) XTERM=( "xterm" "-hold" "-e" )
TERMS=( TERMINOLOGY[@] URXVT[@] XTERM[@] )

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
    for (( x = 0; x < ${#TERMS[@]}; x++ )); do
        if command -v ${!TERMS[$x]:0:1} &> /dev/null; then
            break
        fi
    done
    exec ${!TERMS[$x]} "${SDN}/bashpass.sh" "${@}"
else
    exec "${SDN}/bashpass.sh" "${@}"
fi
