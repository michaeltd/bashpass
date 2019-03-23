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

if [[ "${DB}" != "*.db3" ]]; then
    DB+=".db3"
fi


printf "  This script will:\n \
  1. Make a \${HOME}/bin dir if there isn't one. \n \
  2. Update your \$PATH env var with your ~/bin dir in ~/.bashrc \n \
  3. Update your current \$PATH \n \
  4. Link bp-launch.sh in ~/bin \n \
  5. Make a ${DB} file ... \n \
  6. encrypt it to ${DB}.asc \n \
  7. Execute bp-launch.sh ${DB} \n"

read -p "Continue? [Y/n]:" resp

[[ ${resp:-y} == [Nn]* ]] && exit 1

mkdir ${HOME}/bin

printf "export PATH+=\":${HOME}/bin\"\n" >> ~/.bashrc

export PATH+=":${HOME}/bin"

ln -sf ${SDN}/bp-launch.sh ${HOME}/bin/

sqlite3 "${DB}" < ac.sql

gpg2 --batch --yes --quiet --default-recipient-self --output "${DB}.asc" --encrypt "${DB}"

bp-launch.sh "${DB}"

printf "From now on you'll be able to call bashpass.sh with: bp-launch.sh ${DB}\n" >&2
