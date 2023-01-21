#!/usr/bin/env bats

setup() {
    load 'test_helper/common'
    wheel::test::setup
    . wheel/stack/module.sh

    CURRENT_SCREEN="current"
    SCREEN_STACK=("first" "second" "third")
}

@test "wheel::stack::push" {
    wheel::stack::push "zero"
    assert [ "$CURRENT_SCREEN" = "zero" ]
    assert [ "${SCREEN_STACK[*]}" = "current first second third" ]
}

@test "wheel::stack::pop" {
    wheel::stack::pop
    assert [ "$CURRENT_SCREEN" = "first" ]
    assert [ "${SCREEN_STACK[*]}" = "second third" ]
}

@test "wheel::stack::clear" {
    wheel::stack::clear
    assert [ "${SCREEN_STACK[*]}" = "" ]
}

@test "wheel::stack::empty" {
    refute wheel::stack::empty
    SCREEN_STACK=()
    assert wheel::stack::empty
}