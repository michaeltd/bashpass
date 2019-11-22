#!/usr/bin/env bash
#
# bashpass/install.sh - Install bashpass.sh

if [[ ! -t 1 ]]; then
    echo "You'll need to run $0 in a terminal"
    exit 1
fi

[[ ! $(command -v sqlite3) ]] && printf "You need SQLite3 installed.\n" >&2 && exit 1

[[ ! $(command -v gpg2) ]] && printf "You need GNU Privacy Guard v2 (gnupg) installed.\n" >&2 && exit 1

# link free (S)cript (D)ir(N)ame, (B)ase(N)ame, (F)ull (N)ame.
# if [[ -L "${BASH_SOURCE[0]}" ]]; then
#     declare SDN="$(cd $(dirname $(readlink ${BASH_SOURCE[0]}))&& pwd -P)"
#     declare SBN="$(basename $(readlink ${BASH_SOURCE[0]}))"
# else
#     declare SDN="$(cd $(dirname ${BASH_SOURCE[0]})&& pwd -P)"
#     declare SBN="$(basename ${BASH_SOURCE[0]})"
# fi
# Via `realpath` as no need for link checking.
declare SDN="$(cd $(dirname $(realpath ${BASH_SOURCE[0]})) && pwd -P)"
declare SBN="$(basename $(realpath ${BASH_SOURCE[0]}))"

DB="${1:-git.db3}"

if [[ "${DB}" != *.db3 && "${DB}" != *.sqlite ]]; then
    DB="${SDN}/${DB}.sqlite"
else
    DB="${SDN}/${DB}"
fi

printf " This script will:\n \
 1. Make a ${DB##*/} file ... \n \
 2. encrypt it to ${DB##*/}.asc \n \
 3. Execute bashpass.sh ${DB##*/} \n"

read -p "Continue? [Y/n]:" resp

[[ ${resp:-y} == [Nn]* ]] && exit 1

sqlite3 "${DB}" < ac.sql

#gpg2 --batch --yes --quiet --default-recipient-self --output "${DB}.asc" --encrypt "${DB}"
gpg2 --default-recipient-self --output "${DB}.asc" --encrypt "${DB}"

${SDN}/bashpass.sh "${DB##*/}"

printf "From now on you'll be able to call bashpass.sh with: bashpass.sh %s\n" "${DB##*/}" >&2
