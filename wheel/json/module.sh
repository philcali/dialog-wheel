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

function wheel::json::merge() {
    local parent=$1
    local child=$2
    local field
    shift 2
    local fields=("$@")
    local expanded_filter=""
    local expanded_merge=""
    local length="${#fields[@]}"
    if [ "$length" -eq 0 ]; then
        mapfile -t fields < <(wheel::json::get "$parent" ". as \$self | keys | .[] | select(. != \"screens\") | select(\$self[.] | type == \"object\")")
        length="${#fields[@]}"
    fi
    if [ "$length" -eq 0 ]; then
        wheel::json::get "$parent" "screens[\$screen]" --arg screen "$child"
        return 0
    fi
    for index in "${!fields[@]}"; do
        field="${fields[$index]}"
        expanded_filter+="{} + .$field + .screens[\$screen].$field"
        expanded_merge+="\"$field\": .[$index]"
        if [ "$index" -lt "$((length - 1))" ]; then
            expanded_filter+=", "
            expanded_merge+=", "
        fi
    done
    wheel::log::trace "Merge merge expression:" "filter [$expanded_filter]" "reducer {$expanded_merge}"
    wheel::json::get "$parent" " as \$self | [$expanded_filter] | \$self.screens[\$screen] + {$expanded_merge}" --arg screen "$child"
}

function wheel::json::validate() {
    local input=$1
    local msg; msg=$(echo "$input" | jq 2>&1)
    # validation error code
    if [ $? -eq 4 ]; then
        echo "$msg" >&2
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