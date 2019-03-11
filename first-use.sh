#!/usr/bin/env bash

SDN="$(cd $(dirname ${BASH_SOURCE[0]})&& pwd)"

cd ${SDN}

DB="${1:-git.db3}"

sqlite3 "${DB}" < ac.sql

gpg2 --batch --yes --quiet --default-recipient-self --output "${DB}.asc" --encrypt "${DB}"

./bashpass.sh "${DB}"
