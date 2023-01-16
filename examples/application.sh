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