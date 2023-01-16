#!/usr/bin/env bash

SCREEN_STACK=()

function wheel::stack::push() {
    if [ -z "$1" ]; then
        return
    fi
    SCREEN_STACK=("$CURRENT_SCREEN" "${SCREEN_STACK[@]}")
    CURRENT_SCREEN="$1"
}

function wheel::stack::pop() {
    CURRENT_SCREEN="${SCREEN_STACK[0]}"
    SCREEN_STACK=("${SCREEN_STACK[@]:1}")
}

function wheel::stack::clear() {
    SCREEN_STACK=()
}

function wheel::stack::empty() {
    test -z "${SCREEN_STACK[@]}"
    return $?
}