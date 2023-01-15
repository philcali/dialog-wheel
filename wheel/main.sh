#!/usr/bin/env bash

DIR=$(dirname "$(realpath "$0")")
. "$DIR"/constants.sh
. "$DIR"/log/module.sh
. "$DIR"/stack/module.sh
. "$DIR"/json/module.sh
. "$DIR"/events/module.sh
. "$DIR"/screens/module.sh


INPUT_SOURCE=""
CURRENT_SCREEN=""
EXIT_SCREEN=""

APP_BACKTITLE=""
APP_ASPECT=""
APP_WIDTH=""
APP_HEIGHT=""

function wheel::usage() {
    local exit_code=${1:-0}
    echo "Usage $(basename "$0") - v$VERSION: Invoke a dialog wheel"
    echo "Example usage: $(basename "$0") [-h] [-s workflow.json] [< workflow.json]"
    echo "  -s: Supply a JSON file that represents the dialog flow"
    echo "  -l: Supply a log source (defaults to /dev/null)"
    echo "  -L: Supply a log level (defaults to INFO)"
    echo "  -h: Prints out this help"
    exit "$exit_code"
}

function wheel::parse_args() {
    while getopts "L:l:s:h" flag
    do
        case "${flag}" in
        s) INPUT_SOURCE="${OPTARG}";;
        l) wheel::log::set_file "${OPTARG}";;
        L) wheel::log::set_level "${OPTARG}";;
        h) wheel::usage 0;;
        *) wheel::usage 1;;
        esac
    done
}

function wheel::main_loop() {
    wheel::log::info "Starting Dialog Loop"
    local returncode=0
    while true; do
        local screen; screen=$(echo "$json_source" | jq ".screens.$CURRENT_SCREEN")
        if [ -z "$screen" ] || [ "$screen" = "null" ]; then
            break
        fi
        local next_screen; next_screen=$(wheel::json::get "$screen" "next")
        wheel::log::debug "Displaying screen $CURRENT_SCREEN"
        exec 3>&1
        wheel::screens::new_screen "$screen"
        # Allow trap
        ACTIVE_DIALOG=$!
        wait $ACTIVE_DIALOG
        returncode=$?
        exec 3>&-
        wheel::log::debug "Screen $CURRENT_SCREEN exits with $returncode"
        case $returncode in
        "$DIALOG_OK")
            if [ "$CURRENT_SCREEN" = "$EXIT_SCREEN" ]; then
                break
            fi
            wheel::stack::push "$next_screen"
            ;;
        "$DIALOG_CANCEL")
            wheel::stack::pop
            ;;
        "$DIALOG_ESC")
            if [ "$CURRENT_SCREEN" = "$EXIT_SCREEN" ]; then
                wheel::stack::pop
                continue
            fi
            wheel::stack::push "$EXIT_SCREEN"
            ;;
        esac
    done
}

function wheel::main() {
    local input_source="${INPUT_SOURCE:-/dev/stdin}"
    local json_source; json_source=$(wheel::json::read "$input_source")
    local msg; msg=$(wheel::json::validate "$json_source")
    if [ $? -eq 1 ]; then
        echo "json error: $msg" > /dev/stderr
        exit 1
    fi
    wheel::events::set_traps
    local properties; properties=$(echo "$json_source" | jq '.properties')
    APP_HEIGHT=$(wheel::json::get_or_default "$properties" "height" "0")
    APP_WIDTH=$(wheel::json::get_or_default "$properties" "width" "0")
    APP_ASPECT=$(wheel::json::get_or_default "$properties" "aspect" "9")
    APP_BACKTITLE=$(echo "$json_source" | jq -r '.title')
    EXIT_SCREEN=$(echo "$json_source" | jq -r '.exit')
    CURRENT_SCREEN=$(echo "$json_source" | jq -r '.start')
    wheel::log::debug "Application Height: $APP_HEIGHT"
    wheel::log::debug "Application Width: $APP_WIDTH"
    wheel::log::debug "Application Aspect Ratio: $APP_ASPECT"
    wheel::log::debug "Application Title: $APP_BACKTITLE"
    wheel::log::debug "Exit screen: $EXIT_SCREEN"
    wheel::log::debug "Start screen: $CURRENT_SCREEN"
    wheel::main_loop
}

wheel::parse_args "$@"
wheel::main