#!/usr/bin/env bats

setup() {
    load 'test_helper/common'
    wheel::test::setup
    . wheel/log/module.sh
    . wheel/constants.sh
    TMP_FILE=$(mktemp)
    trap "rm -rf $tmp_file" EXIT
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

@test "wheel::log::set_file" {
    assert [ "$LOG_FILE" = "/dev/null" ]
    wheel::log::set_file "$TMP_FILE"
    assert [ "$LOG_FILE" = "$TMP_FILE" ]
}

@test "wheel::log::write" {
    LOG_FILE=$TMP_FILE
    wheel::log::write "$LOG_DEBUG" "this is skipped"
    wheel::log::write "$LOG_TRACE" "this is skipped"
    wheel::log::write "$LOG_INFO" "this is not skipped"
    wheel::log::write "$LOG_ERROR" "this is not skipped"

    assert [ "$(wc -l < $TMP_FILE)" -eq 2 ]
    assert [ "$(grep INFO < "$TMP_FILE" | wc -l)" -eq 1 ]
    assert [ "$(grep ERROR < "$TMP_FILE" | wc -l)" -eq 1 ]
}

@test "wheel::log::stream" {
    LOG_FILE=$TMP_FILE
    (
        for index in {0..9}; do
            echo "Something at $index"
        done
    ) |
    wheel::log::stream wheel::log::info
    assert [ "$(wc -l < $TMP_FILE)" -eq 10 ]
}

@test "wheel::log::trace" {
    LOG_FILE=$TMP_FILE
    wheel::log::trace "Skipped"
    wheel::log::set_level "TRACE"
    wheel::log::trace "There"

    assert [ "$(grep TRACE < $TMP_FILE | wc -l) " -eq 1 ]
}

@test "wheel::log::debug" {
    LOG_FILE=$TMP_FILE
    wheel::log::debug "Skipped"
    wheel::log::set_level "DEBUG"
    wheel::log::debug "There"

    assert [ "$(grep DEBUG < $TMP_FILE | wc -l) " -eq 1 ]
}

@test "wheel::log::info" {
    LOG_FILE=$TMP_FILE
    wheel::log::info "There"

    assert [ "$(grep INFO < $TMP_FILE | wc -l) " -eq 1 ]
}

@test "wheel::log::warn" {
    LOG_FILE=$TMP_FILE
    wheel::log::warn "There"

    assert [ "$(grep WARN < $TMP_FILE | wc -l) " -eq 1 ]
}

@test "wheel::log::error " {
    LOG_FILE=$TMP_FILE
    wheel::log::error "There"

    assert [ "$(grep ERROR < $TMP_FILE | wc -l) " -eq 1 ]
}

@test "wheel::log::fatal" {
    LOG_FILE=$TMP_FILE
    wheel::log::fatal "There"

    assert [ "$(grep FATAL < $TMP_FILE | wc -l) " -eq 1 ]
}