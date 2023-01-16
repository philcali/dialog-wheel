#!/usr/bin/env bash

function wheel::screens::new_screen() {
    local screen="$1"
    local dialog_type="$2"
    local answer_file="$3"
    local title; title=$(wheel::json::get_or_default "$screen" "title" "$CURRENT_SCREEN")
    local dialog_type; dialog_type=$(wheel::json::get "$screen" "type")
    local screen_height; screen_height=$(wheel::json::get_or_default "$screen" "properties.height" "$APP_HEIGHT")
    local screen_width; screen_width=$(wheel::json::get_or_default "$screen" "properties.width" "$APP_WIDTH")

    "wheel::screens::$dialog_type" 2>"$answer_file" &
}

function wheel::screens::set_dialog_options() {
    local -n options=$1
    if [ -n "$APP_BACKTITLE" ] && [ "$APP_BACKTITLE" != "null" ]; then
        options+=("--backtitle" "$APP_BACKTITLE")
    fi
    options+=("--title" "$title")
    options+=("--aspect" "$APP_ASPECT")
    wheel::log::debug "Dialog options: ${options[*]}"
}

function wheel::screens::msgbox() {
    local dialog_options
    wheel::screens::set_dialog_options dialog_options
    dialog \
        "${dialog_options[@]}" \
        --msgbox \
        "$(wheel::json::get "$screen" "properties.text")" "$screen_height" "$screen_width"
}

function wheel::screens::yesno() {
    local dialog_options
    wheel::screens::set_dialog_options dialog_options
    dialog \
        "${dialog_options[@]}" \
        --yesno \
        "$(wheel::json::get "$screen" "properties.text")" "$screen_height" "$screen_width"
}

function wheel::screens::custom() {
    local dialog_options
    wheel::screens::set_dialog_options dialog_options
    local entrypoint; entrypoint=$(wheel::json::get "$screen" "entrypoint")
    if [ -z "$entrypoint" ] || [ "$entrypoint" = "null" ]; then
        wheel::log::warn "Custom screen $CURRENT_SCREEN is missing 'entrypoint'"
        dialog \
            "${dialog_options[@]}" \
            --msgbox \
            "Could not invoke custom screen without an 'entrypoint' specified." "$screen_height" "$screen_width"
    else
        eval "$entrypoint"
    fi
}

function wheel::screens::hub() {
    local dialog_options
    local menu_options
    local menu_height; menu_height=$(wheel::json::get_or_default "$screen" "properties.menu_height" "5")
    wheel::screens::set_dialog_options dialog_options
    local old_ifs=$IFS
    IFS=$'\n'
    for item in $(wheel::json::get "$screen" "properties.items[]" "-c"); do
        local item_name; item_name=$(wheel::json::get "$item" "name")
        local item_desc; item_desc=$(wheel::json::get "$item" "description")
        menu_options+=("$item_name" "$item_desc")
    done
    IFS=$old_ifs
    wheel::log::debug "Menu options for $title: ${menu_options[*]}"
    dialog \
        "${dialog_options[@]}" \
        --menu \
        "$(wheel::json::get_or_default "$screen" "properties.text" "Please select an option:")" "$screen_height" "$screen_width" "$menu_height" \
        "${menu_options[@]}"
}