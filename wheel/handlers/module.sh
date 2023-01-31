#!/usr/bin/env bash

function wheel::handlers::ok() {
    [ "$CURRENT_SCREEN" = "$EXIT_SCREEN" ] && return 1
    wheel::stack::push "${next_screen:-""}"
}

function wheel::handlers::cancel() {
    if [ -n "$back_screen" ]; then
        wheel::stack::push "$back_screen"
        return 0
    fi
    if wheel::stack::empty && [ -n "$EXIT_SCREEN" ]; then
        wheel::stack::push "$EXIT_SCREEN"
        return 0
    fi
    wheel::stack::pop
}

function wheel::handlers::noop() {
    wheel::log::debug "No-op handler called for $CURRENT_SCREEN"
}

function wheel::handlers::capture_into() {
    local arg=${1:-"arg"}
    wheel::state::set "${capture_into:?}" "${value:-""}" "$arg"
}

function wheel::handlers::clear_capture() {
    wheel::state::del "$capture_into"
}

function wheel::handlers::capture_into::argjson() {
    wheel::handlers::capture_into argjson
}

function wheel::handlers::flag() {
    local toggle=true
    if [ "${returncode:-0}" -eq 1 ]; then
        toggle=false
    fi
    wheel::state::set "$capture_into" "$toggle" argjson
}

function wheel::handlers::esc() {
    if [ "$CURRENT_SCREEN" = "$EXIT_SCREEN" ]; then
        wheel::stack::pop
        return 0
    fi
    wheel::stack::push "$EXIT_SCREEN"
}

function wheel::handlers::error() {
    wheel::stack::pop
    wheel::stack::push "$ERROR_SCREEN"
}