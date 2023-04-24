#!/usr/bin/env bats

setup() {
    load 'test_helper/common'
    wheel::test::setup
    . wheel/constants.sh
    . wheel/state/module.sh
    . wheel/events/module.sh
    . wheel/log/module.sh
    . wheel/utils/module.sh
    . wheel/json/module.sh
    . wheel/functions/module.sh
}

@test "wheel::functions::if" {
    local actual
    wheel::state::set "some.flag" "true"
    actual="$(wheel::functions::if '[{"!ref": "some.flag"}, "It is true", "It is false"]')"
    assert [ "$actual" = "It is true" ]
    wheel::state::set "some.flag" "false"
    actual="$(wheel::functions::if '[{"!ref": "some.flag"}, "It is true", "It is false"]')"
    assert [ "$actual" = "It is false" ]
}

@test "wheel::functions::split" {
    local actual
    wheel::state::set "some.numbers" "1+2+3+4+5"
    actual="$(wheel::functions::split '["+", {"!ref": "some.numbers"}]')"
    assert [ "$actual" = "1 2 3 4 5" ]
    # round trip
    actual="$(wheel::functions::join '["+", {"!split": ["+", {"!ref": "some.numbers"}]}]')"
    assert [ "$actual" = "1+2+3+4+5" ]
}

@test "wheel::functions::join" {
    local actual
    wheel::state::set "some.array" "[1, 2, 3, 4, 5]"
    actual="$(wheel::functions::join '["+", {"!ref": "some.array"}]' )"
    assert [ "1+2+3+4+5" = "$actual" ]
    actual="$(wheel::functions::join '["+", [1, 2, 3, 4, 5]]')"
    assert [ "1+2+3+4+5" = "$actual" ]
}

@test "wheel::functions::not" {
    assert wheel::functions::not '[{"!ref": "some.flag"}]'
    wheel::state::set "some.flag" "true"
    refute wheel::functions::not '[{"!ref": "some.flag"}]'
    wheel::state::set "some.flag" "false"
    assert wheel::functions::not '[{"!ref": "some.flag"}]'
}

@test "wheel::functions::or" {
    wheel::state::set "some.one" "false"
    wheel::state::set "some.two" "true"
    assert wheel::functions::or '[{"!ref": "some.one"}, {"!ref": "some.two"}]'
    refute wheel::functions::or '[{"!ref": "some.one"}, {"!not": [{"!ref": "some.two"}]}]'
}

@test "wheel::functions::and" {
    wheel::state::set "some.one" "true"
    wheel::state::set "some.two" "true"
    assert wheel::functions::and '[{"!ref": "some.one"}, {"!ref": "some.two"}]'
    refute wheel::functions::and '[{"!ref": "some.one"}, {"!not": [{"!ref": "some.two"}]}]'
}

@test "wheel::functions::eval" {
    assert wheel::functions::eval '["date"]'
}