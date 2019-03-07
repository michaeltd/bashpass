#!/usr/bin/env bash

SDN="$(cd $(dirname ${BASH_SOURCE[0]})&& pwd)"

TRM=$(which terminology||which st||which konsole||which gnome-terminal||which xfce-4-terminal||which terminator||which sakura||which termite||which tilix||which urxvt||which xterm)

${TRM} -e "${SDN}/bashpass.sh" "${@}" &
