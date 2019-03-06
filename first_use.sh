#!/usr/bin/env bash

SDN="$(cd $(dirname ${BASH_SOURCE[0]})&& pwd)"

sqlite3 git.db3 < ac.sql

gpg2 --batch --yes --quiet --encrypt --default-recipient-self --output git.db3.asc git.db3

./bashpass.sh
