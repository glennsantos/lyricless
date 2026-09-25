# Proposal

## Why

The current CLI can overwrite source audio, publish partial output, and report batch success after failed files. Its documentation and older player specifications also contradict the program's behavior. The repository needs one tested CLI contract before users can rely on it.

## What changes

- Define the supported single-file and batch behavior, output formats, errors, progress records, and model setup.
- Protect inputs and previous outputs with path checks, isolated temporary files, and atomic publication.
- Use MP3 for default output across all supported input formats; accept only verified encoder formats for explicit output.
- Preserve relative paths in batch output, handle unusual filenames, and report accurate counts and failure status.
- Pin a reproducible dependency set, test user-visible behavior and a real audio conversion, and align the README and legacy specifications.
- Remove unused tracked model assets after confirming that no supported workflow loads them.

## Capabilities

### New capabilities

- `single-file-separation`: Input validation, output format and naming, safe publication, errors, progress, and model availability.
- `batch-separation`: Recursive MP3 discovery, output layout, skip policy, and aggregate results.

### Modified capabilities

None. OpenSpec has no existing capability specs.

## Impact

`python/vocal_remover_cli.py`, `python/batch_process.sh`, `python/run_vocal_remover.sh`, `python/requirements.txt`, `README.md`, `.kiro/specs/`, tests, and potentially `assets/models/`.
