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
