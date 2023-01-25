#!/usr/bin/env bash

DIALOG=("dialog")

function wheel::screens::new_screen() {
    local screen="$1"
    local answer_file="$2"
    local dialog_type; dialog_type=$(wheel::json::get "$screen" "type")
    local screen_height; screen_height=$(wheel::json::get_or_default "$screen" "properties.height" "0")
    local screen_width; screen_width=$(wheel::json::get_or_default "$screen" "properties.width" "0")
    # Local here to assist in testing
    local capture_into=${capture_into:-"$(wheel::json::get_or_default "$screen" "capture_into" "")"}

    # pass by reference to set generic dialog options
    local dialog_options
    wheel::screens::set_dialog_options dialog_options
    "wheel::screens::$dialog_type" 2>"$answer_file"
}

function wheel::screens::set_dialog_options() {
    local -n options=$1
    local dialog_opts; dialog_opts=$(wheel::json::get_or_default "$screen" "dialog" "{}")
    local title="$CURRENT_SCREEN"
    old_ifs=$IFS
    IFS=$'\n'
    for entry in $(wheel::json::get "$dialog_opts" ' | to_entries[]' "-c"); do
        IFS=$old_ifs
        local key; key=$(wheel::json::get "$entry" "key")
        local value; value=$(wheel::json::get "$entry" "value")
        if [ "$key" = "title" ]; then
            title=$value
            IFS=$'\n'
            continue
        fi
        if [ "$value" = "true" ]; then
            options+=("--$key")
        elif [ "$value" != "false" ]; then
            options+=("--$key" "$value")
        fi
        IFS=$'\n'
    done
    IFS=$old_ifs
    options+=("--title" "$title")
    wheel::log::debug "Dialog options: ${options[*]}"
}

function wheel::screens::_info_type() {
    "${DIALOG[@]}" \
        "${dialog_options[@]}" \
        --"$1" \
        "$(wheel::json::get "$screen" "properties.text")" "$screen_height" "$screen_width"
}

function wheel::screens::msgbox() {
    wheel::screens::_info_type "msgbox"
}

function wheel::screens::info() {
    wheel::screens::_info_type "infobox"
}

function wheel::screens::yesno() {
    wheel::screens::_info_type "yesno"
}

function wheel::screens::custom() {
    local entrypoint; entrypoint=$(wheel::json::get_or_default "$screen" "entrypoint" "")
    if [ -z "$entrypoint" ]; then
        wheel::log::warn "Custom screen $CURRENT_SCREEN is missing 'entrypoint'"
        return "$DIALOG_ERROR"
    else
        "$entrypoint"
    fi
}

function wheel::screens::_input_type() {
    local text_value; text_value=$(wheel::json::get_or_default "$screen" "properties.text" "")
    local state_value; state_value=$(wheel::state::get "$capture_into")
    local thing_opts=()
    if [ "$2" = "text_is_value" ]; then
        thing_opts+=("$state_value")
    else
        thing_opts+=("$text_value")
    fi
    thing_opts+=("$screen_height" "$screen_width")
    [ "$2" != "text_is_value" ] && thing_opts+=("$state_value")
    "${DIALOG[@]}" \
        "${dialog_options[@]}" \
        --"$1" \
        "${thing_opts[@]}"
}

function wheel::screens::input() {
    wheel::screens::_input_type "inputbox"
}

function wheel::screens::password() {
    wheel::screens::_input_type "passwordbox"
}

function wheel::screens::files() {
    wheel::screens::_input_type "fselect" "text_is_value"
}

function wheel::screens::files::select() {
    local selection=$1
    if [ -d "$selection" ]; then
        wheel::state::set "$capture_into" "$selection/"
    fi
    if [ -f "$selection" ]; then
        wheel::handlers::ok "$selection"
    fi
}

function wheel::screens::calendar() {
    IFS=$'/' read -r -a state_values <<< "$(wheel::state::get "$capture_into")"
    "${DIALOG[@]}" \
        "${dialog_options[@]}" \
        --calendar \
        "$(wheel::json::get_or_default "$screen" "properties.text" "")" "$screen_height" "$screen_width" \
        "${state_values[@]}"
}

