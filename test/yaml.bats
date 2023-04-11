#!/usr/bin/env bats

setup() {
    load 'test_helper/common'
    wheel::test::setup
    . wheel/yaml/module.sh
}

@test "wheel::yaml::is_supported" {
    assert wheel::yaml::is_supported
}

@test "wheel::yaml::to_json|from_json" {
    local expected='{"global": {"first": {"part": "value", "second": ["one", "two", "three"]}}}'
    local value=$(echo "$expected" | wheel::yaml::from_json | wheel::yaml::to_json)
    assert [ "$expected"  = "$value" ]
}