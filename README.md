# Lyricless

Lyricless is a local command-line tool that creates an instrumental stem from an audio file. It uses the `instrumental_clean` ensemble from [Audio Separator](https://github.com/nomadkaraoke/python-audio-separator). Separation can leave vocal bleed, so check the output before using it.

## Install

You need Python 3.10 or newer, except Python 3.14.1, and `ffmpeg` on `PATH`. Audio Separator excludes Python 3.14.1. Its Apple Silicon acceleration path requires macOS 14 or newer; this project has only been end-to-end tested on macOS arm64 with Python 3.11. See [supported environments](docs/support.md) for the verification limits.

On macOS with Homebrew:

```sh
brew install ffmpeg
git clone https://github.com/glennsantos/lyricless.git
cd lyricless
python3.11 -m venv python/separator_venv
python/separator_venv/bin/python -m pip install -r python/requirements.txt
python/separator_venv/bin/python -m pip check
```

The first conversion downloads two model checkpoints. Audio Separator stores them in `python/model_cache/`; keep that directory if you need to run offline later. See [model sources and terms](docs/model-sources-and-terms.md).

## Convert one file

```sh
python/separator_venv/bin/python python/vocal_remover_cli.py /path/to/song.mp3
python/separator_venv/bin/python python/vocal_remover_cli.py /path/to/song.wav /path/to/karaoke.wav
python/separator_venv/bin/python python/vocal_remover_cli.py /path/to/song.mp3 /path/to/karaoke.mp3 --overwrite
```

Inputs can be MP3, WAV, M4A, or FLAC. The default output is `<stem>_instrumental.mp3` beside the input. Explicit output paths can use `.mp3` or `.wav`. Existing outputs require `--overwrite`.

The CLI rejects an output path that identifies the input, including through a hard link or symbolic link. It writes to a temporary directory and publishes a completed output atomically.

Exit codes are 0 for success, 1 for invalid arguments or paths, 2 for separation or encoding errors, and 130 for interruption. Human-readable errors go to stderr. `--json-progress` writes JSON records to stdout. Progress values mark stages; they do not measure separation percentage.

## Convert a directory of MP3 files

```sh
./python/batch_process.sh /path/to/music
```

The batch command writes outputs under `/path/to/music/instrumentals/` and preserves relative directories. For example, `a/song.mp3` becomes `instrumentals/a/song_instrumental.mp3`. It skips an output only when a nonempty regular file already exists. Remove an old output to process that input again.

## Performance results

This repository does not publish quantitative separation results. An earlier README listed Whisper word counts without identifying the audio, transcription model version, or decoding settings, so those numbers could not be reproduced. See the [benchmark protocol](docs/performance.md) before publishing new measurements.

## Project docs

- [Command behavior](docs/specs/requirements.md)
- [Architecture](docs/specs/design.md)
- [Support and verification](docs/support.md)
- [Model sources and terms](docs/model-sources-and-terms.md)
- [Benchmark protocol](docs/performance.md)
- [Contributing](docs/contributing.md)
- [All documentation](docs/index.md)

The project is a local CLI. It has no hosted service or API deployment target.
