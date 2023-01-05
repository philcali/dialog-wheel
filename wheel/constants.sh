#!/usr/bin/env bash

# Dialog return codes
: "${DIALOG_OK=0}"
: "${DIALOG_CANCEL=1}"
: "${DIALOG_HELP=2}"
: "${DIALOG_EXTRA=3}"
: "${DIALOG_TIMEOUT=5}"
: "${DIALOG_ESC=255}"

: "${SIG_INT=2}"