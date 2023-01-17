#!/usr/bin/env bash

function application::example::hello_world() {
    # Delegates to the library method, however the following exist in env:
    # $screen
    # $dialog_options
    # $title
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