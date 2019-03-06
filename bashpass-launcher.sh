#!/usr/bin/env bash

SDN="$(cd $(dirname ${BASH_SOURCE[0]})&& pwd)"

xterm -e "${SDN}/bashpass.sh" "${@}" &