function wheel::screens::_parse_menu_options() {
    local -n ref=$1
    local action_items
    local index
    local old_ifs=$IFS
    IFS=$'\n'
    mapfile -t action_items < <(wheel::json::get "$screen" "properties.items[]?" -c)
    for index in "${!action_items[@]}"; do
        local item="${action_items[$index]}"
        local item_caps; item_caps=$(wheel::json::get_or_default "$item" "configures" "")
        local item_desc; item_desc=$(wheel::json::get_or_default "$item" "description" "")
        local item_reqs; item_reqs=$(wheel::json::get_or_default "$item" "required" "false")
        local item_name; item_name=$(wheel::json::get "$item" "name")
        if [ "$2" = "form" ]; then
            local prefix=" "
            [ "$item_reqs" = "true" ] && prefix="*"
            item_name="$prefix$item_name"
            local item_len; item_len=$(wheel::json::get_or_default "$item" "length" "10")
            local item_max; item_max=$(wheel::json::get_or_default "$item" "max" "$item_len")
            local item_typ; item_typ=$(wheel::json::get_or_default "$item" "type" "0")
            ref+=("$item_name" "$((index + 1))" "1")
            [ -z "$item_caps" ] && item_caps=$(wheel::screens::_default_item_configures "$item_name")
            ref+=("$(wheel::state::get "$capture_into.$item_caps")")
            ref+=("$((index + 1))")
            ref+=("$item_col")
            ref+=("$item_len")
            ref+=("$item_max")
            ref+=("$item_typ")
            continue
        fi
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
            elif [ "$(wheel::state::get "$capture_into")" = "$item_name" ]; then
                on_off="on"
            elif [ "$(wheel::state::get "$capture_into | type")" = "array" ]; then
                local values
                # shellcheck disable=SC2034 # does not recgnize passed reference
                mapfile -t values < <(wheel::state::get "${capture_into}"[] -c)
                wheel::utils::in_array values "$item_name" && on_off="on"
            fi
            ref+=("$on_off")
        fi
    done
    IFS=$old_ifs
}

function wheel::screens::_list_type() {
    local menu_height; menu_height=$(wheel::json::get_or_default "$screen" "properties.box_height" "5")
    local menu_options
    [ -n "$extra_items" ] && menu_options=("${extra_items[@]}")
    wheel::screens::_parse_menu_options menu_options "${2:-$1}"
    wheel::log::debug "Menu options for $CURRENT_SCREEN: ${menu_options[*]}"
    "${DIALOG[@]}" \
        "${dialog_options[@]}" \
        --"$1" \
        "$(wheel::json::get_or_default "$screen" "properties.text" "")" "$screen_height" "$screen_width" "$menu_height" \
        "${menu_options[@]}"
}

function wheel::screens::hub() {
    wheel::screens::_list_type "menu"
}

function wheel::screens::checklist() {
    wheel::screens::_list_type "checklist" "list"
}

function wheel::screens::radiolist() {
    wheel::screens::_list_type "radiolist" "list"
}

function wheel::screens::hub::selection() {
    wheel::log::trace "Previous next screen was $next_screen"
    [ -n "$1" ] && next_screen=$1
    wheel::log::trace "Selected next screen is $next_screen"
    wheel::handlers::ok
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
    for reset in $(wheel::json::get "$screen" "properties.items[]?.configures" -c -r); do
        wheel::state::set "$reset" false "argjson"
    done
    for field in "${value_arr[@]}"; do
        local field_cap; field_cap=$(wheel::json::get_or_default "$screen" "properties.items[] | select(.name == \"$field\") | .configures" "" -r)
        if [ -n "$field_cap" ]; then
            wheel::state::set "$field_cap" true "argjson"
        fi
    done
}

function wheel::screens::_file_type() {
    local text_file; text_file=$(wheel::json::get_or_default "$screen" "properties.text" "")
    [ -n "$text_file" ] && text_file=$(wheel::state::interpolate "$text_file")
    [ ! -f "$text_file" ] && exit "$DIALOG_ERROR"
    "${DIALOG[@]}" \
        "${dialog_options[@]}" \
        --"$1" \
        "$text_file" "$screen_height" "$screen_width"
}

