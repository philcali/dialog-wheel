#!/usr/bin/env bats

setup() {
    load 'test_helper/common'
    wheel::test::setup
    . wheel/constants.sh
    . wheel/state/module.sh
    . wheel/log/module.sh
    . wheel/json/module.sh
    . wheel/handlers/module.sh
    . wheel/stack/module.sh
    . wheel/screens/module.sh
    . wheel/app/module.sh
    . wheel/utils/module.sh
    . wheel/yaml/module.sh
    . wheel/functions/module.sh
}

@test "wheel::app::init" {
    assert wheel::app::init \
        -s "Main Menu" -i "example.json" \
        -l "application.log" -L "DEBUG" \
        -o "output.json"
    [ "$START_SCREEN" = "Main Menu" ]
    [ "$INPUT_SOURCE" = "example.json" ]
    [ "$LOG_LEVEL" = "DEBUG" ]
    [ "$LOG_THRESHOLD" = "$LOG_DEBUG" ]
    [ "$OUTPUT_PATH" = "output.json" ]
}

@test "wheel::app::run - json" {
    INPUT_SOURCE=$(mktemp)
    trap "rm -rf $INPUT_SOURCE" EXIT
    DIALOG_TIMEOUT=5
    cat << EOF > $INPUT_SOURCE
{
    "version": "$VERSION",
    "start": "Start",
    "screens": {
        "Start": {
            "type": "msgbox",
            "properties": {
                "text": "This is a message"
            },
            "dialog": {
                "timeout": 1
            },
            "handlers": {
                "timeout": "wheel::handlers::ok"
            }
        }
    }
}
EOF
    assert wheel::app::run
}

@test "wheel::app::run - yaml" {
    INPUT_SOURCE=$(mktemp)
    YAML_PARSING="Y"
    trap "rm -rf $INPUT_SOURCE" EXIT
    DIALOG_TIMEOUT=5
    cat << EOF > $INPUT_SOURCE
version: "$VERSION"
start: Start
screens:
    Start:
        type: msgbox
        properties:
            text: "This is a message"
        dialog:
            timeout: 1
        handlers:
            timeout: wheel::handlers::ok
EOF
    assert wheel::app::run
}