#!/usr/bin/env bats

setup() {
    load 'test_helper/common'
    wheel::test::setup
    . wheel/json/module.sh
    JSON_SOURCE=$(cat example.json)
}

@test "wheel::json::validate" {
    local input="not a valid JSON value"
    refute wheel::json::validate "$input"
    assert wheel::json::validate "{}"
}

@test "wheel::json::get" {
    assert [ "$(wheel::json::get "$JSON_SOURCE" "dialog.backtitle")" = "Example App" ]
    assert [ "$(wheel::json::get "$JSON_SOURCE" "screens[\$screen].dialog.title" --arg screen "1 Checklist")" = "List Checklist" ]
}

@test "wheel::json::set" {
    local updated=$(wheel::json::set "$JSON_SOURCE" "dialog.backtitle" "Test Title")

    assert [ "$(wheel::json::get "$updated" "dialog.backtitle")" = "Test Title" ]
    assert [ "$(wheel::json::get "$JSON_SOURCE" "dialog.backtitle")" = "Example App" ]
}

@test "wheel::json::del" {
    local updated=$(wheel::json::del "$JSON_SOURCE" "dialog")

    assert [ "$(wheel::json::get "$updated" "dialog.backtitle")" = "null" ]
    assert [ "$(wheel::json::get "$JSON_SOURCE" "dialog.backtitle")" = "Example App" ]
    assert [ "$(wheel::json::get "$JSON_SOURCE" "version")" = "$(wheel::json::get "$updated" "version")" ]
}

@test "wheel::json::get_or_default" {
    local height=$(wheel::json::get_or_default "$JSON_SOURCE" "properties.height" "10")
    local title=$(wheel::json::get_or_default "$JSON_SOURCE" "dialog.backtitle" "Test Title")

    assert [ "$height" -eq 10 ]
    refute [ "$title" = "Test Title" ]
}

@test "wheel::json::merge" {
    local expected
    local updated
    local screen
    screen=$(wheel::json::get "$JSON_SOURCE" "screens[\$screen]" --arg screen "Welcome")
    expected=$(wheel::json::merge "$JSON_SOURCE" "Welcome")
    updated=$(wheel::json::merge "$JSON_SOURCE" "Welcome" dialog)
    assert [ "$expected" = "$updated" ]

    updated=$(wheel::json::del "$JSON_SOURCE" "dialog")
    expected=$(wheel::json::merge "$updated" "Welcome")
    assert [ "$expected" = "$screen" ]
}

@test "wheel::json::is_null" {
    assert wheel::json::is_null "$(wheel::json::get "$JSON_SOURCE" "farts.mcgeehee")"
    refute wheel::json::is_null "Value"
}