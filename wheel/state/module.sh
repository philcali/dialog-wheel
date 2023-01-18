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

    wheel::json::get_or_default "$APP_STATE" "$key" ""
}

function wheel::state::set() {
    local key=$1
    local value=$2

    local state; state=$(wheel::json::set "$APP_STATE" "$key" "$value")
    wheel::log::debug "Setting state to: $state"
    APP_STATE=$state
}