#!/usr/bin/env bash

function wheel::json::get() {
    local map=$1
    local key=$2
    echo "$map" | jq -r ".$key"
}

function wheel::json::get_or_default() {
    local map=$1
    local key=$2
    local default_value=$3
    local value; value=$(wheel::json::get "$map" "$key")
    if [ "$value" = "null" ]; then
        echo "$default_value"
    else
        echo "$value"
    fi
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