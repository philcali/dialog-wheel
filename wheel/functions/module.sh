#!/usr/bin/env bash

function wheel::functions::expand() {
    local condition=$1
    local exit_code=${2:-0}
    [ -z "$condition" ] && return "$exit_code"
    local json_type
    local func
    local args
    json_type=$(wheel::json::get "$condition" " | type" 2>/dev/null) || json_type="string"
    case "$json_type" in
    null) return 0;;
    number) [ "$condition" -ne "0" ] && return 0;;
    boolean) [ "$condition" = "true" ] && return 0;;
    string) [ -n "$condition" ] && echo "$condition" && return 0;;
    array) wheel::json::get "$condition" "[]" -c && return $?;;
    object)
        old_ifs=$IFS
        IFS=$'\n'
        for entry in $(wheel::json::get "$condition" " | to_entries | .[]" -c); do
            func=$(wheel::json::get "$entry" "key")
            [[ "$func" = "!"* ]] && func="wheel::functions::${func/!/}"
            args=$(wheel::json::get "$entry" "value")
            "$func" "$args" && return 0
        done
        IFS=$old_ifs;;
    esac
    return 1
}

function wheel::functions::if() {
    local args
    mapfile -t args <<< "$(wheel::json::get "$1" "[]" -c)"
    if wheel::functions::expand "${args[0]}" 1; then
        wheel::functions::expand "${args[1]}"
    else
        wheel::functions::expand "${args[2]}"
    fi
}

function wheel::functions::join() {
    local rval=""
    local delim
    local input
    local arg
    delim="$(wheel::json::get "$1" "[0]")"
    input=$(wheel::json::get "$1" "[1]")
    for arg in $(wheel::functions::expand "$input"); do
        [ -n "$rval" ] && rval+="$delim"
        rval+="$arg"
    done
    wheel::functions::expand "$rval" 1
}

function wheel::functions::split() {
    local delim
    local elements
    local input
    input=$(wheel::json::get "$1" "[1]")
    input=$(wheel::functions::expand "$input")
    delim="$(wheel::json::get "$1" "[0]")"
    while IFS=$delim read -ra elements; do
        echo "${elements[*]}"
    done <<< "$input"
}

function wheel::functions::ref() {
    local arg
    arg=$(wheel::state::get "$1")
    wheel::functions::expand "$arg" 1
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