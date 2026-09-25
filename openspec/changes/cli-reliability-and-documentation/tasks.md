# Tasks

## 1. Establish the CLI contract

- [ ] 1.1 Replace player requirements in `.kiro/specs/lyricless/requirements.md` and `.kiro/specs/local-vocal-remover/{design,tasks}.md` with command-checkable single-file and batch criteria; verify no active requirement mentions player, Flutter, playback, queues, or cache eviction.
- [ ] 1.2 Record a failing command or user-level test for source aliasing, existing output, format mismatch, batch basename collision, and batch failure status; verify each reproduces the stated defect before implementation.

## 2. Protect single-file conversion

- [ ] 2.1 Add preflight input/output identity and `--overwrite` checks, including symlinks and hard links; verify command-level tests preserve source and existing output bytes.
- [ ] 2.2 Isolate each conversion in a unique temporary directory, clean it on success/failure/interruption, and publish via atomic replacement; verify failure and interruption tests leave no partial output or shared run directory.
- [ ] 2.3 Update CLI help and single-file documentation for overwrite policy and exit codes; verify `--help` and documented commands match behavior.

## 3. Align formats and progress

- [ ] 3.1 Centralize the output extension/codec/temporary filename mapping and make MP3 the default for MP3, WAV, M4A, and FLAC input; verify command-level cases for all four input suffixes and each accepted output suffix.
- [ ] 3.2 Reject unsupported output extensions before model loading and keep JSON stdout parseable line by line; verify invalid-format and success/failure JSON command tests.
- [ ] 3.3 Update README and `.kiro` CLI criteria for actual formats and stage-marker progress; verify the examples and expected JSON fields against command output.

## 4. Make batch outcomes reliable

- [ ] 4.1 Preserve relative directories, prune `instrumentals/`, and use null-delimited discovery; verify duplicate basenames and filenames with whitespace/newlines through the batch command.
- [ ] 4.2 Count processed, skipped, and failed inputs, enforce the nonempty-regular-file skip rule, and fail the batch command when any conversion fails; verify summary counts and exit status with stub conversions.
- [ ] 4.3 Document batch layout and the narrow skip check in README and `.kiro` criteria; verify documented paths and skip behavior with a sample batch.

## 5. Reproduce installation and finish documentation

- [ ] 5.1 Establish a supported Python and direct-dependency set in a fresh environment, run `pip check`, and record the tested platform and versions; verify the environment is independent of the tracked `python/venv`.
- [ ] 5.2 Run a short real-audio conversion for each advertised output format and confirm the files decode; keep only formats that pass, then verify one documented default conversion path.
- [ ] 5.3 Check `assets/models/` references and remove or archive assets unused by a supported workflow; verify no documentation claims they prepare Spleeter for offline use.
- [ ] 5.4 Replace the README placeholder clone URL and machine-specific examples; document installation, system dependencies, model setup and offline use, exit codes, and batch results; verify each command on the tested platform.
- [ ] 5.5 Run automated CLI and batch behavior tests, `bash -n` on both shell wrappers, and a final clean-environment real-audio conversion; record any platform not tested.
