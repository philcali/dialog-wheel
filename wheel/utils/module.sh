#!/usr/bin/env bash

function wheel::utils::in_array() {
    local -n haystack=$1
    local needle=$2

    for elem in "${haystack[@]}"; do
        [ "$elem" = "$needle" ] && return 0
    done
    return 1
}