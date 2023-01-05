#!/usr/bin/env bash

DIR=$(dirname "$(realpath "$0")")
. "$DIR"/constants.sh
. "$DIR"/queue/module.sh
. "$DIR"/json/module.sh


INPUT_SOURCE=""
CURRENT_SCREEN=""
ACTIVE_DIALOG=""
EXIT_SCREEN=""
VERSION="1.0.0"

function wheel::usage() {
    local exit_code=${1:-0}
    echo "Usage $(basename "$0") - v$VERSION: Invoke a dialog wheel"
    echo "Example usage: $(basename "$0") [-h] [-s workflow.json] [< worklfow.json]"
    echo "  -s: Supply a JSON file that represents the dialog flow"
    echo "  -h: Prints out this help"
    exit "$exit_code"
}

function wheel::parse_args() {
    while getopts "s:h" flag
    do
        case "${flag}" in
        s) INPUT_SOURCE="${OPTARG}";;
        h) wheel::usage 0;;
        *) wheel::usage 1;;
        esac
    done
}

function wheel::catch_force_exit() {
    if [ "$EXIT_SCREEN" != "$CURRENT_SCREEN" ]; then
        wheel::queue::push "$EXIT_SCREEN"
    else
        CURRENT_SCREEN="null"
    fi
    kill $ACTIVE_DIALOG
}

function wheel::main() {
    local input_source="${INPUT_SOURCE:-/dev/stdin}"
    local json_source; json_source=$(wheel::json::read "$input_source")
    local properties; properties=$(echo "$json_source" | jq '.properties')
    local height; height=$(wheel::json::get_or_default "$properties" "height" "0")
    local width; width=$(wheel::json::get_or_default "$properties" "width" "0")
    local aspect; aspect=$(wheel::json::get_or_default "$properties" "aspect" "9")
    local backtitle; backtitle=$(echo "$json_source" | jq -r '.title')
    local returncode=0
    EXIT_SCREEN=$(echo "$json_source" | jq -r '.exit')
    CURRENT_SCREEN=$(echo "$json_source" | jq -r '.start')
    while true; do
        local screen; screen=$(echo "$json_source" | jq ".screens.$CURRENT_SCREEN")
        if [ -z "$screen" ] || [ "$screen" = "null" ]; then
            break
        fi
        local title; title=$(wheel::json::get_or_default "$screen" "title" "$CURRENT_SCREEN")
        local dialog_type; dialog_type=$(wheel::json::get "$screen" "type")
        local screen_height; screen_height=$(wheel::json::get_or_default "$screen" "properties.height" "$height")
        local screen_width; screen_width=$(wheel::json::get_or_default "$screen" "properties.width" "$width")
        local next_screen; next_screen=$(wheel::json::get "$screen" "next")
        exec 3>&1
        dialog \
            --backtitle "$backtitle" \
            --title "$title" \
            --aspect "$aspect" \
            "--$dialog_type" \
            "$(wheel::json::get "$screen" "properties.text")" "$screen_height" "$screen_width" \
            2>&1 1>&3 &
        # Allow trap
        ACTIVE_DIALOG=$!
        wait $ACTIVE_DIALOG
        returncode=$?
        exec 3>&-
        case $returncode in
        "$DIALOG_OK")
            if [ "$CURRENT_SCREEN" = "$EXIT_SCREEN" ]; then
                break
            fi
            wheel::queue::push "$next_screen"
            ;;
        "$DIALOG_CANCEL")
            wheel::queue::pop
            ;;
        "$DIALOG_ESC")
            if [ "$CURRENT_SCREEN" = "$EXIT_SCREEN" ]; then
                wheel::queue::pop
                continue
            fi
            wheel::queue::push "$EXIT_SCREEN"
            ;;
        esac
    done
}

wheel::parse_args "$@"
trap "wheel::catch_force_exit" "$SIG_INT"
wheel::main