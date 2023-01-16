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
        local screen; screen=$(wheel::json::get "$json_source" "screens[\$screen]" --arg screen "$CURRENT_SCREEN")
        if [ -z "$screen" ] || [ "$screen" = "null" ]; then
            break
        fi
        local next_screen; next_screen=$(wheel::json::get "$screen" "next")
        local dialog_type; dialog_type=$(wheel::json::get "$screen" "type")
        local clear_history; clear_history=$(wheel::json::get_or_default "$screen" "clear_history" "false")
        local value
        wheel::log::debug "Displaying screen $CURRENT_SCREEN"
        if [ "$dialog_type" = "hub" ] || [ "$clear_history" = "true" ]; then
            wheel::stack::clear
        fi
        wheel::screens::new_screen "$screen" "$dialog_type" "$answer_file"
        # Allow trap
        ACTIVE_DIALOG=$!
        wait $ACTIVE_DIALOG
        returncode=$?
        ACTIVE_DIALOG=""
        value=$(cat "$answer_file")
        wheel::log::debug "Screen $CURRENT_SCREEN exits with $returncode, value $value"
        case $returncode in
        "$DIALOG_OK")
            if [ "$CURRENT_SCREEN" = "$EXIT_SCREEN" ]; then
                break
            fi
            if [ "$dialog_type" = "hub" ] && [ -n "$value" ]; then
                next_screen=$value
            fi
            wheel::stack::push "$next_screen"
            ;;
        "$DIALOG_CANCEL")
            if wheel::stack::empty; then
                wheel::stack::push "$EXIT_SCREEN"
                continue
            fi
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
    wheel::log::info "Exiting Dialog Loop"
}

function wheel::inclusion() {
    local inclusions; inclusions=$(wheel::json::get "$json_source" "includes[]" "-c")
    local inclusion
    for inclusion in $inclusions; do
        local file; file=$(wheel::json::get "$inclusion" "file")
        local directory; directory=$(wheel::json::get_or_default "$inclusion" "directory" "$CWD")
        if [ ! -f "$directory/$file" ]; then
            wheel::log::warn "Tried to include $directory/$file, but it does not exist"
            continue
        fi
        # shellcheck source=examples/application.sh
        . "$directory/$file"
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
    local answer_file; answer_file=$(mktemp)
    wheel::events::add_clean_up "rm $answer_file"
    wheel::inclusion
    local properties; properties=$(wheel::json::get "$json_source" "properties")
    APP_HEIGHT=$(wheel::json::get_or_default "$properties" "height" "0")
    APP_WIDTH=$(wheel::json::get_or_default "$properties" "width" "0")
    APP_ASPECT=$(wheel::json::get_or_default "$properties" "aspect" "9")
    APP_BACKTITLE=$(wheel::json::get "$json_source" "title")
    EXIT_SCREEN=$(wheel::json::get "$json_source" "exit")
    CURRENT_SCREEN=$(wheel::json::get "$json_source" "start")
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