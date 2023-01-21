#!/usr/bin/env bats

setup() {
    load 'test_helper/common'
    wheel::test::setup
    . wheel/log/module.sh
    . wheel/constants.sh
}

@test "wheel::log::set_level" {
    assert [ "$LOG_THRESHOLD" = "$LOG_INFO" ]
    for thres in "${!LOG_LEVELS_TO_LABEL[@]}"; do
        local level="${LOG_LEVELS_TO_LABEL[$thres]}"
        wheel::log::set_level "$level"
        assert [ "$LOG_LEVEL" = "$level" ]
        assert [ "$LOG_THRESHOLD" = "$thres" ]
    done
    wheel::log::set_level "FARTS"
    assert [ "$LOG_LEVEL" = "INFO" ]
    assert [ "$LOG_THRESHOLD" = "$LOG_INFO" ]
}