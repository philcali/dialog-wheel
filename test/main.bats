#!/usr/bin/env bats

setup() {
    load 'test_helper/common'
    wheel::test::setup
    . wheel/constants.sh
}

@test "wheel::main -h" {
    run ./wheel/main.sh -h
    [ "$status" -eq 0 ]
}

@test "wheel::main -v" {
    run ./wheel/main.sh -v
    [ "$status" -eq 0 ]
    [ "$output" = "$VERSION" ]
}