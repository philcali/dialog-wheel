#!/usr/bin/env bash

TERM_WIDTH="$(tput cols)"

function wheel::dialog::app() {
    local dialog_args
    wheel::dialog::_parse_args dialog_args "$@"
    clear
    "${dialog_args[@]}"
}

function wheel::dialog::_strip_colors() {
    echo "$1" | sed -e 's|\\Z.||g'
}

function wheel::dialog::_header() {
    local width
    local text
    [ -n "$1" ] && {
        text=$(wheel::dialog::_strip_colors "$1")
        width=$(echo -n "$text" | wc -c)
        echo "$text"
        for _ in $(seq 1 "$TERM_WIDTH"); do
            echo -n "#"
        done
        echo
    }
    [ -n "$2" ] && {
        text=$(wheel::dialog::_strip_colors "$2")
        width=$(echo -n "$text" | wc -c)
        echo
        for _ in $(seq 0 "$(((TERM_WIDTH / 2) - (width + 2)))"); do
            echo -n "-"
        done
        echo -n "[  $text  ]"
        for _ in $(seq 0 "$(((TERM_WIDTH / 2) - (width + 2)))"); do
            echo -n "-"
        done
        echo
    }
}

function wheel::dialog::_buttons() {
    column -t -s $'\t' < <(
        local index=0
        for button in "$@"; do
            [ -z "$button" ] && continue
            echo -n -e "[ b$index: $button ]\t"
            index=$((index + 1))
        done
    )
}

function wheel::dialog::_button_handle() {
    case "$1" in
    b1) return 1;;
    b2) return 3;;
    b3) return 2;;
    *) return 0;;
    esac
}

function wheel::dialog::_modal_header() {
    local text=$7
    wheel::dialog::_header "$1" "$2"
    wheel::dialog::_strip_colors "$text"
}

function wheel::dialog::_modal_footer() {
    wheel::dialog::_buttons "$3" "$4" "$5" "$6"
    echo "[ Input ]: "
}

function wheel::dialog::_modal_infobox() {
    wheel::dialog::_modal_header "$@"
    echo
    wheel::dialog::_modal_footer "$@"
}

function wheel::dialog::_modal_inputbox() {
    local formatter=$1
    shift
    local current_value; current_value=$($formatter "$@")
    wheel::dialog::_modal_header "$@"
    [ -n "$current_value" ] && echo "Current value: $current_value"
    echo
    wheel::dialog::_modal_footer "$@"
}

function wheel::dialog::msgbox() {
    wheel::dialog::_modal_infobox "$@"
    local resp
    read -r -u 1 resp
    wheel::dialog::_button_handle "$resp" || return "$?"
}

function wheel::dialog::infobox() {
    wheel::dialog::_modal_infobox "$@"
    local resp
    read -r -u 1 resp
    wheel::dialog::_button_handle "$resp" || return "$?"
}

function wheel::dialog::yesno() {
    wheel::dialog::_modal_infobox "$@"
    local resp
    read -r -u 1 resp
    wheel::dialog::_button_handle "$resp" || return "$?"
}

function wheel::dialog::_mask_pass() {
    echo -n "${10}" | sed -e 's|.|*|g'    
}

function wheel::dialog::_identity() {
    echo -n "${10}"
}

function wheel::dialog::_date() {
    echo -n "${10}/${11}/${12}"
}

function wheel::dialog::_range() {
    echo -n "${12}"
}

function wheel::dialog::inputbox() {
    wheel::dialog::_modal_inputbox wheel::dialog::_identity "$@"
    local resp
    read -r -u 1 resp
    wheel::dialog::_button_handle "$resp" || return "$?"
    >&2 echo "$resp"
}

function wheel::dialog::passwordbox() {
    wheel::dialog::_modal_inputbox "wheel::dialog::_mask_pass" "$@"
    local resp
    read -r -s -u 1 resp
    wheel::dialog::_button_handle "$resp" || return "$?"
    >&2 echo "$resp"
}

function wheel::dialog::calendar() {
    wheel::dialog::_modal_inputbox "wheel::dialog::_date" "$@"
    local resp
    read -r -u 1 resp
    wheel::dialog::_button_handle "$resp" || return "$?"
    >&2 echo "$resp"
}

function wheel::dialog::rangebox() {
    wheel::dialog::_modal_inputbox "wheel::dialog::_range" "$@"
    local resp
    read -r -u 1 resp
    wheel::dialog::_button_handle "$resp" || return "$?"
    >&2 echo "$resp"
}

function wheel::dialog::checklist() {
    local resp
    local buttons
    local selection
    wheel::dialog::_modal_header "$@"
    buttons=$(wheel::dialog::_modal_footer "$@")
    # back, title, ok, cancel, extra, help, text, width, height, menu
    shift 10
    local items=("$@")
    index=0
    column -t -s $'\t' < <(
        while [ -n "$*" ]; do
            selection=" "
            [ "$3" = "on" ] && selection="*"
            echo -n "[$selection]"
            echo -e "[ $index]: $1\t$2"
            shift 3 
            index=$((index + 1))
        done
    )
    echo
    echo "$buttons"
    read -r -u 1 resp
    wheel::dialog::_button_handle "$resp" || return "$?"
    IFS=$' ' read -r -a resp_arr <<< "$resp"
    for elem in "${resp_arr[@]}"; do
        >&2 echo "\"${items[$((elem * 3))]}\""
    done
}

