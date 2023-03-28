#!/usr/bin/env bash

ACTIVE_DIALOG=""
CLEANUP_QUEUE=()
STATE_CHANGE_QUEUE=()

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

function wheel::events::add_state_change() {
    local action=$1
    wheel::log::debug "Adding $action to state-change"
    STATE_CHANGE_QUEUE+=("$action")
}

function wheel::events::fire() {
    local event_name=$1
    shift
    command -v "wheel::events::$event_name" > /dev/null && "wheel::events::$event_name" "$@"
}

function wheel::events::state_change() {
    for action in "${STATE_CHANGE_QUEUE[@]}"; do
        "$action" "$@"
        wheel::log::info "Invoked '$action' with exit code $?"
    done
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