# Lyricless CLI Vocal Remover

A powerful command-line tool to remove vocals from audio files using AI. Built with [Spleeter](https://github.com/deezer/spleeter).

## Features

- **AI-Powered Separation**: Uses the Spleeter 2-stem model to separate vocals from accompaniment.
- **High Quality**: Outputs 320kbps MP3 instrumentals.
- **Batch Processing**: Easily process entire folders of music.
- **Multiple Formats**: Supports MP3, WAV, M4A, and FLAC inputs.
- **Offline**: Runs entirely locally on your machine.

## Installation

1.  **Clone the repository** (if you haven't already):
    ```bash
    git clone https://github.com/yourusername/lyricless.git
    cd lyricless
    ```

2.  **Navigate to the python directory:**
    ```bash
    cd python
    ```

3.  **Create and activate a virtual environment:**
    ```bash
    python3 -m venv venv
    source venv/bin/activate
    ```

4.  **Install dependencies:**
    ```bash
    pip install -r requirements.txt
    ```
    *Note: This will install TensorFlow, Spleeter, and other necessary libraries.*

## Usage

### Single File Processing

Use the `vocal_remover_cli.py` script to process a single file.

```bash
# Basic usage (creates <input>_instrumental.mp3)
python3 vocal_remover_cli.py /path/to/song.mp3

# Specify custom output path
python3 vocal_remover_cli.py /path/to/song.mp3 /path/to/karaoke_version.mp3

# Quiet mode (suppress progress bars)
python3 vocal_remover_cli.py /path/to/song.mp3 -q
```

### Batch Processing

Use the `batch_process.sh` script to process an entire folder of MP3s.

```bash
# Process all MP3s in a directory
./batch_process.sh /Users/aryeh/Music/MySongs
```
*   Creates an `instrumentals` folder inside the target directory.
*   Skips files that have already been processed.

## Requirements

- Python 3.8+
- ffmpeg (usually required by Spleeter/Librosa for audio processing)

## Troubleshooting

**"Spleeter model not found"**
The script should automatically download the model on the first run. If it fails, ensure you have an internet connection.

**Audio loading errors**
Ensure `ffmpeg` is installed on your system (`brew install ffmpeg` on macOS).
