#!/usr/bin/env bats

setup() {
    load 'test_helper/common'
    wheel::test::setup
    . wheel/constants.sh
    . wheel/screens/module.sh
    . wheel/log/module.sh
    . wheel/json/module.sh
    . wheel/state/module.sh
    . wheel/utils/module.sh
    . wheel/functions/module.sh

    DIALOG=("echo" "dialog")
    answer_file=$(mktemp)
    trap "rm -rf $answer_file" EXIT
}

@test "wheel::screens::msgbox" {
    screen='
    {
        "type": "msgbox",
        "dialog": {
            "title": "Title",
            "backtitle": "Test App",
            "cancel-button": true,
            "cancel-label": "Back"
        },
        "properties": {
            "text": "This is a statement of sorts."
        }
    }'

    local expected_cmd="dialog --backtitle Test App --cancel-button --cancel-label Back --title Title --msgbox This is a statement of sorts. 0 0"
    local actual_cmd=$(wheel::screens::new_screen "$screen" "$answer_file")
    assert [ "$expected_cmd" = "$actual_cmd" ]
}

@test "wheel::screens::yesno" {
    screen='
    {
        "type": "yesno",
        "dialog": {
            "title": "Title",
            "backtitle": "Test App",
            "cancel-button": true,
            "cancel-label": "Back"
        },
        "properties": {
            "text": "This is a statement of sorts."
        }
    }'

    local expected_cmd="dialog --backtitle Test App --cancel-button --cancel-label Back --title Title --yesno This is a statement of sorts. 0 0"
    local actual_cmd=$(wheel::screens::new_screen "$screen" "$answer_file")
    assert [ "$expected_cmd" = "$actual_cmd" ]
}

@test "wheel::screens::info" {
    screen='
    {
        "type": "info",
        "dialog": {
            "title": "WARNING",
            "colors": true
        },
        "properties": {
            "text": "This is a statement of sorts.",
            "width": 70
        }
    }'

    local expected_cmd="dialog --colors --title WARNING --infobox This is a statement of sorts. 0 70"
    local actual_cmd=$(wheel::screens::new_screen "$screen" "$answer_file")
    assert [ "$expected_cmd" = "$actual_cmd" ]
}

@test "wheel::screens::input" {
    APP_STATE="{\"username\": \"nobody\"}"
    screen='
    {
        "type": "input",
        "capture_into": "username",
        "dialog": {
            "title": "Username"
        },
        "properties": {
            "text": "Enter your username:"
        }
    }'
    local expected_cmd="dialog --title Username --inputbox Enter your username: 0 0 nobody"
    local actual_cmd=$(wheel::screens::new_screen "$screen" "$answer_file")
    assert [ "$expected_cmd" = "$actual_cmd" ]
}

@test "wheel::screens::password" {
    screen='
    {
        "type": "password",
        "capture_into": "password",
        "dialog": {
            "title": "Password",
            "insecure": true
        },
        "properties": {
            "text": "Enter your password:"
        }
    }'
    local expected_cmd="dialog --insecure --title Password --passwordbox Enter your password: 0 0 "
    local actual_cmd=$(wheel::screens::new_screen "$screen" "$answer_file")
    assert [ "$expected_cmd" = "$actual_cmd" ]
}

@test "wheel::screens::files" {
    screen='
    {
        "type": "files",
        "capture_into": "file",
        "dialog": {
            "title": "Select a File"
        }
    }'
    local expected_cmd="dialog --title Select a File --fselect  0 0"
    local actual_cmd=$(wheel::screens::new_screen "$screen" "$answer_file")
    assert [ "$expected_cmd" = "$actual_cmd" ]
}

@test "wheel::screens::calendar" {
    APP_STATE="{\"birthday\": \"19/11/1985\"}"
    screen='
    {
        "type": "calendar",
        "capture_into": "birthday",
        "dialog": {
            "title": "Birthday"
        }
    }'
    local expected_cmd="dialog --title Birthday --calendar  0 0 19 11 1985"
    local actual_cmd; actual_cmd=$(wheel::screens::new_screen "$screen" "$answer_file")
    assert [ "$expected_cmd" = "$actual_cmd" ]
}

@test "wheel::screens::hub" {
    screen='
    {
        "type": "hub",
        "dialog": {
            "title": "Main Menu"
        },
        "properties": {
            "box_height": 10,
            "items": [
                {
                    "name": "First",
                    "description": "this is the First label"
                },
                {
                    "name": "Second",
                    "description": "this is the Second label"
                }
            ]
        }
    }'
    local expected_cmd="dialog --title Main Menu --menu  0 0 10 First this is the First label Second this is the Second label"
    local actual_cmd; actual_cmd=$(wheel::screens::new_screen "$screen" "$answer_file")
    assert [ "$expected_cmd" = "$actual_cmd" ]
}

