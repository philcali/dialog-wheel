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
    local entrypoint; entrypoint=$(wheel::json::get_or_default "$screen" "entrypoint" "")
    if [ -z "$entrypoint" ]; then
        wheel::log::warn "Custom screen $CURRENT_SCREEN is missing 'entrypoint'"
        exit "$DIALOG_ERROR"
    else
        "$entrypoint"
    fi
}

function wheel::screens::input() {
    local captures; captures=$(wheel::json::get "$screen" "capture_into")
    dialog \
        "${dialog_options[@]}" \
        --inputbox \
        "$(wheel::json::get "$screen" "properties.text")" \
        "$screen_height" "$screen_width" \
        "$(wheel::state::get "$captures")"
}

function wheel::screens::password() {
    local captures; captures=$(wheel::json::get "$screen" "capture_into")
    dialog \
        "${dialog_options[@]}" \
        --passwordbox \
        "$(wheel::json::get "$screen" "properties.text")" \
        "$screen_height" "$screen_width" \
        "$(wheel::state::get "$captures")"
}

function wheel::screens::calendar() {
    dialog \
        "${dialog_options[@]}" \
        --calendar \
        "$(wheel::json::get "$screen" "properties.text")" "$screen_height" "$screen_width"
}

function wheel::screens::_parse_menu_options() {
    local captures; captures=$(wheel::json::get "$screen" "capture_into")
    local -n ref=$1
    local old_ifs=$IFS
    IFS=$'\n'
    for item in $(wheel::json::get "$screen" "properties.items[]" -c); do
        local item_name; item_name=$(wheel::json::get "$item" "name")
        local item_caps; item_caps=$(wheel::json::get_or_default "$item" "configures" "")
        local item_desc; item_desc=$(wheel::json::get_or_default "$item" "description" "")
        local item_reqs; item_reqs=$(wheel::json::get_or_default "$item" "required" "false")
        if [ -n "$item_caps" ] && [ "$2" = "menu" ]; then
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
        if [ "$2" = "list" ]; then
            local on_off="off"
            if [ -n "$item_caps" ]; then
                [ "$(wheel::state::get "$item_caps")" = "true" ] && on_off="on"
            elif [ "$(wheel::state::get "$captures")" = "$item_name" ]; then
                on_off="on"
            elif [ "$(wheel::state::get "$captures | length")" -gt 0 ]; then
                local values
                # shellcheck disable=SC2034 # does noe recgnize passed reference
                mapfile -t values < <(wheel::state::get "${captures}"[] -c)
                wheel::utils::in_array values "$item_name" && on_off="on"
            fi
            ref+=("$on_off")
        fi
    done
    IFS=$old_ifs
}

function wheel::screens::hub() {
    local menu_height; menu_height=$(wheel::json::get_or_default "$screen" "properties.box_height" "5")
    local menu_options
    wheel::screens::_parse_menu_options menu_options "menu"
    wheel::log::debug "Menu options for $CURRENT_SCREEN: ${menu_options[*]}"
    dialog \
        "${dialog_options[@]}" \
        --menu \
        "$(wheel::json::get_or_default "$screen" "properties.text" "")" "$screen_height" "$screen_width" "$menu_height" \
        "${menu_options[@]}"
}

function wheel::screens::checklist() {
    local menu_height; menu_height=$(wheel::json::get_or_default "$screen" "properties.box_height" "5")
    local menu_options
    wheel::screens::_parse_menu_options menu_options "list"
    wheel::log::debug "List options for $CURRENT_SCREEN: ${menu_options[*]}"
    dialog \
        "${dialog_options[@]}" \
        --checklist \
        "$(wheel::json::get_or_default "$screen" "properties.text" "")" "$screen_height" "$screen_width" "$menu_height" \
        "${menu_options[@]}"
}

function wheel::screens::checklist::list() {
    local index
    local value_arr
    read -r -a value_arr <<< "$@"
    for index in "${!value_arr[@]}"; do
        wheel::state::set "${capture_into:?}[$index]" "${value_arr[$index]}"
    done
}

function wheel::screens::checklist::field() {
    local field
    local reset
    local value_arr
    read -r -a value_arr <<< "$@"
    for reset in $(wheel::json::get "$screen" "properties.items[].configures" -c -r); do
        wheel::state::set "$reset" false "argjson"
    done
    for field in "${value_arr[@]}"; do
        local field_cap; field_cap=$(wheel::json::get_or_default "$screen" "properties.items[] | select(.name == \"$field\") | .configures" "" -r)
        if [ -n "$field_cap" ]; then
            wheel::state::set "$field_cap" true "argjson"
        fi
    done
}

