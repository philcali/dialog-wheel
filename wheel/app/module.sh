#!/usr/bin/env bash

INPUT_SOURCE=""
CURRENT_SCREEN=""
EXIT_SCREEN=""
ERROR_SCREEN=""
START_SCREEN=""

function wheel::app::usage() {
    local exit_code=${1:-0}
    echo "Usage $(basename "$0") - v$VERSION: Invoke a dialog wheel"
    echo "Example usage: $(basename "$0") [-hv] [-d state.json] [-o output.json] [-l app.log] [-L DEBUG|INFO|WARN|ERROR] [-s START_SCREEN] [-i workflow.json] [< workflow.json]"
    echo "  -o: Supply an output path for configured JSON"
    echo "  -d: Supply a JSON file representative of the workflow state data"
    echo "  -i: Supply a JSON file that represents the dialog flow"
    echo "  -s: Supply a screen name to start the flow"
    echo "  -l: Supply a log source (defaults to /dev/null)"
    echo "  -L: Supply a log level (defaults to INFO)"
    echo "  -v: PRints out the version and exits"
    echo "  -h: Prints out this help"
    exit "$exit_code"
}

function wheel::app::init() {
    while getopts "s:o:d:L:l:i:hv" flag
    do
        case "${flag}" in
        s) START_SCREEN="${OPTARG}";;
        i) INPUT_SOURCE="${OPTARG}";;
        o) wheel::state::set_output "${OPTARG}";;
        d) wheel::state::init "${OPTARG}";;
        l) wheel::log::set_file "${OPTARG}";;
        L) wheel::log::set_level "${OPTARG}";;
        h) wheel::app::usage 0;;
        v) echo "$VERSION" && exit 0;;
        *) wheel::app::usage 1;;
        esac
    done
}

function wheel::app::_inclusion() {
    local inclusion
    local inclusions; inclusions=$(wheel::json::get "$json_source" "includes[]?" -c)
    for inclusion in $inclusions; do
        local file; file=$(wheel::json::get "$inclusion" "file")
        local directory; directory=$(wheel::json::get_or_default "$inclusion" "directory" "$CWD")
        if [ ! -f "$directory/$file" ]; then
            wheel::log::warn "Tried to include $directory/$file, but it does not exist"
            continue
        fi
        wheel::log::trace "Including $directory/$file"
        # shellcheck source=examples/application.sh
        . "$directory/$file"
        wheel::log::trace "Inclusion exits with $?"
    done
}

function wheel::app::_run() {
    wheel::log::info "Starting Dialog Loop"
    local returncode=0
    while true; do
        [ "$(wheel::json::get "$json_source" "screens | has(\"$CURRENT_SCREEN\")")" = "false" ] && break
        local value
        local action
        local action_name
        local action_names=()
        local single_arg=1
        local screen; screen=$(wheel::json::merge "$json_source" "$CURRENT_SCREEN" dialog properties handlers)
        local clear_history; clear_history=$(wheel::json::get_or_default "$screen" "clear_history" "false")
        local capture_into; capture_into=$(wheel::json::get_or_default "$screen" "capture_into" "")
        local next_screen
        local back_screen
        # shellcheck disable=SC2034 # next_screen left for documentation
        next_screen=$(wheel::json::get_or_default "$screen" "next" "")
        # shellcheck disable=SC2034 # back_screen left for documentation
        back_screen=$(wheel::json::get_or_default "$screen" "back" "")
        wheel::log::info "Displaying screen $CURRENT_SCREEN"
        [ "$clear_history" = "true" ] && wheel::stack::clear
        # Allow trap
        wheel::screens::new_screen "$screen" "$answer_file" &
        ACTIVE_DIALOG=$!
        wait $ACTIVE_DIALOG
        returncode=$?
        ACTIVE_DIALOG=""
        # dialog does something weird here... if the answer is a spaced arg
        # Then it will quote it "sometimes"... here we account for that
        # Unfortunately this parsing hint needs to be passed to the
        # capture handlers
        if grep '"' < "$answer_file" 2>&1 >/dev/null; then
            IFS=$'\n' value=("$(xargs -n1 < "$answer_file")")
            single_arg=0
        else
            value=("$(<"$answer_file")")
        fi
        wheel::log::debug "Screen $CURRENT_SCREEN exits with $returncode, single arg: $single_arg value ${value[*]}"
        case $returncode in
        "$DIALOG_OK")
            if [ -n "$capture_into" ]; then
                action_names+=("capture_into")
            fi
            action_names+=("ok")
            ;;
        "$DIALOG_CANCEL")
            action_names+=("cancel")
            ;;
        "$DIALOG_TIMEOUT")
            action_names+=("timeout")
            ;;
        "$DIALOG_HELP")
            action_names+=("help")
            ;;
        "$DIALOG_EXTRA")
            action_names+=("extra")
            ;;
        "$DIALOG_ERROR"|"$DIALOG_NOT_FOUND")
            action_names+=("error")
            ;;
        "$DIALOG_ESC")
            action_names+=("esc")
            ;;
        esac
        for action_name in "${action_names[@]}"; do
            local is_array=false
            for action in $(wheel::json::get_or_default "$screen" "handlers.${action_name}[]?" ""); do
                is_array=true
                "$action" "${value[@]}" || break 3
            done
            $is_array && continue
            local default_action="wheel::handlers::$action_name"
            case "$action_name" in
                "help"|"extra"|"timeout")
                    default_action="wheel::handlers::cancel"
                    ;;
            esac
            action=$(wheel::json::get_or_default "$screen" "handlers.$action_name" "$default_action")
            "$action" "${value[@]}" || break 2
        done
    done
    wheel::log::debug "Last screen was $CURRENT_SCREEN"
    wheel::log::info "Exiting Dialog Loop"
}

function wheel::app::run() {
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
    wheel::app::_inclusion
    EXIT_SCREEN=$(wheel::json::get "$json_source" "exit")
    ERROR_SCREEN=$(wheel::json::get_or_default "$json_source" "error" "")
    CURRENT_SCREEN=$(wheel::json::get "$json_source" "start")
    [ -n "$START_SCREEN" ] && CURRENT_SCREEN=$START_SCREEN
    wheel::log::debug "Exit screen: $EXIT_SCREEN"
    wheel::log::debug "Start screen: $CURRENT_SCREEN"
    wheel::log::debug "Error screen: $ERROR_SCREEN"
    wheel::app::_run
}