#!/usr/bin/env -S bats --tap

@test "Available Bash major version is greater or equal to 4?" {
    run bash -c "echo ${BASH_VERSINFO[0]}"
    [ "$output" -ge "4" ]
}

@test "Have we SQLite3, GNU Privacy Guard and Shellcheck executables available in path?" {
    run sqlite3 --version
    [ "$status" -eq 0 ]
    run gpg --version
    [ "$status" -eq 0 ]
    run shellcheck --version
    [ "$status" -eq 0 ]
}

@test "GenPassWord output is according to input?" {
    skip
    run gpw 64
    [ "${#output}" -eq 64 ]
    run gpw 32
    [ "${#output}" -eq 32 ]
    run gpw 16
    [ "${#output}" -eq 16 ]
}

@test "Can we create a ${BATS_TEST_FILENAME##*/} SQLite3 database?" {
    run sqlite3 "${BATS_TEST_DIRNAME}/dbs/${BATS_TEST_FILENAME##*/}.sl3" < "${BATS_TEST_DIRNAME}/examples/create.sql"
    [ "$status" -eq 0 ]
}

@test "Can we encrypt ${BATS_TEST_FILENAME##*/}'s SQLite3 to gpg (have default keyring)?" {
    run gpg --default-recipient-self --output "${BATS_TEST_DIRNAME}/dbs/${BATS_TEST_FILENAME##*/}.gpg" --encrypt "${BATS_TEST_DIRNAME}/dbs/${BATS_TEST_FILENAME##*/}.sl3"
    [ "$status" -eq 0 ]
}

@test "Can we shred ${BATS_TEST_FILENAME##*/}'s .sl3 .gpg files?" {
    run shred --zero --remove ${BATS_TEST_DIRNAME}/dbs/{${BATS_TEST_FILENAME##*/}.gpg,${BATS_TEST_FILENAME##*/}.sl3}
    [ "$status" -eq 0 ]
}

@test "Does shellcheck approve bashpass and source files?" {
    run shellcheck bashpass
    [ "$status" -eq 0 ]
    # run shellcheck setup
    # [ "$status" -eq 0 ]
    run shellcheck srcs/*.src
    [ "$status" -eq 0 ]
}
