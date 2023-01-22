#!/usr/bin/env bash

: "${VERSION=1.0.0}"

# Dialog return codes
: "${DIALOG_OK=0}"
: "${DIALOG_CANCEL=1}"
: "${DIALOG_HELP=2}"
: "${DIALOG_EXTRA=3}"
: "${DIALOG_TIMEOUT=5}"
: "${DIALOG_ERROR=254}"
: "${DIALOG_NOT_FOUND=127}"
: "${DIALOG_ESC=255}"

: "${LOG_TRACE=0}"
: "${LOG_DEBUG=1}"
: "${LOG_INFO=2}"
: "${LOG_WARN=3}"
: "${LOG_ERROR=4}"
: "${LOG_FATAL=5}"

: "${SIG_INT=2}"