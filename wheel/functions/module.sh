#!/usr/bin/env bash

function wheel::functions::expand() {
    local condition=$1
    [ -z "$condition" ] && return 0
    local json_type
    local func
    local args
    json_type=$(wheel::json::get "$condition" " | type" 2>/dev/null) || json_type="string"
    case "$json_type" in
    null) return 0;;
    number) [ "$condition" -ne "0" ] && return 0;;
    boolean) [ "$condition" = "true" ] && return 0;;
    string) [ "$(wheel::state::interpolate "$condition")" = "true" ] && return 0;;
    object)
        wheel::log::info "$(wheel::json::get "$condition" " | to_entries | .[]" -c)"
        for entry in $(wheel::json::get "$condition" " | to_entries | .[]" -c); do
            func=$(wheel::json::get "$entry" "key")
            [[ "$func" = "!"* ]] && func="wheel::functions::${func/!/}"
            args=$(wheel::json::get "$entry" "value")
            wheel::log::info "key is $func and value is $args"
            "$func" "$args" && return 0
        done;;
    esac
    return 1
}

function wheel::functions::not() {
    ! wheel::functions::expand "$(wheel::json::get "$1" "[0]")"
}

function wheel::functions::or() {
    local args
    mapfile -t args <<< "$(wheel::json::get "$1" "[]" -c)"
    wheel::functions::expand "${args[0]}" || wheel::functions::expand "${args[1]}"
}

function wheel::functions::and() {
    local args
    mapfile -t args <<< "$(wheel::json::get "$1" "[]" -c)"
    wheel::functions::expand "${args[0]}" && wheel::functions::expand "${args[1]}"
}

function wheel::functions::eval() {
    local args
    mapfile -t args <<< "$(wheel::json::get "$1" "[]" -c)"
    # TODO: replace with when other evaluations exist
    "${args[@]}"
}