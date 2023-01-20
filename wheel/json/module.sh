#!/usr/bin/env bash

function wheel::json::get() {
    local map=$1
    local key=$2
    shift 2
    local rest=("$@" ".$key")
    echo "$map" | jq -r "${rest[@]}"
}

function wheel::json::is_null() {
    [ -z "$1" ] || [ "$1" = "null" ]
}

function wheel::json::set() {
    local map=$1
    local key=$2
    local value=$3
    local argtype=${4:-"arg"}

    echo "$map" | jq --"$argtype" value "$value" ". | setpath(path(.$key); \$value)"
}

function wheel::json::del() {
    local map=$1
    local key=$2
    echo "$map" | jq ". | del(.$key)"
}

function wheel::json::get_or_default() {
    local map=$1
    local key=$2
    local default_value=$3
    shift 3
    local value; value=$(wheel::json::get "$map" "$key" "$@")
    if  wheel::json::is_null "$value"; then
        echo "$default_value"
    else
        echo "$value"
    fi
}

function wheel::json::validate() {
    local input=$1
    local msg; msg=$(echo "$input" | jq 2>&1)
    # validation error code
    if [ $? -eq 4 ]; then
        echo "$msg"
        return 1
    fi
    return 0
}

function wheel::json::read() {
    while read -r line
    do
        echo "$line"
    done < "$1"
    if [ -n "$line" ]; then
        echo "$line"
    fi
}