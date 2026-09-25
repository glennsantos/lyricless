#!/bin/bash

if [ "$#" -ne 1 ] || [ ! -d "$1" ]; then
    echo "Usage: $0 <directory>" >&2
    exit 1
fi

TARGET_DIR="$(cd "$1" && pwd)" || exit 1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_EXEC="${LYRICLESS_PYTHON:-$SCRIPT_DIR/separator_venv/bin/python}"
CLI_SCRIPT="$SCRIPT_DIR/vocal_remover_cli.py"
OUTPUT_FOLDER="$TARGET_DIR/instrumentals"

if [ ! -x "$PYTHON_EXEC" ]; then
    echo "Error: Python interpreter not found: $PYTHON_EXEC" >&2
    exit 1
fi
mkdir -p "$OUTPUT_FOLDER" || exit 1

processed=0
skipped=0
failed=0
while IFS= read -r -d '' file; do
    relative="${file#"$TARGET_DIR"/}"
    parent="$(dirname "$relative")"
    name="$(basename "$relative")"
    stem="${name%.*}"
    if [ "$parent" = . ]; then
        destination="$OUTPUT_FOLDER/${stem}_instrumental.mp3"
    else
        destination="$OUTPUT_FOLDER/$parent/${stem}_instrumental.mp3"
    fi
    if [ ! -L "$destination" ] && [ -f "$destination" ] && [ -s "$destination" ]; then
        skipped=$((skipped + 1))
        printf 'Skipped: %s\n' "$relative"
        continue
    fi
    if ! mkdir -p "$(dirname "$destination")"; then
        failed=$((failed + 1))
        printf 'Failed: %s\n' "$relative" >&2
        continue
    fi
    if "$PYTHON_EXEC" "$CLI_SCRIPT" "$file" "$destination" --overwrite; then
        processed=$((processed + 1))
        printf 'Processed: %s\n' "$relative"
    else
        failed=$((failed + 1))
        printf 'Failed: %s\n' "$relative" >&2
    fi
done < <(find "$TARGET_DIR" -path "$OUTPUT_FOLDER" -prune -o -type f -iname '*.mp3' ! -iname '*_instrumental.mp3' -print0)

printf 'Processed: %d\nSkipped: %d\nFailed: %d\n' "$processed" "$skipped" "$failed"
if [ "$failed" -gt 0 ]; then
    exit 2
fi
