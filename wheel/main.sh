#!/usr/bin/env bash

DIR=$(dirname "$(realpath "$0")")
. "$DIR"/constants.sh
. "$DIR"/handlers/module.sh
. "$DIR"/log/module.sh
. "$DIR"/stack/module.sh
. "$DIR"/json/module.sh
. "$DIR"/events/module.sh
. "$DIR"/screens/module.sh
. "$DIR"/state/module.sh
. "$DIR"/utils/module.sh
. "$DIR"/app/module.sh

wheel::app::init "$@"
wheel::app::run