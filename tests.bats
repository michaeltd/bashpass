#!/bin/env bats

@test "Testing dependencies" {
   echo stocks
}


@test "Check that the SQLite3 is available" {
    command -v sqlite3
}

@test "Check that the GPG2 is available" {
    command -v gpg2
}

