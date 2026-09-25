# CLI requirements

This document describes the command behavior implemented by Lyricless.

## Single-file conversion

Run `python python/vocal_remover_cli.py INPUT [OUTPUT]` for an MP3, WAV, M4A, or FLAC input. Without `OUTPUT`, write `<stem>_instrumental.mp3` beside the input. Explicit output accepts `.mp3` and `.wav`. Reject unsupported extensions before loading the separator.

Reject a missing input, an output that identifies the input through its path, symbolic link, or hard link, and an existing output unless `--overwrite` is present. A failed or interrupted run must preserve the input and any previous output. Remove only temporary files created by that run. Publish completed output atomically.

Exit with code 0 on success, 1 for invalid arguments or paths, 2 for separation or encoding errors, and 130 on interruption. Write human-readable errors to stderr. With `--json-progress`, write one JSON object per stdout line. Stage records have `progress` and `status` fields. The final successful record has `success: true` and `output_path`. Progress values mark stages. They do not measure separation percentage.

The first run needs network access to download model files unless the cache is already populated. Without a cached model and network access, conversion fails without publishing an output.

## Batch conversion

Run `./python/batch_process.sh DIRECTORY` to find MP3 inputs recursively. Preserve relative directories under `DIRECTORY/instrumentals/`. For example, `a/song.mp3` maps to `instrumentals/a/song_instrumental.mp3`. Exclude the output directory from discovery and preserve whitespace and newlines in names.

Skip an input only if its destination is a nonempty regular file. This check does not verify that the file decodes or came from the current model. Continue after individual failures. Print processed, skipped, and failed counts, and return nonzero if any conversion fails.

## Verification

`tests/test_cli.py` calls the CLI and batch script with a stub separator. The suite covers path identity, existing outputs, cleanup, output formats, JSON progress, batch path layout, unusual filenames, skip behavior, and batch failure status.
