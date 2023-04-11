#!/usr/bin/env bash

APP_STATE="{}"
OUTPUT_PATH=""

function wheel::state::init() {
    local source=$1
    APP_STATE=$(wheel::json::read "$source") || return 1
}

function wheel::state::set_output() {
    OUTPUT_PATH=$1
}

function wheel::state::flush() {
    [ "$APP_STATE" != "{}" ] && {
        local path=$OUTPUT_PATH
        if [ -n "$OUTPUT_PATH" ]; then
            wheel::json::write "$APP_STATE" "$OUTPUT_PATH" > "$path"
        # Allow an fd 3 > redirect, since stdout is taken with the dialog
        elif { true >&3; } 2> /dev/null; then
            wheel::json::write "$APP_STATE" "$OUTPUT_PATH" >&3
        fi
    }
}

function wheel::state::get() {
    local key=$1
    shift
    local rest=("$@")

    wheel::json::get_or_default "$APP_STATE" "$key" "" "${rest[@]}"
}

function wheel::state::set() {
    local key=$1
    local value=$2
    shift 2
    local rest=("$@")

    local state
    local previous_value
    previous_value=$(wheel::json::get "$APP_STATE" "$key")
    state=$(wheel::json::set "$APP_STATE" "$key" "$value" "${rest[@]}") || return $?
    wheel::log::debug "Setting state to: $state"
    APP_STATE=$state
    if [ "$previous_value" != "$(wheel::json::get "$state" "$key")" ]; then
        wheel::events::fire "state_change" "$key" "$previous_value"
    fi
}

function wheel::state::del() {
    local key=$1
    local state
    local previous_value
    previous_value=$(wheel::json::get "$APP_STATE" "$key")
    state=$(wheel::json::del "$APP_STATE" "$key") || return $?
    wheel::log::debug "Setting state to: $state"
    APP_STATE=$state
    if [ "$previous_value" != "$(wheel::json::get "$state" "$key")" ]; then
        wheel::events::fire "state_change" "$key" "$previous_value"
    fi
}

function wheel::state::interpolate() {
    local input=$1
    local replacement=${2:-$capture_into}
    # For backwards cap
    if [ -z "$replacement" ]; then
        if [[ "$input" =~ ^\$state. ]]; then
            replacement="${input/"\$state."/}"
        else
            echo "$input" && return 0
        fi
    fi
    local state_value
    state_value="$(wheel::state::get "$replacement")"
    echo "${input//"\$state.$replacement"/$state_value}"
}