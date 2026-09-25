# Lyricless CLI vocal remover

Lyricless uses [Audio Separator](https://github.com/nomadkaraoke/python-audio-separator) and its `instrumental_clean` ensemble to make an instrumental stem from one audio file or a directory of MP3 files. The ensemble is designed to reduce vocal bleed. Source separation still cannot guarantee that every lyric disappears, so listen to each result before using it.

## Installation

Use Python 3.10 or newer (except 3.14.1). Install `ffmpeg` and make it available on `PATH`. On macOS with Homebrew, run `brew install ffmpeg`. Keep this environment separate from the old `python/venv`, which contains Spleeter.

```bash
git clone https://github.com/glennsantos/lyricless.git
cd lyricless
python3.11 -m venv python/separator_venv
python/separator_venv/bin/python -m pip install -r python/requirements.txt
python/separator_venv/bin/python -m pip check
```

The first conversion downloads two model checkpoints into `python/model_cache/` (about 1.1 GB total). Keep that directory for offline reuse. On Apple Silicon, Audio Separator uses the MPS device when available. The [Audio Separator documentation](https://github.com/nomadkaraoke/python-audio-separator#usage-) describes the model preset and platform support.

## One file

```bash
python/separator_venv/bin/python python/vocal_remover_cli.py /path/to/song.mp3
python/separator_venv/bin/python python/vocal_remover_cli.py /path/to/song.wav /path/to/karaoke.wav
python/separator_venv/bin/python python/vocal_remover_cli.py /path/to/song.mp3 /path/to/karaoke.mp3 --overwrite
```

Inputs may be MP3, WAV, M4A, or FLAC. The default output is `<stem>_instrumental.mp3` beside the input. Explicit outputs may use `.mp3` or `.wav`. Existing outputs require `--overwrite`. The CLI rejects an output that identifies the input, including a hard link or symbolic link. Conversion uses an isolated temporary directory and publishes a completed file atomically.

Exit codes are 0 for success, 1 for invalid arguments or paths, 2 for separation or encoding failure, and 130 for interruption. Human-readable errors go to stderr. `--json-progress` writes one JSON object per stdout line. Stage records contain `progress` and `status`; a successful run ends with `{"success": true, "output_path": "..."}`. Progress values mark stages and do not measure separation percentage.

## Batch MP3 conversion

```bash
./python/batch_process.sh /path/to/music
```

The batch command writes under `/path/to/music/instrumentals/` and preserves relative directories. For example, `a/song.mp3` becomes `instrumentals/a/song_instrumental.mp3`. It excludes the output tree from discovery, handles spaces and newlines in filenames, prints processed, skipped, and failed counts, and exits nonzero if any conversion fails. It skips a target only if a nonempty regular file already exists. This check does not prove the file decodes or uses the new model. Delete an old target before rerunning it.

## Verification status

The command-level tests use a stub separator and pass with `python3 -m unittest discover -s tests -v`. Both shell wrappers pass `bash -n` and ShellCheck. A clean macOS arm64 Python 3.11 environment passed `pip check`. Two complete MP3 outputs decoded with `ffmpeg`. In one 40-second sample, Whisper recognized 32 words in both the original and Spleeter output, and only "music" in the new output. Across the two complete tracks, recognized word counts fell from 469 to 10 and from 288 to 11. Transcription is a proxy for intelligible lyrics, not a guarantee of silence. Other platforms have not been tested. This is a local CLI with no hosted service deployment target.
