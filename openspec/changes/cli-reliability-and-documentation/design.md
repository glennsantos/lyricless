# Design

## Context

See `proposal.md`. The Python entry point currently uses a predictable temp directory beside the input, chooses a codec from the output suffix but expects the requested suffix even for unsupported formats, and moves the result directly to the final path. The batch shell script uses a pipe into `while read`, flattens paths, and loses conversion failures.

## Goals / non-goals

Goals: preserve source and existing output bytes on any failed run; make CLI and batch outcomes testable from their command-line interfaces; verify one reproducible installation on the target platform.

Non-goals: mobile playback, other audio inputs in batch mode, or a measured separation progress estimate.

## Decisions

### Validate paths before work

Resolve input and output paths and use same-file identity checks for existing paths. Refuse an existing output without `--overwrite`. This makes accidental replacement explicit. Reject a symlink output even with overwrite if it identifies the input. Check all conditions before loading the model.

### Publish within the output filesystem

Create a unique run directory under the output's parent so the completed file can be staged on the same filesystem. Keep Spleeter's files in that directory, then stage the chosen accompaniment at a temporary sibling path and use atomic replacement only after a complete encode. A context manager and interruption handler remove only that run directory. A temporary directory under a global system temp path was considered, but cross-filesystem moves would lose atomicity.

### Map formats in one place

Use MP3 for every default path. Keep a single extension-to-codec mapping, initially MP3 and WAV only if both pass an installed-version conversion check. The mapping determines the codec and expected `accompaniment` filename. M4A and FLAC remain inputs only. Do not advertise an output format until a real conversion confirms it.

### Keep batch state in the shell process

Use null-delimited `find` results without a pipeline subshell, prune the output tree, preserve relative parent paths, and maintain processed, skipped, and failed counters in the main shell. Skip only nonempty regular outputs and state this limited check in the README. Continue after each conversion error; return failure if the failed count is positive. A full decode check before every skip would add substantial work and require an extra dependency for each batch run.

### Test installation and behavior separately

Use a clean virtual environment for dependency resolution and one short real audio conversion on macOS. Fast command-level tests use a stub separator to simulate errors and verify file safety, JSON records, and batch behavior. Document only the platform and Python version actually checked. Inspect all references to `assets/models/` before removal; the Spleeter model cache under `python/pretrained_models/` is a separate concern.

## Risks / trade-offs

- A model download or encoder may fail on a clean machine. Pin versions only after a clean install and real conversion pass; report any untested platform.
- Filesystem atomic replacement protects the final pathname, but power-loss durability is not guaranteed without explicit sync. The contract covers process failure and interruption.
- The batch nonempty-file skip check can accept corrupt output. Document this limitation and let users remove the target to retry.

## Migration plan

Implement and check one risk-ordered task group at a time. Existing outputs become protected by default; users who intend replacement pass `--overwrite`. Update README and old `.kiro` documents in the same change. No deployed service or data migration is involved.