@test "wheel::screens::checklist - read from list" {
    APP_STATE="{\"favorites\": [\"Bourbon\"]}"
    screen='
    {
        "type": "checklist",
        "dialog": {
            "title": "Favorite Things"
        },
        "capture_into": "favorites",
        "properties": {
            "text": "Select your favorite things:",
            "items": [
                {
                    "name": "Chocolate",
                    "description": "Needs no introduction"
                },
                {
                    "name": "Bourbon",
                    "description": "American whiskey"
                }
            ]
        }
    }'
    local expected_cmd="dialog --title Favorite Things --checklist Select your favorite things: 0 0 5 Chocolate Needs no introduction off Bourbon American whiskey on"
    local actual_cmd; actual_cmd=$(wheel::screens::new_screen "$screen" "$answer_file")
    assert [ "$expected_cmd" = "$actual_cmd" ]
}

@test "wheel::screens::checklist - read from fields" {
    APP_STATE="{\"favorites\": {\"chocolate\": true}, \"fables\": {\"bourbon\": false}}"
    screen='
    {
        "type": "checklist",
        "dialog": {
            "title": "Favorite Things"
        },
        "capture_into": "favorites",
        "properties": {
            "text": "Select your favorite things:",
            "items": [
                {
                    "name": "Chocolate",
                    "description": "Needs no introduction",
                    "configures": "favorites.chocolate"
                },
                {
                    "name": "Bourbon",
                    "description": "American whiskey",
                    "configures": "favorites.bourbon",
                    "depends": "fables.bourbon"
                }
            ]
        }
    }'
    local expected_cmd="dialog --title Favorite Things --checklist Select your favorite things: 0 0 5 Chocolate Needs no introduction on"
    local actual_cmd; actual_cmd=$(wheel::screens::new_screen "$screen" "$answer_file")
    assert [ "$expected_cmd" = "$actual_cmd" ]
}

@test "wheel::screens::range" {
    APP_STATE="{\"selection\": 5}"
    screen='
    {
        "type": "range",
        "capture_into": "selection",
        "dialog": {
            "title": "Range Selection"
        },
        "properties": {
            "text": "Happiness",
            "default": "$state.selection"
        }
    }'
    local expected_cmd="dialog --title Range Selection --rangebox Happiness 0 0 0 10 5"
    local actual_cmd; actual_cmd=$(wheel::screens::new_screen "$screen" "$answer_file")
    assert [ "$expected_cmd" = "$actual_cmd" ]
}

@test "wheel::screens::gauge" {
    # Best to use a real dialog in this case
    DIALOG=("dialog")
    CURRENT_SCREEN="Install Screen"
    LOG_FILE="$(mktemp)"
    trap "rm -rf $LOG_FILE" EXIT
    screen='
    {
        "type": "gauge",
        "managed": true,
        "dialog": {
            "title": "Installation"
        },
        "properties": {
            "width": 70,
            "actions": [
                "wheel::test::gauge_managed_one",
                "wheel::test::gauge_managed_two"
            ]
        }
    }'
    assert wheel::screens::new_screen "$screen" "$answer_file"
    assert [ "$(grep gauge_managed_one < $LOG_FILE | wc -l)" -eq 1 ]
    assert [ "$(grep gauge_managed_two < $LOG_FILE | wc -l)" -eq 1 ]
}

@test "wheel::screens::textbox" {
    screen='
    {
        "type": "textbox",
        "dialog": {
            "title": "Open File"
        },
        "properties": {
            "text": "example.json"
        }
    }'
    local expected_cmd="dialog --title Open File --textbox example.json 0 0"
    local actual_cmd; actual_cmd=$(wheel::screens::new_screen "$screen" "$answer_file")
    assert [ "$expected_cmd" = "$actual_cmd" ]
}

@test "wheel::screens::editor" {
    screen='
    {
        "type": "editor",
        "dialog": {
            "title": "Edit File"
        },
        "properties": {
            "text": "example.json"
        }
    }'
    local expected_cmd="dialog --title Edit File --editbox example.json 0 0"
    local actual_cmd; actual_cmd=$(wheel::screens::new_screen "$screen" "$answer_file")
    assert [ "$expected_cmd" = "$actual_cmd" ]
}

@test "wheel::screens::form" {
    APP_STATE="{\"person\": {\"name\":\"nobody\"}}"
    screen='
    {
        "type": "form",
        "dialog": {
            "title": "Person Form",
            "insecure": true
        },
        "capture_into": "person",
        "properties": {
            "items": [
                {
                    "name": "Name:",
                    "required": true,
                    "length": 40
                },
                {
                    "name": "Age:",
                    "length": 3
                },
                {
                    "name": "Password:",
                    "required": true,
                    "length": 12,
                    "max": 32,
                    "type": 2
                }
            ]
        }
    }'
    local expected_cmd="dialog --insecure --title Person Form --mixedform  0 0 5 *Name: 1 1 nobody 1 12 40 40 0  Age: 2 1  2 12 3 3 0 *Password: 3 1  3 12 12 32 2"
    local actual_cmd; actual_cmd=$(wheel::screens::new_screen "$screen" "$answer_file")
    assert [ "$expected_cmd" = "$actual_cmd" ]
}

@test "wheel::screens::custom" {
    screen='
    {
        "type": "custom"
    }'
    refute wheel::screens::new_screen "$screen" "$answer_file"
    screen='
    {
        "type": "custom",
        "entrypoint": "date"
    }'
    assert wheel::screens::new_screen "$screen" "$answer_file"
}