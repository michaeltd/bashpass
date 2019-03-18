#!/usr/bin/env bash
#
# bashpass/install.sh - Install bashpass.sh

# link free (S)cript (D)ir(N)ame, (B)ase(N)ame, (F)ull (N)ame.
if [[ -L "${BASH_SOURCE[0]}" ]]; then
    declare SDN="$(cd $(dirname $(readlink ${BASH_SOURCE[0]}))&& pwd -P)" SBN="$(basename $(readlink ${BASH_SOURCE[0]}))"
    declare SFN=${SDN}/${SBN}
else
    declare SDN="$(cd $(dirname ${BASH_SOURCE[0]})&& pwd -P)" SBN="$(basename ${BASH_SOURCE[0]})"
    declare SFN="${SDN}/${SBN}"
fi

cd ${SDN}

DB="${1:-git.db3}"

if [[ -x "$(command -v bp-launch.sh)" || -L "${HOME}/bin/bp-launch.sh" || -f "${DB}.asc" ]]; then
    printf " ${SBN} has done its part.\n bp-launch.sh is an executable in your path\n and/or ${DB}.asc is in place.\n Troubleshoot manually by following directions from here:\n http://github.com/michaeltd/bashpass\n" >&2
    exit 1
fi

mkdir ${HOME}/bin

# printf "export PATH+=\":${HOME}/bin\"\n" >> ~/.bashrc
printf " please include a line like this \n 'export PATH+=\":${HOME}/bin\"',\n in your ~/.bashrc equivalent shell initialization file.\n" >&2

export PATH+=":${HOME}/bin"

ln -sf ${SDN}/bp-launch.sh ${HOME}/bin/

sqlite3 "${DB}" < ac.sql

gpg2 --batch --yes --quiet --default-recipient-self --output "${DB}.asc" --encrypt "${DB}"

bp-launch.sh "${DB}"

printf "From now on you'll be able to call bashpass.sh with: bp-launch.sh ${DB}\n" >&2
