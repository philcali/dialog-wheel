#!/usr/bin/env bats

setup() {
    load 'test_helper/common'
    wheel::test::setup
    . wheel/handlers/module.sh
    . wheel/stack/module.sh
    CURRENT_SCREEN="first"
    wheel::stack::push "current"
    EXIT_SCREEN="exit"
    ERROR_SCREEN="error"
}

@test "wheel::handlers::ok" {
    next_screen="some value"
    EXIT_SCREEN=""
    assert wheel::handlers::ok
    EXIT_SCREEN="some value"
    refute wheel::handlers::ok
}

@test "wheel::handlers::cancel" {
    back_screen="previous"
    wheel::handlers::cancel
    assert [ "$CURRENT_SCREEN" = "$back_screen" ]
    unset back_screen
    wheel::handlers::cancel
    assert [ "$CURRENT_SCREEN" = "current" ]
    wheel::stack::clear
    wheel::handlers::cancel
    assert [ "$CURRENT_SCREEN" = "exit" ]

}

@test "wheel::handlers::capture_into" {
    function wheel::state::set() {
        [ "$1" = "capture_into" ] && [ "$2" = "value" ]
    }
    capture_into="capture_into"
    value="value"
    assert wheel::handlers::capture_into
}

@test "wheel::handlers::esc" {
    wheel::handlers::esc
    assert [ "$CURRENT_SCREEN" = "exit" ]
    wheel::handlers::esc
    assert [ "$CURRENT_SCREEN" = "current" ]
}

@test "wheel::handlers::error" {
    # assumes that "CURRENT_SCREEN" failed
    wheel::handlers::error
    assert [ "$CURRENT_SCREEN" = "error" ]
    wheel::handlers::cancel
    assert [ "$CURRENT_SCREEN" = "first" ]
}

@test "wheel::handlers::clear_capture" {
    function wheel::state::del() {
        [ "$1" = "capture_into" ]
    }
    capture_into="capture_into"
    assert wheel::handlers::clear_capture
}