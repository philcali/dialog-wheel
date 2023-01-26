#!/usr/bin/env bash

set -e

OUTPUT="${1:-"dialog-wheel"}"
touch "$OUTPUT" || {
    echo >&2 "Failed to create $OUTPUT"
    exit 1
}

{
    cat wheel/constants.sh
} > "$OUTPUT"
chmod +x "$OUTPUT"

while IFS= read -r -d '' module; do
    echo "Adding module $(basename "$(dirname "$module")")"
    {
        echo
        echo "# ======== BEGIN $module ======== #"
        tail -n +2 "$module"
        echo
        echo "# ======== END $module ======== #"
    } >> "$OUTPUT"
done < <(find . -name "module.sh" -print0)

{
    echo 'wheel::app::init "$@"'
    echo 'wheel::app::run'
} >> "$OUTPUT"

echo "[SUCCESS] Compiled program written to: $OUTPUT"
echo "================== Invoking help ==================="
bash "$OUTPUT" -h