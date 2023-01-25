#!/usr/bin/env bash

function application::example::hello_world() {
    # Delegates to the library method, however the following exist in env:
    # $screen
    # $dialog_options
    # $screen_width
    # $screen_height
    wheel::screens::msgbox
}

function application::example::validate() {
    for i in {0..9}; do
        local precentage=$(((i + 1) * 10))
        echo "XXX"
        echo "$precentage"
        echo "Validating is %$precentage complete..."
        echo "XXX"
        sleep 1
    done
}

function application::example::networks() {
    local network_line
    local index
    local networks
    mapfile -t networks < <(nmcli device | grep -v DEVICE | grep -v bridge)
    for index in "${!networks[@]}"; do
        local network_line="${networks[$index]}"
        local parts
        read -r -a parts <<< "$network_line"
        screen=$(wheel::json::set \
            "$screen" "properties.items[$index]" \
            "{\"name\":\"${parts[0]}\",\"description\":\"${parts[1]} device ${parts[2]} ${parts[3]}\"}")
    done
    wheel::screens::radiolist
}

function application::example::network_status() {
    local entries
    local index
    local selected_device; selected_device=$(wheel::state::get "network")
    local msg="\nDetails for \Zb$selected_device\ZB\n\n"
    local labels=("Connect" "Address" "Gateway")
    mapfile -t entries < <(nmcli device show "$selected_device" | grep -E "CONNECTION|IP4.(ADDRESS|GATEWAY)" | awk '{print $2}')
    for index in "${!entries[@]}"; do
        msg+="${labels[$index]}: \Zb${entries[$index]}\ZB\n"
    done
    screen=$(wheel::json::set "$screen" "properties.text" "$msg")
    wheel::screens::msgbox
}

function application::example::step() {
    echo "Invoked from $CURRENT_SCREEN - $i"
    echo "Some other things to be helpful: $(date -u)"
}

function application::example::step_failure() {
    echo "Explosion!" >&2
    exit 1
}

function application::example::step_one() {
    sleep 1
    echo "Testing the device storage..."
}

function application::example::step_two() {
    sleep 1
    echo "Testing the device compute..."
}

function application::example::step_three() {
    sleep 1
    echo "Testing the device network..."
}

function application::example::step_four() {
    sleep 1
    echo "Testing authentication..."
}

function application::example::step_five() {
    sleep 1
    echo "Authorizing..."
}