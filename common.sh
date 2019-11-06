# Generate PassWord
gpw() {
    echo $(tr -dc '[:alnum:]~!@#$%^_+:?' < /dev/urandom|head -c "${1:-64}")
}

#RowID'S
rids() {
    echo $(${DCM[@]} "SELECT rowid FROM ${ACT} ORDER BY rowid ASC;")
}

# -.-
maxid() {
    echo $(${DCM[@]} "SELECT MAX(rowid) FROM ${ACT};")
}

#Row count
rcount() {
    echo $(${DCM[@]} "SELECT COUNT(rowid) FROM ${ACT};")
}

#Build Row Lines (for (X)dialog check/radio lists)
brl() {
    for i in $(rids); do
        local dm=$(${DCM[@]} "SELECT dm FROM ${ACT} WHERE rowid = '${i}';"|sed 's/ /-/g')
        local em=$(${DCM[@]} "SELECT em FROM ${ACT} WHERE rowid = '${i}';"|sed 's/ /-/g')
        local rl+="${i} ${dm:-null}:${em:-null} off "
    done
    echo ${rl[@]}
}
