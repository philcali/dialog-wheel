#!/usr/bin/env bash

# The TODO state structure will generate something like
# The selected_* and current_* fields are transient
#{
#    "lists": [
#        {
#            "name": "Housework",
#            "description": "List containing things to do around the house"
#        },
#        {
#            "name": "Shopping",
#            "description": "List containing things to buy"
#        }
#    ],
#    "selected_list": "Housework",
#    "selected_list_index": 0,
#    "current_list": {
#        "name": "Housework",
#        "description": "List containing things to do around the house"
#    },
#    "Housework": [
#        {
#            "name": "Rake",
#            "description": "Rake the leaves"
#        },
#        {
#            "name": "Fix the fence",
#            "description": "Pull out the rotted boards and replace"
#        }
#    ],
#    "selected_item": "Rake",
#    "selected_index": 0,
#    "current_item": {
#        "name": "Rake",
#        "description": "Rake the leaves"
#    },
#    "Shopping": [
#        {
#            "name": "Apples"
#        },
#        {
#            "name": "Bananas"
#        }
#    ]
#}

function wheel::todo::add_to_database() {
    wheel::todo::_add_to_list "selected_list_index" "lists" "current_list"
}

function wheel::todo::remove_from_database() {
    wheel::todo::_remove_from_list "lists" "current_list"
}

function wheel::todo::reset_lists() {
    wheel::todo::_reset "selected_list_index" "selected_list" "current_list"
}

function wheel::todo::select_list() {
    wheel::todo::_select_item \
        "current_list" \
        "selected_list_index" \
        "lists" \
        "$(wheel::state::get "selected_list")"
}

function wheel::todo::add_list() {
    next_screen="Create List"
}

function wheel::todo::delete_list() {
    next_screen="Delete List"
}

function wheel::todo::update_list() {
    next_screen="Update List"
}

function wheel::todo::_add_to_list() {
    local index
    local selected_index=$1
    local selected_list=$2
    local current_list=$3
    index=$(wheel::state::get "$selected_index")
    [ -z "$index" ] && index=$(wheel::state::get "$selected_list | length")
    wheel::state::set "${selected_list}[$index]" "$(wheel::state::get "$current_list")" argjson
}

function wheel::todo::_remove_from_list() {
    local selected_list=$1
    local current_item=$2
    local result
    local item_name
    item_name=$(wheel::state::get "${current_item}.name")
    result=$(wheel::state::get " | [.${selected_list}[] | select(.name != \"$item_name\")]")
    wheel::state::set "$selected_list" "$result" argjson
}

function wheel::todo::_reset() {
    local field
    for field in "$@"; do
        wheel::state::del "$field"
    done
}

function wheel::todo::_select_item() {
    local index=0
    local current_item=$1
    local selected_index=$2
    local selected_list=$3
    local selected_item=$4
    local old_ifs=$IFS
    IFS=$'\n'
    for entry in $(wheel::state::get "${selected_list}[]?" -c); do
        local name
        name=$(wheel::json::get "$entry" "name")
        if [ "$name" = "$selected_item" ]; then
            wheel::state::set "$current_item" "$entry" argjson
            wheel::state::set "$selected_index" "$index" argjson
            break
        fi
        index=$((index + 1))
    done
    IFS=$old_ifs
}

#### Snippet below adapted from the Recipes

function wheel::recipes::add_to_list() {
    wheel::todo::_add_to_list "selected_index" "$(wheel::state::get "selected_list")" "current_item"
}

function wheel::recipes::remove_from_list() {
    wheel::todo::_remove_from_list "$(wheel::state::get "selected_list")" "current_item"
}

function wheel::recipes::reset() {
    wheel::todo::_reset "selected_index" "selected_item" "current_item"
}

function wheel::recipes::select_item() {
    wheel::todo::_select_item \
        "current_item" \
        "selected_index" \
        "$(wheel::state::get "selected_list")" \
        "$(wheel::state::get "selected_item")"
}

function wheel::recipes::add_item() {
    next_screen="Create Item"
}

function wheel::recipes::delete_item() {
    next_screen="Delete Item"
}