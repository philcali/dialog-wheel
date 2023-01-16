#!/usr/bin/env bash

SPECIAL_DIALOG_FIELDS=("title" "aspect")

function wheel::screens::new_screen() {
    local screen="$1"
    local dialog_type="$2"
    local answer_file="$3"
    local dialog_type; dialog_type=$(wheel::json::get "$screen" "type")
    local screen_height; screen_height=$(wheel::json::get_or_default "$screen" "properties.height" "$APP_HEIGHT")
    local screen_width; screen_width=$(wheel::json::get_or_default "$screen" "properties.width" "$APP_WIDTH")

    # pass by reference to set generic dialog options
    local dialog_options
    wheel::screens::set_dialog_options dialog_options
    "wheel::screens::$dialog_type" 2>"$answer_file" &
}

function wheel::screens::set_dialog_options() {
    local -n options=$1
    if [ -n "$APP_BACKTITLE" ] && [ "$APP_BACKTITLE" != "null" ]; then
        options+=("--backtitle" "$APP_BACKTITLE")
    fi
    local title; title=$(wheel::json::get_or_default "$screen" "dialog.title" "$CURRENT_SCREEN")
    local aspect; aspect=$(wheel::json::get_or_default "$screen" "dialog.aspect" "$APP_ASPECT")
    if [ "$(wheel::json::get "$screen" 'dialog | length')" -gt 0 ]; then
        old_ifs=$IFS
        IFS=$'\n'
        for entry in $(wheel::json::get "$screen" 'dialog | to_entries[]' "-c"); do
            IFS=$old_ifs
            local key; key=$(wheel::json::get "$entry" "key")
            local value; value=$(wheel::json::get "$entry" "value")
            if wheel::utils::in_array SPECIAL_DIALOG_FIELDS "$key"; then
                wheel::log::debug "Dialog option $key was in ${SPECIAL_DIALOG_FIELDS[*]}"
                IFS=$'\n'
                continue
            fi
            if [ "$value" = "true" ]; then
                options+=("--$key")
            else
                options+=("--$key" "$value")
            fi
            IFS=$'\n'
        done
        IFS=$old_ifs
    fi
    options+=("--title" "$title")
    options+=("--aspect" "$aspect")
    wheel::log::debug "Dialog options: ${options[*]}"
}

function wheel::screens::msgbox() {
    dialog \
        "${dialog_options[@]}" \
        --msgbox \
        "$(wheel::json::get "$screen" "properties.text")" "$screen_height" "$screen_width"
}

function wheel::screens::yesno() {
    dialog \
        "${dialog_options[@]}" \
        --yesno \
        "$(wheel::json::get "$screen" "properties.text")" "$screen_height" "$screen_width"
}

function wheel::screens::custom() {
    local entrypoint; entrypoint=$(wheel::json::get "$screen" "entrypoint")
    if [ -z "$entrypoint" ] || [ "$entrypoint" = "null" ]; then
        wheel::log::warn "Custom screen $CURRENT_SCREEN is missing 'entrypoint'"
        dialog \
            "${dialog_options[@]}" \
            --msgbox \
            "Could not invoke custom screen without an 'entrypoint' specified." "$screen_height" "$screen_width"
    else
        "$entrypoint"
    fi
}

function wheel::screens::input() {
    dialog \
        "${dialog_options[@]}" \
        --inputbox \
        "$(wheel::json::get "$screen" "properties.text")" "$screen_height" "$screen_width"
}

function wheel::screens::password() {
    dialog \
        "${dialog_options[@]}" \
        --passwordbox \
        "$(wheel::json::get "$screen" "properties.text")" "$screen_height" "$screen_width"
}

function wheel::screens::calendar() {
    dialog \
        "${dialog_options[@]}" \
        --calendar \
        "$(wheel::json::get "$screen" "properties.text")" "$screen_height" "$screen_width"
}

function wheel::screens::_parse_menu_options() {
    local -n ref=$1
    local old_ifs=$IFS
    IFS=$'\n'
    for item in $(wheel::json::get "$screen" "properties.items[]" "-c"); do
        local item_name; item_name=$(wheel::json::get "$item" "name")
        local item_caps; item_caps=$(wheel::json::get "$item" "configures")
        local item_desc; item_desc=$(wheel::json::get_or_default "$item" "description" "")
        local item_reqs; item_reqs=$(wheel::json::get_or_default "$item" "required" "false")
        if ! wheel::json::is_null "$item_caps"; then
            local prefix
            if [ -n "$(wheel::state::get "$item_caps")" ]; then
                prefix="[X]"
            else
                prefix="[ ]"
            fi
            if [ "$item_reqs" = "true" ]; then
                prefix+=" Required"
            else
                prefix+=" Optional"
            fi
            item_desc="$prefix $item_desc"
        fi
        ref+=("$item_name" "$item_desc")
    done
    IFS=$old_ifs
}

function wheel::screens::hub() {
    local menu_height; menu_height=$(wheel::json::get_or_default "$screen" "properties.box_height" "5")
    local menu_options
    wheel::screens::_parse_menu_options menu_options
    wheel::log::debug "Menu options for $title: ${menu_options[*]}"
    dialog \
        "${dialog_options[@]}" \
        --menu \
        "$(wheel::json::get_or_default "$screen" "properties.text" "Please select an option:")" "$screen_height" "$screen_width" "$menu_height" \
        "${menu_options[@]}"
}