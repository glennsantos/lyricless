#!/bin/bash
# run_vocal_remover.sh

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Check if venv exists
if [ -d "venv" ]; then
    echo "Using virtual environment..."
    PYTHON_CMD="./venv/bin/python"
else
    echo "Virtual environment not found. Using system python3..."
    PYTHON_CMD="python3"
fi

# Check arguments
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <input_audio_file> [output_file]"
    exit 1
fi

echo "Running vocal remover on: $1"
$PYTHON_CMD vocal_remover_cli.py "$@"
