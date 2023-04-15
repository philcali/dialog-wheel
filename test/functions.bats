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

@test "wheel::functions::not" {
    wheel::state::set "some.flag" "true"
    refute wheel::functions::not '["$state.some.flag"]'
    wheel::state::set "some.flag" "false"
    assert wheel::functions::not '["$state.some.flag"]'
}

@test "wheel::functions::or" {
    wheel::state::set "some.one" "false"
    wheel::state::set "some.two" "true"
    assert wheel::functions::or '["$state.some.one", "$state.some.two"]'
    refute wheel::functions::or '["$state.some.one", {"!not": ["$state.some.two"]}]'
}

@test "wheel::functions::and" {
    wheel::state::set "some.one" "true"
    wheel::state::set "some.two" "true"
    assert wheel::functions::and '["$state.some.one", "$state.some.two"]'
    refute wheel::functions::and '["$state.some.one", {"!not": ["$state.some.two"]}]'
}

@test "wheel::functions::eval" {
    wheel::state::set "some.flag" "false"
    assert wheel::functions::eval '["date"]'
}