#!/usr/bin/env bats

source "${BATS_TEST_DIRNAME}/bashpass"

@test "Available Bash major version is greater or equal to 4" {
    run bash -c "echo ${BASH_VERSINFO[0]}"
    [ "$output" -ge 4 ]
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
    run gpw 64
    [ "${#output}" -eq 64 ]
    run gpw 32
    [ "${#output}" -eq 32 ]
    run gpw 16
    [ "${#output}" -eq 16 ]
}
