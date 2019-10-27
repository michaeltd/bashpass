function gpw {
    echo $(tr -dc '[:alnum:]~!@#$%^_+:?' < /dev/urandom|head -c "${1:-64}")
}

function rids {
    echo $(${DCM[@]} "SELECT rowid FROM ${ACT} ORDER BY rowid ASC;")
}

function maxid {
    echo $(${DCM[@]} "SELECT MAX(rowid) FROM ${ACT};")
}

function rcount {
    echo $(${DCM[@]} "SELECT COUNT(rowid) FROM ${ACT};")
}

function brl {
    for R in $(rids); do
        local DM=$(${DCM[@]} "SELECT dm FROM ${ACT} WHERE rowid = '${R}';"|sed 's/ /-/g')
        local EM=$(${DCM[@]} "SELECT em FROM ${ACT} WHERE rowid = '${R}';"|sed 's/ /-/g')
        local RL+="${R} ${DM:-null}:${EM:-null} off "
    done
    echo ${RL[@]}
}
