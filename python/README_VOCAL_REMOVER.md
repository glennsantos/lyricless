# Vocal Remover CLI

A command-line tool to remove vocals from audio files using Spleeter's AI model.

## Requirements

- Python 3.8+
- Spleeter and dependencies (see `requirements.txt`)

## Installation

1. Navigate to the python directory:
   ```bash
   cd python
   ```

2. Activate the virtual environment (if not already active):
   ```bash
   source venv/bin/activate
   ```

3. Dependencies are already installed if you've set up the project. If not:
   ```bash
   pip install -r requirements.txt
   ```

## Usage

### Basic Usage

Remove vocals from an MP3 file (creates `input_instrumental.mp3`):
```bash
python vocal_remover_cli.py song.mp3
```

### Specify Output Filename

```bash
python vocal_remover_cli.py song.mp3 karaoke.mp3
```

### Quiet Mode

Suppress progress messages:
```bash
python vocal_remover_cli.py song.mp3 -q
```

### Help

View all options:
```bash
python vocal_remover_cli.py --help
```

## Supported Formats

- **Input**: MP3, WAV, M4A, FLAC
- **Output**: MP3 (320kbps), WAV

## How It Works

The tool uses Spleeter's pre-trained 2-stems model to separate audio into:
- **Vocals** (discarded)
- **Accompaniment/Instrumental** (saved as output)

The model is already included in this repository at `pretrained_models/2stems/`.

## Examples

```bash
# Process a song from your music library
python vocal_remover_cli.py ~/Music/mysong.mp3

# Create karaoke version
python vocal_remover_cli.py track.mp3 karaoke_version.mp3

# Batch process (shell loop)
for file in *.mp3; do
    python vocal_remover_cli.py "$file"
done
```

## Output

The instrumental track will be saved as an MP3 file (320kbps for high quality). Processing time varies based on song length, typically 30-60 seconds for a 3-minute song.

## Troubleshooting

**Error: "Spleeter model not found"**
- The model should be at `pretrained_models/2stems/`. If missing, run the model conversion script first.

**Error: "Input file not found"**
- Check that the file path is correct and the file exists.

**Error: "Unsupported audio format"**
- Only MP3, WAV, M4A, and FLAC files are supported.
