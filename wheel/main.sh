#!/usr/bin/env bash

DIR=$(dirname "$(realpath "$0")")
. "$DIR"/constants.sh
. "$DIR"/log/module.sh
. "$DIR"/stack/module.sh
. "$DIR"/json/module.sh
. "$DIR"/events/module.sh
. "$DIR"/screens/module.sh
. "$DIR"/state/module.sh
. "$DIR"/utils/module.sh


# TODO: below
# item_generator
# fselect
# form
# rangebox
# state interpolation

INPUT_SOURCE=""
CURRENT_SCREEN=""
# TODO: make defaults in the screen module
EXIT_SCREEN=""
ERROR_SCREEN=""

APP_BACKTITLE=""
APP_ASPECT=""
APP_WIDTH=""
APP_HEIGHT=""

function wheel::usage() {
    local exit_code=${1:-0}
    echo "Usage $(basename "$0") - v$VERSION: Invoke a dialog wheel"
    echo "Example usage: $(basename "$0") [-h] [-d state.json] [-o output.json] [-l app.log] [-L DEBUG|INFO|WARN|ERROR] [-s workflow.json] [< workflow.json]"
    echo "  -o: Supply an output path for configured JSON"
    echo "  -d: Supply a JSON file representative of the workflow state data"
    echo "  -s: Supply a JSON file that represents the dialog flow"
    echo "  -l: Supply a log source (defaults to /dev/null)"
    echo "  -L: Supply a log level (defaults to INFO)"
    echo "  -h: Prints out this help"
    exit "$exit_code"
}

function wheel::parse_args() {
    while getopts "o:d:L:l:s:h" flag
    do
        case "${flag}" in
        s) INPUT_SOURCE="${OPTARG}";;
        o) wheel::state::set_output "${OPTARG}";;
        d) wheel::state::init "${OPTARG}";;
        l) wheel::log::set_file "${OPTARG}";;
        L) wheel::log::set_level "${OPTARG}";;
        h) wheel::usage 0;;
        *) wheel::usage 1;;
        esac
    done
}

# TODO: Perhaps we move this to a "handlers" module
function wheel::ok_handler() {
    [ "$CURRENT_SCREEN" = "$EXIT_SCREEN" ] && return 1
    [ "$dialog_type" = "hub" ] && [ -n "$value" ] && next_screen=$value
    wheel::stack::push "$next_screen"
}

function wheel::cancel_handler() {
    if wheel::stack::empty; then
        local pushed_screen="$EXIT_SCREEN"
        [ -n "$back_screen" ] && pushed_screen="$back_screen"
        wheel::stack::push "$pushed_screen"
        return 0
    fi
    wheel::stack::pop
}

function wheel::capture_into_handler() {
    wheel::state::set "$capture_into" "$value"
}

function wheel::main_loop() {
    wheel::log::info "Starting Dialog Loop"
    local returncode=0
    while true; do
        local screen; screen=$(wheel::json::get_or_default "$json_source" "screens[\$screen]" "" --arg screen "$CURRENT_SCREEN")
        [ -z "$screen" ] && break
        local next_screen; next_screen=$(wheel::json::get "$screen" "next")
        local dialog_type; dialog_type=$(wheel::json::get "$screen" "type")
        local back_screen; back_screen=$(wheel::json::get_or_default "$screen" "back" "")
        local clear_history; clear_history=$(wheel::json::get_or_default "$screen" "clear_history" "false")
        local capture_into; capture_into=$(wheel::json::get_or_default "$screen" "capture_into" "")
        local value
        wheel::log::info "Displaying screen $CURRENT_SCREEN"
        [ "$clear_history" = "true" ] && wheel::stack::clear
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
            local action
            if [ -n "$capture_into" ]; then
                action=$(wheel::json::get_or_default "$screen" "handlers.capture_into" "wheel::capture_into_handler")
                "$action" "$value"
            fi
            action=$(wheel::json::get_or_default "$screen" "handlers.ok" "wheel::ok_handler")
            "$action" || break
            ;;
        "$DIALOG_CANCEL")
            local action; action=$(wheel::json::get_or_default "$screen" "handlers.cancel" "wheel::cancel_handler")
            "$action" || break
            ;;
        "$DIALOG_EXTRA")
            local action; action=$(wheel::json::get_or_default "$screen" "handlerss.extra" "wheel::cancel_handler")
            "$action" || break
            ;;
        "$DIALOG_ERROR")
            # An error occurred on the CURRENT_SCREEN
            # This means we pop it out, push our error handler
            wheel::stack::pop
            wheel::stack::push "$ERROR_SCREEN"
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
    if [ "$(wheel::json::get "$json_source" 'includes | length')" -gt 0 ]; then
        local inclusion
        local inclusions; inclusions=$(wheel::json::get "$json_source" "includes[]" -c)
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
    fi
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
    wheel::events::add_clean_up "wheel::state::flush"
    wheel::inclusion
    local properties; properties=$(wheel::json::get "$json_source" "properties")
    APP_HEIGHT=$(wheel::json::get_or_default "$properties" "height" "0")
    APP_WIDTH=$(wheel::json::get_or_default "$properties" "width" "0")
    APP_ASPECT=$(wheel::json::get_or_default "$properties" "aspect" "9")
    APP_BACKTITLE=$(wheel::json::get "$json_source" "title")
    # TODO: Handle these settings more gracefully
    EXIT_SCREEN=$(wheel::json::get "$json_source" "exit")
    CURRENT_SCREEN=$(wheel::json::get "$json_source" "start")
    ERROR_SCREEN=$(wheel::json::get "$json_source" "error")
    wheel::log::debug "Application Height: $APP_HEIGHT"
    wheel::log::debug "Application Width: $APP_WIDTH"
    wheel::log::debug "Application Aspect Ratio: $APP_ASPECT"
    wheel::log::debug "Application Title: $APP_BACKTITLE"
    wheel::log::debug "Exit screen: $EXIT_SCREEN"
    wheel::log::debug "Start screen: $CURRENT_SCREEN"
    wheel::log::debug "Error screen: $ERROR_SCREEN"
    wheel::main_loop
}

wheel::parse_args "$@"
wheel::main