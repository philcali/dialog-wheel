#!/usr/bin/env bats

setup() {
    load 'test_helper/common'
    wheel::test::setup
}

@test "wheel::utils::in_array" {
    . wheel/utils/module.sh

    local -a arr=("elem1" "elem2" "elem3")
    assert wheel::utils::in_array arr "elem2"
    refute wheel::utils::in_array arr "elem4"
}