#!/usr/bin/env bash

function wheel::utils::in_array() {
    local -n haystack=$1
    local needle=$2

    for elem in "${haystack[@]}"; do
        if [ "$elem" = "$needle" ]; then
            return 0
        fi
    done
    return 1
}