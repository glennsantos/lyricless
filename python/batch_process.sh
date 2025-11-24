#!/bin/bash

# Check if a directory was provided
if [ -z "$1" ]; then
    echo "Usage: $0 <directory_path>"
    echo "Example: $0 /Users/aryeh/Music/MySongs"
    exit 1
fi

TARGET_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_EXEC="$SCRIPT_DIR/venv/bin/python"
CLI_SCRIPT="$SCRIPT_DIR/vocal_remover_cli.py"
OUTPUT_FOLDER="$TARGET_DIR/instrumentals"

# Check if Python environment exists
if [ ! -f "$PYTHON_EXEC" ]; then
    echo "Error: Virtual environment not found at $SCRIPT_DIR/venv"
    echo "Please run this script from the python directory or ensure venv is set up."
    exit 1
fi

# Create output folder if it doesn't exist
mkdir -p "$OUTPUT_FOLDER"

echo "=================================================="
echo "Batch Vocal Remover"
echo "Target Directory: $TARGET_DIR"
echo "Output Folder: $OUTPUT_FOLDER"
echo "=================================================="

# Find all MP3 files recursively and process them one by one
find "$TARGET_DIR" -name "*.mp3" -not -name "*_instrumental.mp3" | while read -r file; do
    filename=$(basename "$file")
    basename_without_ext="${filename%.mp3}"
    output_file="$OUTPUT_FOLDER/${basename_without_ext}_instrumental.mp3"

    echo ""

    # Check if instrumental version already exists
    if [ -f "$output_file" ]; then
        echo "⏭️  Skipping: $filename (instrumental already exists)"
        continue
    fi

    echo "Processing: $filename"

    # Run the vocal remover with explicit output path
    # We don't use --json-progress here so we get human readable output
    "$PYTHON_EXEC" "$CLI_SCRIPT" "$file" "$output_file"

    if [ $? -eq 0 ]; then
        echo "✅ Done"
    else
        echo "❌ Failed to process $filename"
    fi

done

echo ""
echo "=================================================="
echo "Batch processing complete!"
echo "=================================================="