function wheel::dialog::radiolist() {
    local resp
    local buttons
    local selection
    wheel::dialog::_modal_header "$@"
    buttons=$(wheel::dialog::_modal_footer "$@")
    # back, title, ok, cancel, extra, help, text, width, height, menu
    shift 10
    local items=("$@")
    index=0
    column -t -s $'\t' < <(
        while [ -n "$*" ]; do
            selection=" "
            [ "$3" = "on" ] && selection="*"
            echo -n "($selection)"
            echo -e "[ $index]: $1\t$2"
            shift 3 
            index=$((index + 1))
        done
    )
    echo
    echo "$buttons"
    read -r -u 1 resp
    wheel::dialog::_button_handle "$resp" || return "$?"
    >&2 echo "${items[$((resp * 3))]}"
}

function wheel::dialog::menu() {
    local resp
    local index
    local buttons
    wheel::dialog::_modal_header "$@"
    buttons=$(wheel::dialog::_modal_footer "$@")
    # back, title, ok, cancel, extra, help, text, width, height, menu
    shift 10
    local items=("$@")
    index=0
    column -t -s $'\t' < <(
        while [ -n "$*" ]; do
            echo -e "[ $index]: $1\t$2"
            shift 2 
            index=$((index + 1))
        done
    )
    echo
    echo "$buttons"
    read -r -u 1 resp
    wheel::dialog::_button_handle "$resp" || return "$?"
    >&2 echo "${items[$((resp * 2))]}"
}

function wheel::dialog::mixedform() {
    local index=0
    local resp
    local header
    local buttons
    local labels=()
    local answers=()
    header=$(wheel::dialog::_modal_header "$@")
    buttons=$(wheel::dialog::_modal_footer "$@")
    shift 10
    local items=("$@")
    while [ "$index" -lt "${#items[@]}" ]; do
        clear
        echo "$header"
        echo
        column -t -s $'\t' < <(
            for ei in "${!answers[@]}"; do
                echo -e "${labels[$ei]}\t${answers[$ei]}"
            done
        )
        echo "${items[$index]} ${items[$((index + 3))]}"
        echo "$buttons"
        read -r -u 1 resp
        wheel::dialog::_button_handle "$resp" || return "$?"
        labels+=("${items[$index]}")
        [ -z "$resp" ] && answers+=("${items[$((index + 3))]}")
        [ -n "$resp" ] && answers+=("$resp")
        index=$((index + 9))
    done
    for answer in "${answers[@]}"; do
        >&2 echo "$answer"
    done
}

function wheel::dialog::textbox() {
    wheel::dialog::_header "$1" "$2"
    cat "$7"
    wheel::dialog::_modal_footer "$@"
    local resp
    read -r -u 1 resp
    wheel::dialog::_button_handle "$resp" || return "$?"
}

function wheel::dialog::gauge() {
    local line
    local progress
    local percentage=0
    local label=$7
    local start=false
    local parse_percent=false
    local parse_label=false
    while read -r line; do
        clear
        wheel::dialog::_header "$1" "$2"
        echo "$label"
        echo
        progress=$(echo "scale=2; ($TERM_WIDTH * ($percentage / 100))" | bc | cut -d '.' -f 1)
        for _ in $(seq 1 "$progress"); do
            echo -n "#"
        done
        echo 
        if [ "$line" = "XXX" ]; then
            if ! $start; then
                start=true
                parse_percent=false
                parse_label=false
            fi
        elif ! $parse_label && $parse_percent && $start; then
            parse_label=true
            label="$line"
            start=false
        elif ! $parse_percent && $start; then
            parse_percent=true
            percentage="$line"
        fi
    done
}

function wheel::dialog::_parse_args() {
    local -n options=$1
    local titles=("" "")
    local buttons=("OK" "" "" "")
    local text_props=()
    shift
    while [ -n "$*" ]; do
        local param=$1
        case "$param" in
        "--yesno")
            [ "${buttons[0]}" = "OK" ] && buttons[0]="Yes"
            [ "${buttons[1]}" = "" ] && buttons[1]="No";;
        "--radiolist"|"--checklist"|"--menu"|"--mixedform"|"--inputbox"|"--passwordbox"|"--rangebox"|"--calendar")
            [ "${buttons[1]}" = "" ] && buttons[1]="Cancel";;
        esac
        case "$param" in
        "--textbox"|"--yesno"|"--infobox"|"--msgbox"|"--mixedform"|"--rangebox"|"--gauge"|"--menu"|"--checklist"|"--radiolist"|"--inputbox"|"--passwordbox"|"--calendar")
            shift
            text_props+=("$@")
            options+=("wheel::dialog::${param/"--"/}")
            break;;
        "--backtitle")
            shift
            titles[0]="$1";;
        "--title")
            shift
            titles[1]="$1";;
        "--yes-label")
            shift
            buttons[0]="$1";;
        "--no-label")
            shift
            buttons[1]="$1";;
        "--ok-label")
            shift
            buttons[0]="$1";;
        "--cancel-label")
            shift
            buttons[1]="$1";;
        "--extra-label")
            shift
            buttons[2]="$1";;
        "--help-label")
            shift
            buttons[3]="$1";;
        "--exit-label")
            shift
            buttons[0]="$1";;
        "--cancel-button")
            [ "${buttons[1]}" = "" ] && buttons[1]="Cancel"
            ;;
        "--extra-button")
            [ "${buttons[2]}" = "" ] && buttons[2]="Extra"
            ;;
        "--help-button")
            [ "${buttons[3]}" = "" ] && buttons[3]="Help"
            ;;
        esac
        shift
    done
    options+=("${titles[@]}" "${buttons[@]}" "${text_props[@]}")
}

function wheel::dialog::set_new_width() {
    TERM_WIDTH=$(tput cols)
}

trap "wheel::dialog::set_new_width" WINCH
