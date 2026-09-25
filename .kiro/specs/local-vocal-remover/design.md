# CLI design

`python/vocal_remover_cli.py` is the single-file entry point. Validate input and output paths and select the encoder before loading the separator. Write Spleeter output into a unique directory under the output parent, then atomically publish the completed accompaniment. Clean only that directory on success, failure, or interruption.

`python/batch_process.sh` discovers MP3 files with null-delimited names, prunes `instrumentals/`, preserves relative paths, and aggregates results in the current shell. It skips only nonempty regular outputs.

`python/run_vocal_remover.sh` selects the local virtual environment when present and forwards arguments. See `openspec/changes/cli-reliability-and-documentation/specs/` for the behavior contract.
