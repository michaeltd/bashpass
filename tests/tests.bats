#!/usr/bin/env -S bats --tap

# source "${BATS_TEST_DIRNAME}/bashpass"
# source "bashpass"
# load "bashpass"
# load "${BATS_TEST_DIRNAME}/bashpass"

# $BATS_TEST_FILENAME is the fully expanded path to the Bats test file.
# $BATS_TEST_DIRNAME is the directory in which the Bats test file is located.
# $BATS_TEST_NAMES is an array of function names for each test case.
# $BATS_TEST_NAME is the name of the function containing the current test case.
# $BATS_TEST_DESCRIPTION is the description of the current test case.
# $BATS_TEST_NUMBER is the (1-based) index of the current test case in the test file.
# $BATS_TMPDIR is the location to a directory that may be used to store temporary files.

setup() {
    echo $BATS_TEST_FILENAME
    echo $BATS_TEST_DIRNAME
    echo $BATS_TEST_NAMES
    echo $BATS_TEST_NAME
    echo $BATS_TEST_DESCRIPTION
    echo $BATS_TEST_NUMBER
    echo $BATS_TMPDIR
}

teardown() {
    echo $BATS_TEST_FILENAME
    echo $BATS_TEST_DIRNAME
    echo $BATS_TEST_NAMES
    echo $BATS_TEST_NAME
    echo $BATS_TEST_DESCRIPTION
    echo $BATS_TEST_NUMBER
    echo $BATS_TMPDIR
}

@test "Available Bash major version is greater or equal to 4" {
    run bash -c "echo ${BASH_VERSINFO[0]}"
    [ "$output" -ge "4" ]
}

@test "SQLite3 executable is available in path" {
    run sqlite3 --version
    [ "$status" -eq 0 ]
}

@test "GNU Privacy Guard v2 executable is available in path" {
    run gpg --version
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

@test "Can create a bats SQLite3 database" {
    run sqlite3 "test.sqlite3" < "${BATS_TEST_DIRNAME}/../hlprs/ac.sql"
    [ "$status" -eq 0 ]
}

@test "Can encrypt test SQLite3 to pgp (have default keyring)" {
    run gpg --default-recipient-self --output "test.pgp" --encrypt "test.sqlite3"
    [ "$status" -eq 0 ]
}

@test "Can shred .sqlite3 .pgp test files" {
    run shred --zero --remove {test.sqlite3,test.pgp}
    [ "$status" -eq 0 ]
}
