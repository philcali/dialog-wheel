#!/usr/bin/env bash

APP_STATE="{}"
OUTPUT_PATH="state.json"

function wheel::state::init() {
    local source=$1
    local state_source; state_source=$(wheel::json::read "$source")
    local msg; msg=$(wheel::json::validate "$state_source")
    if [ $? -eq 1 ]; then
        echo "json error: $msg" > /dev/stderr
        exit 1
    fi
    APP_STATE=$state_source
}

function wheel::state::set_output() {
    OUTPUT_PATH=$1
}

function wheel::state::flush() {
    echo "$APP_STATE" > $OUTPUT_PATH
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