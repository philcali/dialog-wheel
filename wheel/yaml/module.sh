#!/usr/bin/env bash

function wheel::yaml::is_supported() {
    command -v python3 >/dev/null && python3 -c 'import yaml'
}

function wheel::yaml::to_json() {
    local possible_input=${1:-""}
    local python_input="open('$possible_input')"
    if [ -z "$possible_input" ]; then
        python_input="sys.stdin"
    fi
    python3 -c "import sys;import yaml;import json;print(json.dumps(yaml.safe_load($python_input)))"
}

function wheel::yaml::from_json() {
    local possible_input=${1:-""}
    local python_input="'$possible_input'"
    if [ -z "$possible_input" ]; then
        python_input="sys.stdin"
    fi
    python3 -c "import sys;import yaml;import json;print(yaml.safe_dump(json.load($python_input)))"
}