#!/usr/bin/env bash
#
# bashpass/install.sh - Install bashpass.sh

if [[ ! -t 1 ]]; then
    echo -ne "You'll need to run ${0/*\/} in a terminal\n" >&2
    exit 1
elif [[ ! $(command -v sqlite3) ]]; then
    echo -ne "You need SQLite3 installed.\n" >&2
    exit 1
elif [[ ! $(command -v gpg2) ]]; then
    echo -ne "You need GNU Privacy Guard v2 (gnupg) installed.\n" >&2
    exit 1
fi

declare SDN
SDN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# declare SBN
# SBN="$(basename "$(realpath "${BASH_SOURCE[0]}")")"

DB="${1:-git.sqlite}"

if [[ "${DB}" != *.sqlite ]]; then
    DB="${SDN}/${DB}.sqlite"
else
    DB="${SDN}/${DB}"
fi

echo -ne " This script will:\n \
 1. Make a ${DB##*/} file ... \n \
 2. encrypt it to ${DB##*/}.pgp \n \
 3. Execute bashpass.sh ${DB##*/} \n"

echo -ne "Continue? [Y/n]: "
read -r resp

[[ ${resp:-y} == [Nn]* ]] && exit 1

#gpg2 --batch --yes --quiet --default-recipient-self --output "${DB}.asc" --encrypt "${DB}"
sqlite3 "${DB}" < ac.sql && gpg2 --default-recipient-self --output "${DB}.pgp" --encrypt "${DB}" && "${SDN}/bashpass.sh" "${DB##*/}" && echo -ne "From now on you'll be able to call bashpass.sh with: bashpass.sh ${DB##*/}\n" >&2