function wheel::screens::radiolist() {
    local menu_height; menu_height=$(wheel::json::get_or_default "$screen" "properties.box_height" "5")
    local menu_options
    wheel::screens::_parse_menu_options menu_options "list"
    wheel::log::debug "List options for $CURRENT_SCREEN: ${menu_options[*]}"
    dialog \
        "${dialog_options[@]}" \
        --radiolist \
        "$(wheel::json::get_or_default "$screen" "properties.text" "")" "$screen_height" "$screen_width" "$menu_height" \
        "${menu_options[@]}"
}

function wheel::screens::files() {
    local captures; captures=$(wheel::json::get "$screen" "capture_into")
    dialog \
        "${dialog_options[@]}" \
        --fselect \
        "$(wheel::state::get "$captures")" "$screen_height" "$screen_width"
}

function wheel::screens::files::select() {
    local selection=$1
    if [ -d "$selection" ]; then
        wheel::state::set "$capture_into" "$selection/"
    fi
    if [ -f "$selection" ]; then
        wheel::ok_handler "$selection"
    fi
}

function wheel::screens::textbox() {
    local text_file; text_file=$(wheel::json::get_or_default "$screen" "properties.text" "")
    text_file=$(wheel::state::interpolate "$text_file")
    [ ! -f "$text_file" ] && exit "$DIALOG_ERROR"
    dialog \
        "${dialog_options[@]}" \
        --textbox \
        "$text_file" "$screen_height" "$screen_width"
}

function wheel::screens::editor() {
    local text_file; text_file=$(wheel::json::get_or_default "$screen" "properties.text" "")
    text_file=$(wheel::state::interpolate "$text_file")
    [ ! -f "$text_file" ] && exit "$DIALOG_ERROR"
    dialog \
        "${dialog_options[@]}" \
        --editbox \
        "$text_file" "$screen_height" "$screen_width"
}

function wheel::screens::editor::save() {
    local text_file; text_file=$(wheel::json::get_or_default "$screen" "properties.text" "")
    text_file=$(wheel::state::interpolate "$text_file")
    cp "$answer_file" "$text_file"
    wheel::ok_handler
}

function wheel::screens::gauge() {
    local actions=()
    mapfile -t actions < <(wheel::json::get "$screen" 'properties.actions[]' -c)
    wheel::log::debug "Found the actions ${actions[*]}"
    if [ "$(wheel::json::get_or_default "$screen" "managed" "false")" = "true" ]; then
        local output_file; output_file=$(wheel::json::get_or_default "$screen" "output_to" "")
        # Support overriding logger for local actions
        local LOG_FILE=${output_file:-$LOG_FILE}
        local total="${#actions[@]}"
        (
            for i in "${!actions[@]}"; do
                local action="${actions[$i]}"
                local label="Step $((i + 1)): $action"
                if wheel::json::validate "$action"; then
                    label=$(wheel::json::get_or_default "$action" "label" "$label")
                    action=$(wheel::json::get "$action" "action")
                fi
                local frac; frac=$(echo "scale=2; ($i + 1)/$total" | bc)
                local percentage; percentage=$(awk -vf="$frac" 'BEGIN{printf "%.0f", f * 100}')
                echo "XXX"
                echo "$percentage"
                echo "$label"
                echo "XXX"
                local log_prefix="[$CURRENT_SCREEN][$i][$action]"
                ({  "$action" 2>&1 1>&3 3>&- | wheel::log::stream wheel::log::error "$log_prefix"; exit "${PIPESTATUS[0]}"; } 3>&1 1>&2 | wheel::log::stream wheel::log::info "$log_prefix"; exit "${PIPESTATUS[0]}")
                local action_exit=$?
                wheel::log::debug "Action exits with $action_exit"
                if [ $action_exit -ne 0 ]; then
                    exit "$DIALOG_ERROR"
                fi
            done
        ) |
        dialog \
            "${dialog_options[@]}" \
            --gauge \
            "$(wheel::json::get_or_default "$screen" "properties.text" "In progress. Please wait.")" "$screen_height" "$screen_width" 0
        exit "${PIPESTATUS[0]}"
    else
        (
            for action in "${actions[@]}"; do
                wheel::log::info "Invoking $CURRENT_SCREEN action $action"
                "$action" || exit "$DIALOG_ERROR"
            done
        ) |
        dialog \
            "${dialog_options[@]}" \
            --gauge \
            "$(wheel::json::get_or_default "$screen" "properties.text" "In progress. Please wait.")" "$screen_height" "$screen_width" 0
        exit "${PIPESTATUS[0]}"
    fi
}