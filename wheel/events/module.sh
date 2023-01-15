#!/usr/bin/env bash

ACTIVE_DIALOG=""

function wheel::events::trap_exit() {
    # TODO: properly handle gauges
    if [ -n "$EXIT_SCREEN" ] && [ "$EXIT_SCREEN" != "$CURRENT_SCREEN" ]; then
        wheel::stack::push "$EXIT_SCREEN"
    else
        CURRENT_SCREEN="null"
    fi
    kill "$ACTIVE_DIALOG"
}

function wheel::events::trap_resize() {
    # TODO: properly handle gauges
    if [ -n "$ACTIVE_DIALOG" ]; then
        kill "$ACTIVE_DIALOG"
    fi
}

function wheel::events::set_traps() {
    trap "wheel::events::trap_exit" "$SIG_INT"
    trap "wheel::events::trap_resize" WINCH
}