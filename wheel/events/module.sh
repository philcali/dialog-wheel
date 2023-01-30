#!/usr/bin/env bash

ACTIVE_DIALOG=""
CLEANUP_QUEUE=()

function wheel::events::trap_exit() {
    # TODO: properly handle gauges
    if [ -n "$EXIT_SCREEN" ] && [ "$EXIT_SCREEN" != "$CURRENT_SCREEN" ]; then
        wheel::stack::push "$EXIT_SCREEN"
    else
        CURRENT_SCREEN="null"
    fi
    wheel::events::kill_active_dialog    
}

function wheel::events::kill_active_dialog() {
    # TODO: properly handle gauges
    if [ -n "$ACTIVE_DIALOG" ]; then
        kill "$ACTIVE_DIALOG"
    fi
}

function wheel::events::add_clean_up() {
    local action=$1
    wheel::log::debug "Adding $action to clean-up"
    CLEANUP_QUEUE+=("$action")
}

function wheel::events::clean_up() {
    for action in "${CLEANUP_QUEUE[@]}"; do
        eval "$action"
        wheel::log::info "Invoked '$action' with exit code $?"
    done
}

function wheel::events::set_traps() {
    trap "wheel::events::trap_exit" "$SIG_INT"
    # This appears to be breaking things in newer versions of dialog
    # trap "wheel::events::kill_active_dialog" WINCH
    trap "wheel::events::clean_up" EXIT
}