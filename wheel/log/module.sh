#!/usr/bin/env bash

LOG_THRESHOLD="1"
LOG_FILE="/dev/null"
LOG_LEVEL="INFO"
LOG_LEVELS_TO_LABEL=("TRACE" "DEBUG" "INFO" "WARN" "ERROR" "FATAL")

function wheel::log::set_level() {
    LOG_LEVEL=$1
    case "$LOG_LEVEL" in
        "TRACE") LOG_THRESHOLD=$LOG_TRACE;;
        "DEBUG") LOG_THRESHOLD=$LOG_DEBUG;;
        "INFO") LOG_THRESHOLD=$LOG_INFO;;
        "WARN") LOG_THRESHOLD=$LOG_WARN;;
        "ERROR") LOG_THRESHOLD=$LOG_ERROR;;
        "FATAL") LOG_THRESHOLD=$LOG_FATAL;;
        *) LOG_THRESHOLD=$LOG_INFO;;
    esac
}

function wheel::log::set_file() {
    LOG_FILE=$1
}

function wheel::log::write() {
    local level=$1
    shift
    local rest=("$@")

    if [ "$level" -ge "$LOG_THRESHOLD" ]; then
        echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) [${LOG_LEVELS_TO_LABEL[$level]}] ${rest[*]}" >> $LOG_FILE
    fi
}

function wheel::log::stream() {
    local logger=("$@")
    local line
    while read -r line; do
        "${logger[@]}" "$line"
    done
}

function wheel::log::info() {
    wheel::log::write "$LOG_INFO" "$@"
}

function wheel::log::warn() {
    wheel::log::write "$LOG_WARN" "$@"
}

function wheel::log::error() {
    wheel::log::write "$LOG_ERROR" "$@"
}

function wheel::log::fatal() {
    wheel::log::write "$LOG_ERROR" "$@"
}

function wheel::log::trace() {
    wheel::log::write "$LOG_TRACE" "$@"
}

function wheel::log::debug() {
    wheel::log::write "$LOG_DEBUG" "$@"
}
