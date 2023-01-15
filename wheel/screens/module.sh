#!/usr/bin/env bash

function wheel::screens::new_screen() {
    local screen="$1"
    local title; title=$(wheel::json::get_or_default "$screen" "title" "$CURRENT_SCREEN")
    local dialog_type; dialog_type=$(wheel::json::get "$screen" "type")
    local screen_height; screen_height=$(wheel::json::get_or_default "$screen" "properties.height" "$APP_HEIGHT")
    local screen_width; screen_width=$(wheel::json::get_or_default "$screen" "properties.width" "$APP_WIDTH")

    "wheel::screens::$dialog_type"
}

function wheel::screens::msgbox() {
    local dialog_options=()
    if [ -n "$APP_BACKTITLE" ] && [ "$APP_BACKTITLE" != "null" ]; then
        dialog_options+=("--backtitle" "$APP_BACKTITLE")
    fi
    dialog \
        "${dialog_options[@]}" \
        --title "$title" \
        --aspect "$APP_ASPECT" \
        --msgbox \
        "$(wheel::json::get "$screen" "properties.text")" "$screen_height" "$screen_width" \
        2>&1 1>&3 &
}

function wheel::screens::yesno() {
    dialog \
        --backtitle "$APP_BACKTITLE" \
        --title "$title" \
        --aspect "$APP_ASPECT" \
        --yesno \
        "$(wheel::json::get "$screen" "properties.text")" "$screen_height" "$screen_width" \
        2>&1 1>&3 &
}