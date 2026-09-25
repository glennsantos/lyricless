# Lyricless CLI vocal remover

Lyricless uses [Spleeter](https://github.com/deezer/spleeter) to write an instrumental stem from one audio file or a directory of MP3 files.

## Installation

The CLI targets Python 3.8 through 3.11, the range allowed by the pinned Spleeter release. Install `ffmpeg` and make it available on `PATH`. On macOS with Homebrew, run `brew install ffmpeg`. Spleeter also needs a compatible TensorFlow installation. A clean installation has **not** been verified on macOS arm64: Python 3.11 cannot resolve TensorFlow 2.12.1, and Python 3.9 cannot resolve the required `tensorflow-io-gcs-filesystem==0.32.0` package. Do not treat the repository's old `python/venv` as a working install; it contains Spleeter 2.4.0 rather than the pinned 2.4.2 and fails `pip check`.

```bash
git clone https://github.com/glennsantos/lyricless.git
cd lyricless
python3.11 -m venv python/venv
python/venv/bin/python -m pip install -r python/requirements.txt
python/venv/bin/python -m pip check
```

The first conversion downloads Spleeter's `2stems` model if absent. To prepare for offline use, run a short conversion while online and confirm it succeeds, then keep the resulting Spleeter model cache. The files in `assets/models/` were unrelated to this CLI and have been removed. If the model is missing while offline, the command fails without publishing an output. Spleeter's [getting started guide](https://github.com/deezer/spleeter/wiki/2.-getting-started) describes the first-run download.

## One file

```bash
python/venv/bin/python python/vocal_remover_cli.py /path/to/song.mp3
python/venv/bin/python python/vocal_remover_cli.py /path/to/song.wav /path/to/karaoke.wav
python/venv/bin/python python/vocal_remover_cli.py /path/to/song.mp3 /path/to/karaoke.mp3 --overwrite
```

Inputs may be MP3, WAV, M4A, or FLAC. The default output is `<stem>_instrumental.mp3` beside the input. Explicit outputs may use `.mp3` or `.wav`; these encoders still need a real conversion check on the documented installation. Existing outputs require `--overwrite`. The CLI rejects an output that identifies the input, including a hard link or symbolic link. Conversion uses an isolated temporary directory and publishes a completed file atomically.

Exit codes are 0 for success, 1 for invalid arguments or paths, 2 for separation or encoding failure, and 130 for interruption. Human-readable errors go to stderr. `--json-progress` writes one JSON object per stdout line. Stage records contain `progress` and `status`; a successful run ends with `{"success": true, "output_path": "..."}`. Progress values mark stages and do not measure separation percentage.

## Batch MP3 conversion

```bash
./python/batch_process.sh /path/to/music
```

The batch command writes under `/path/to/music/instrumentals/` and preserves relative directories. For example, `a/song.mp3` becomes `instrumentals/a/song_instrumental.mp3`. It excludes the output tree from discovery, handles spaces and newlines in filenames, prints processed, skipped, and failed counts, and exits nonzero if any conversion fails. It skips a target only if a nonempty regular file already exists. This check does not prove the file decodes. Delete a target to retry it.

## Verification status

The command-level tests use a stub separator and pass with `python3 -m unittest discover -s tests -v`. Both shell wrappers pass `bash -n` and ShellCheck. On macOS arm64, the existing Python 3.9 environment and cached Spleeter model produced MP3 and WAV outputs from a generated one-second WAV input; both outputs decoded with `ffmpeg`. That environment contains Spleeter 2.4.0 and fails `pip check`, so these smoke checks do not verify the pinned Spleeter 2.4.2 installation. Fresh Python 3.11 and 3.9 installs both failed dependency resolution as described above. The GitHub Actions workflow runs the stub-backed tests and static checks. Other platforms have not been tested. This is a local CLI and has no hosted service deployment target.
