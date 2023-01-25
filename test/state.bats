#!/usr/bin/env bats

setup() {
    load 'test_helper/common'
    wheel::test::setup
    . wheel/constants.sh
    . wheel/state/module.sh
    . wheel/log/module.sh
}

@test "wheel::state::init" {
    . wheel/json/module.sh
    TMP_FILE=$(mktemp)
    trap "rm -rf $TMP_FILE" EXIT
    echo '{"field": "value", "name": "My Name"}' > $TMP_FILE
    assert [ "$APP_STATE" = "{}" ] 
    wheel::state::init $TMP_FILE
    assert [ "$APP_STATE" = '{"field": "value", "name": "My Name"}' ]
}

@test "wheel::state::set_output" {
    assert [ "$OUTPUT_PATH" = "state.json" ]
    wheel::state::set_output "new-state.json"
    assert [ "$OUTPUT_PATH" = "new-state.json" ]
}

@test "wheel::state::get" {
    function wheel::json::get_or_default() {
        [ "$1" = "$APP_STATE" ] && \
        [ "$2" = "field" ] && \
        [ -z "$3" ] && \
        [ "$4" = "-c" ]
    }

    assert wheel::state::get "field" -c
}

@test "wheel::state::set" {
    function wheel::json::set() {
        echo '{"field": "new value"}'
        [ "$1" = "$APP_STATE" ] && \
        [ "$2" = "field" ] && \
        [ "$3" = "new value" ]
    }

    assert wheel::state::set "field" "new value"
    assert [ "$APP_STATE" = '{"field": "new value"}' ]
}

@test "wheel::state::del" {
    function wheel::json::del() {
        [ "$1" = "$APP_STATE" ] && [ "$2" = "field" ]
    }

    assert wheel::state::del "field"
}