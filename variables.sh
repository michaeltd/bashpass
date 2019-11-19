#~/bashpass/variables.sh
#
# bashpass/variables.sh Common variables.

# Xdialog/dialog
export XDIALOG_HIGH_DIALOG_COMPAT=1 XDIALOG_FORCE_AUTOSIZE=1 XDIALOG_INFOBOX_TIMEOUT=5000 XDIALOG_NO_GMSGS=1
declare DIALOG_OK=0 DIALOG_CANCEL=1 DIALOG_HELP=2 DIALOG_EXTRA=3 DIALOG_ITEM_HELP=4 DIALOG_ESC=255
declare SIG_NONE=0 SIG_HUP=1 SIG_INT=2 SIG_QUIT=3 SIG_KILL=9 SIG_TERM=15

# Temp files
declare TF="${SDN}/.${RANDOM}.${$}"
declare MUTEX="${SDN}/.${SBN}.MUTEX"

# SQLite
declare DB="${DB:-${SDN}/git.db3}" ACT="ac"
declare -a DCM="sqlite3 ${DB}" RCM="sqlite3 -line ${DB}" CCM="sqlite3 -csv ${DB}"

# Build menus and help messages.
declare -a TUI_OPS=( "${red}Create  ${reset}" \
                         "${green}Retrieve${reset}" \
                         "${blue}Update  ${reset}" \
                         "${yellow}Delete  ${reset}" \
                         "${magenta}CSV     ${reset}" \
                         "${cyan}SQLite3 ${reset}" \
                         "${black}Help    ${reset}" \
                         "${grey}Quit    ${reset}" )

declare -a GUI_OPS=( "Create" "Retrieve" "Update" "Delete" "CSV" "SQLite3" "Help" "Quit" )

declare -a SDESC=( "New entry" \
                       "Find account" \
                       "Regen password" \
                       "Remove entry" \
                       "Import a file" \
                       "sqlite3 session" \
                       "Help screen" \
                       "Exit" )

declare -a DESC=( "gather details for a new account." \
                      "search records by domain. (empty for all)" \
                      "regenerate an existing password." \
                      "remove an account." \
                      "prompt for csv file to import(eg:test.csv)." \
                      "start an sqlite session against ${DB/*\/}." \
                      "Show this message" \
                      "Quit this application." )

declare -a TUI_MENU=() # PRompt
declare -a TUI_HMSG="\nUsage: ${SBN} [some.db3] [Xdialog|dialog|terminal]\n\n" # Terminal Help Message
declare -a GUI_MENU=() # Menu Text
declare -a GUI_HMSG="\nUsage: ${SBN} [some.db3] [Xdialog|dialog|terminal]\n\n" # Help Message

for (( x = 0; x < ${#TUI_OPS[@]}; x++ )); do
    TUI_MENU+="${x}:${TUI_OPS[$x]}"; (( ( x + 1 ) % 4 == 0 )) && TUI_MENU+="\n" || TUI_MENU+="\t"
    TUI_HMSG+="Use ${bold}${x}${reset}, for ${TUI_OPS[$x]}, which will ${bold}${DESC[$x]}${reset}\n"
    GUI_MENU+="${GUI_OPS[$x]}|${SDESC[$x]}|${DESC[$x]}|"
    GUI_HMSG+="Use ${GUI_OPS[$x]}, to ${DESC[$x]}\n"
done

TUI_MENU+="${bold}Choose[0-$((${#TUI_OPS[@]}-1))]:${reset}"
TUI_HMSG+="\naccounts table format is as follows:\nCREATE TABLE ac(dm VARCHAR(100),em VARCHAR(100),un VARCHAR(100),pw VARCHAR(256),cm VARCHAR(100));\n"
GUI_HMSG+="\naccounts table format is as follows:\nCREATE TABLE ac(dm VARCHAR(100),em VARCHAR(100),un VARCHAR(100),pw VARCHAR(256),cm VARCHAR(100));\n"
