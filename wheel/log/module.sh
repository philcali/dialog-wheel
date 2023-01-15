#!/usr/bin/env bash

LOG_THRESHOLD="1"
LOG_FILE="/dev/null"
LOG_LEVEL="INFO"
LOG_LEVELS_TO_LABEL=("DEBUG" "INFO" "WARN" "ERROR")

function wheel::log::set_level() {
    LOG_LEVEL=$1
    case "$LOG_LEVEL" in
        "DEBUG") LOG_THRESHOLD=$LOG_DEBUG;;
        "INFO") LOG_THRESHOLD=$LOG_INFO;;
        "WARN") LOG_THRESHOLD=$LOG_WARN;;
        "ERROR") LOG_THRESHOLD=$LOG_ERROR;;
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

    if [ $LOG_THRESHOLD -ge "$level" ]; then
        echo "[${LOG_LEVELS_TO_LABEL[$level]}] $(date -u +%Y-%m-%dT%H:%M:%SZ) - ${rest[*]}" >> $LOG_FILE
    fi
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

function wheel::log::debug() {
    wheel::log::write "$LOG_DEBUG" "$@"
}
