#!/usr/bin/env bash

SCREEN_QUEUE=()

function wheel::queue::push() {
    SCREEN_QUEUE=("$CURRENT_SCREEN" "${SCREEN_QUEUE[@]}")
    CURRENT_SCREEN="$1"
}

function wheel::queue::pop() {
    CURRENT_SCREEN="${SCREEN_QUEUE[0]}"
    SCREEN_QUEUE=("${SCREEN_QUEUE[@]:1}")
}
