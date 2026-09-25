# CLI design

`python/vocal_remover_cli.py` validates the input, output format, and destination before loading Audio Separator. Each conversion writes to a unique temporary directory under the output directory. Lyricless publishes the completed file atomically and removes the run directory on success, failure, or interruption.

The CLI uses Audio Separator's `instrumental_clean` ensemble and asks for the `Instrumental` stem. It stores model files under `python/model_cache/`. See [model sources and terms](../model-sources-and-terms.md) for the preset and checkpoint names.

`python/batch_process.sh` finds MP3 files with null-delimited paths, prunes the `instrumentals` output directory, preserves relative paths, and aggregates processed, skipped, and failed counts.

`python/run_vocal_remover.sh` selects `python/separator_venv` when present and forwards its arguments to the CLI. The documented setup uses the virtual environment created during installation.
