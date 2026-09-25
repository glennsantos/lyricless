# Lyricless CLI requirements

## Single-file conversion

Run `python vocal_remover_cli.py INPUT [OUTPUT]` for an MP3, WAV, M4A, or FLAC input. Without OUTPUT, write `<stem>_instrumental.mp3` beside the input. Explicit output accepts `.mp3` or `.wav` only. Reject unsupported input and output extensions before model loading.

Refuse a missing input, an output that identifies the input through its path, symbolic link, or hard link, and an existing output unless `--overwrite` is present. A failed or interrupted run must keep input and prior output bytes and remove only that run's temporary files. Publish completed output atomically.

Exit 0 on success, 1 for invalid arguments or paths, 2 for separation or encoding errors, and 130 on interruption. Write human-readable errors to stderr. With `--json-progress`, write one JSON object per stdout line. Stage records have `progress` between 0 and 1 and `status`; the last successful record has `success: true` and `output_path`. Progress numbers are stage markers.

The first run requires the Spleeter model download. Without a cached model and network access, the command fails without publishing output. A checked model setup path must be documented.

## Batch conversion

Run `./batch_process.sh DIRECTORY` to discover MP3 inputs recursively. Keep relative directories under `DIRECTORY/instrumentals/`; `a/song.mp3` maps to `instrumentals/a/song_instrumental.mp3`. Do not search the output tree. Preserve whitespace and newlines in filenames.

Skip an input only if its target is a nonempty regular file. This check does not prove that the file decodes. Continue after individual failures and print processed, skipped, and failed counts. Return nonzero if any conversion fails.

## Acceptance commands

Use command-level tests with a stub separator for file identity, failures, JSON records, format choices, duplicate basenames, unusual filenames, and batch counts. Use a clean environment and a short real input to check installation, decoding, and default output naming. Run `bash -n` on both wrappers.