function wheel::screens::textbox() {
    wheel::screens::_file_type "textbox"
}

function wheel::screens::editor() {
    wheel::screens::_file_type "editbox"
}

function wheel::screens::editor::save() {
    local text_file; text_file=$(wheel::json::get_or_default "$screen" "properties.text" "")
    text_file=$(wheel::state::interpolate "$text_file")
    cp "$answer_file" "$text_file"
    wheel::handlers::ok
}

function wheel::screens::range() {
    local prop_opts=("$(wheel::json::get_or_default "$screen" "properties.text" "")")
    local default_value; default_value=$(wheel::json::get_or_default "$screen" "properties.default" "0")
    default_value=$(wheel::state::interpolate "$default_value")
    prop_opts+=("$screen_height" "$screen_width")
    prop_opts+=("$(wheel::json::get_or_default "$screen" "properties.min" "0")")
    prop_opts+=("$(wheel::json::get_or_default "$screen" "properties.max" "10")")
    prop_opts+=("$default_value")
    "${DIALOG[@]}" \
        "${dialog_options[@]}" \
        --rangebox \
        "${prop_opts[@]}"
}

function wheel::screens::_invoke_gauge_action() {
    local log_prefix="[$CURRENT_SCREEN][$i][$action]"
    (
        {
            "$action" 2>&1 1>&3 3>&- |
            wheel::log::stream wheel::log::error "$log_prefix"
            exit "${PIPESTATUS[0]}"
        } 3>&1 1>&2 |
        wheel::log::stream wheel::log::info "$log_prefix"
        exit "${PIPESTATUS[0]}"
    )
}

function wheel::screens::_default_form_box_width() {
    local n; n=$(wheel::json::get "$screen" "properties.items[]?.name" |
        xargs -I '{}' bash -c 'echo {} | wc -c' |
        sort |
        head -n1)
    echo "$((n + 2))"
}

function wheel::screens::_default_item_configures() {
    echo "$1" |
    tr -d "[:space:][:punct:]" |
    tr "[:upper:]" "[:lower:]"
}

function wheel::screens::form() {
    local item_col
    item_col=$(wheel::json::get_or_default "$screen" "properties.box_width" "$(wheel::screens::_default_form_box_width)")
    wheel::screens::_list_type "mixedform" "form"
}

function wheel::screens::form::save() {
    local field
    local index
    local value_arr
    local field_arr
    mapfile -t value_arr <<< "$@"
    mapfile -t field_arr < <(wheel::json::get "$screen" "properties.items[]?" -c)
    for index in "${!field_arr[@]}"; do
        field="${field_arr[$index]}"
        local item_name; item_name=$(wheel::json::get "$field" "name")
        local item_caps; item_caps=$(wheel::json::get_or_default "$field" "configures" "")
        [ -z "$item_caps" ] && item_caps=$(wheel::screens::_default_item_configures "$item_name")
        wheel::state::set "${capture_into}.${item_caps}" "${value_arr[$index]}"
    done
}

function wheel::screens::gauge() {
    local screen_label; screen_label=$(wheel::json::get_or_default "$screen" "properties.text" "In progress. Please wait.")
    local actions=()
    mapfile -t actions < <(wheel::json::get "$screen" 'properties.actions[]?' -c)
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
                if ! wheel::screens::_invoke_gauge_action; then
                    exit "$DIALOG_ERROR"
                fi
            done
        ) |
        "${DIALOG[@]}" \
            "${dialog_options[@]}" \
            --gauge \
            "$screen_label" "$screen_height" "$screen_width" 0
        return "${PIPESTATUS[0]}"
    else
        (
            for i in "${!actions[@]}"; do
                local action="${actions[$i]}"
                local log_prefix="[$CURRENT_SCREEN][$i][$action]"
                wheel::log::info "$log_prefix Starting invocation"
                "$action" || exit "$DIALOG_ERROR"
            done
        ) |
        "${DIALOG[@]}" \
            "${dialog_options[@]}" \
            --gauge \
            "$screen_label" "$screen_height" "$screen_width" 0
        return "${PIPESTATUS[0]}"
    fi
}