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