#!/usr/bin/env bash

: "${VERSION=1.0.0}"

# Dialog return codes
: "${DIALOG_OK=0}"
: "${DIALOG_CANCEL=1}"
: "${DIALOG_HELP=2}"
: "${DIALOG_EXTRA=3}"
: "${DIALOG_TIMEOUT=5}"
: "${DIALOG_ESC=255}"

: "${LOG_DEBUG=0}"
: "${LOG_INFO=1}"
: "${LOG_WARN=2}"
: "${LOG_ERROR=3}"

: "${SIG_INT=2}"