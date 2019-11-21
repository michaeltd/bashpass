#!/bin/env bats

@test "Testing dependencies" {
   echo deps
}

@test "Check that SQLite3 is available" {
    command -v sqlite3
}

@test "Check that GPG2 is available" {
    command -v gpg2
}

@test "Check that Xdialog is available" {
    command -v Xdialog
}

@test "Check that dialog is available" {
    command -v dialog
}

