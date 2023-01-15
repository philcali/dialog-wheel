#!/usr/bin/env bash

SCREEN_STACK=()

function wheel::stack::push() {
    SCREEN_STACK=("$CURRENT_SCREEN" "${SCREEN_STACK[@]}")
    CURRENT_SCREEN="$1"
}

function wheel::stack::pop() {
    CURRENT_SCREEN="${SCREEN_STACK[0]}"
    SCREEN_STACK=("${SCREEN_STACK[@]:1}")
}
