#!/usr/bin/env bats

setup() {
    load 'test_helper/common'
    wheel::test::setup
    . wheel/json/module.sh
    TMP_FILE=$(mktemp)
    trap "rm -rf $TMP_FILE" EXIT
}

@test "wheel::json::read" {
    local input="{\"key\": \"value\"}"
    echo "$input" > $TMP_FILE
    local output=$(wheel::json::read "$TMP_FILE")
    assert [ "$input" = "$output" ]
}

@test "wheel::json::validate" {
    local input="not a valid JSON value"
    refute wheel::json::validate "$input"
    assert wheel::json::validate "{}"
}