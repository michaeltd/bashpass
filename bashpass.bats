#!/usr/bin/env -S bats --tap

@test "Available Bash major version is greater or equal to 4" {
    run bash -c "echo ${BASH_VERSINFO[0]}"
    [ "$output" -ge "4" ]
}

@test "Have SQLite3, GNU Privacy Guard and Shellcheck executables available in path" {
    run sqlite3 --version
    [ "$status" -eq 0 ]
    run gpg --version
    [ "$status" -eq 0 ]
    run shellcheck --version
    [ "$status" -eq 0 ]
}

@test "GenPassWord output is according to input" {
    skip
    run gpw 64
    [ "${#output}" -eq 64 ]
    run gpw 32
    [ "${#output}" -eq 32 ]
    run gpw 16
    [ "${#output}" -eq 16 ]
}

@test "Can create a ${BATS_TEST_FILENAME##*/} SQLite3 database" {
    run sqlite3 "${BATS_TEST_DIRNAME}/databases/${BATS_TEST_FILENAME##*/}.sqlite3" < "${BATS_TEST_DIRNAME}/examples/create.sql"
    [ "$status" -eq 0 ]
}

@test "Can encrypt ${BATS_TEST_FILENAME##*/}'s SQLite3 to pgp (have default keyring)" {
    run gpg --default-recipient-self --output "${BATS_TEST_DIRNAME}/databases/${BATS_TEST_FILENAME##*/}.pgp" --encrypt "${BATS_TEST_DIRNAME}/databases/${BATS_TEST_FILENAME##*/}.sqlite3"
    [ "$status" -eq 0 ]
}

@test "Can shred ${BATS_TEST_FILENAME##*/}'s .sqlite3 .pgp files" {
    run shred --zero --remove ${BATS_TEST_DIRNAME}/databases/{${BATS_TEST_FILENAME##*/}.pgp,${BATS_TEST_FILENAME##*/}.sqlite3}
    [ "$status" -eq 0 ]
}

@test "Does bashpass checks out with shellcheck" {
    run shellcheck bashpass
    [ "$status" -eq 0 ]
}
