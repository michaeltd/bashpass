#~/bashpass/common.sh
#
# bashpass/common.sh Common functions.

clean_up() {

    gpg2 --batch --yes --quiet --default-recipient-self --output "${DB}.asc" --encrypt "${DB}"

    shred --verbose --zero --remove --iterations=30 "${DB}"

    shred --verbose --zero --remove --iterations=30 "${TF}"

    rm -f "${MUTEX}"
}

# No mutex or die.
check_mutex() {

    if [[ -f "${MUTEX}" ]]
    then

        printf "${bold}You can only have one instance of ${SBN}.${reset}\n \
               Follow the instructions from here:\n \
               ${underline}https://github.com/michaeltd/bashpass${reset}\n" >&2
        return 1
    fi
}

# Decrypt db3, setup trap and mutex or die.
check_decrypt() {

    if ! gpg2 --batch --yes --quiet --default-recipient-self --output "${DB}" --decrypt "${DB}.asc"
    then

        printf "${bold}Decryption failed.${reset}\n \
               Follow the instructions from here:\n \
               ${underline}https://github.com/michaeltd/bashpass${reset}\n" >&2
        return 1
    else

        touch "${MUTEX}"

        # trap needs to be here as we need at least a decrypted db and a mutex file to cleanup
        trap clean_up $SIG_NONE $SIG_HUP $SIG_INT $SIG_QUIT $SIG_TERM
    fi
}

# SQL or die.
check_sql() {

    if ! ${DCM[@]} "SELECT * FROM ${ACT} ORDER BY rowid ASC;" &> /dev/null
    then

        printf "${bold}Need a working db to function.${reset}\n \
               Follow the instructions from here:\n \
               ${underline}https://github.com/michaeltd/bashpass${reset}\n" >&2
        return 1
    fi
}

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
