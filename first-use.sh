#!/usr/bin/env bash

SDN="$(cd $(dirname ${BASH_SOURCE[0]})&& pwd)"

cd ${SDN}

sqlite3 git.db3 < ac.sql

gpg2 --batch --yes --quiet --default-recipient-self --output git.db3.asc --encrypt git.db3

./bashpass.sh
