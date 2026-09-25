# Tasks

## 1. Establish the CLI contract

- [x] 1.1 Replace player requirements in `.kiro/specs/lyricless/requirements.md` and `.kiro/specs/local-vocal-remover/{design,tasks}.md` with command-checkable single-file and batch criteria; verify no active requirement mentions player, Flutter, playback, queues, or cache eviction.
- [x] 1.2 Record a failing command or user-level test for source aliasing, existing output, format mismatch, batch basename collision, and batch failure status; verify each reproduces the stated defect before implementation.

## 2. Protect single-file conversion

- [x] 2.1 Add preflight input/output identity and `--overwrite` checks, including symlinks and hard links; verify command-level tests preserve source and existing output bytes.
- [x] 2.2 Isolate each conversion in a unique temporary directory, clean it on success/failure/interruption, and publish via atomic replacement; verify failure and interruption tests leave no partial output or shared run directory.
- [x] 2.3 Update CLI help and single-file documentation for overwrite policy and exit codes; verify `--help` and documented commands match behavior.

## 3. Align formats and progress

- [x] 3.1 Centralize the output extension/codec/temporary filename mapping and make MP3 the default for MP3, WAV, M4A, and FLAC input; verify command-level cases for all four input suffixes and each accepted output suffix.
- [x] 3.2 Reject unsupported output extensions before model loading and keep JSON stdout parseable line by line; verify invalid-format and success/failure JSON command tests.
- [x] 3.3 Update README and `.kiro` CLI criteria for actual formats and stage-marker progress; verify the examples and expected JSON fields against command output.

## 4. Make batch outcomes reliable

- [x] 4.1 Preserve relative directories, prune `instrumentals/`, and use null-delimited discovery; verify duplicate basenames and filenames with whitespace/newlines through the batch command.
- [x] 4.2 Count processed, skipped, and failed inputs, enforce the nonempty-regular-file skip rule, and fail the batch command when any conversion fails; verify summary counts and exit status with stub conversions.
- [x] 4.3 Document batch layout and the narrow skip check in README and `.kiro` criteria; verify documented paths and skip behavior with a sample batch.
- [x] 4.4 Treat symbolic links at batch output paths as failures rather than completed regular outputs; add a regression test proving the link target remains unchanged.

## 4a. Close output publication race

- [x] 4a.1 Publish without `--overwrite` using an atomic no-clobber operation; add a command-level race test that creates the destination after preflight and verifies its bytes are preserved.
- [x] 4a.2 Keep `--overwrite` atomic replacement behavior and rerun existing failure and output-preservation cases.

## 5. Reproduce installation and finish documentation

- [ ] 5.1 Establish a supported Python and direct-dependency set in a fresh environment, run `pip check`, and record the tested platform and versions; verify the environment is independent of the tracked `python/venv`.
- [x] 5.2 Run a short real-audio conversion for each advertised output format and confirm the files decode; keep only formats that pass, then verify one documented default conversion path.
- [x] 5.3 Check `assets/models/` references and remove or archive assets unused by a supported workflow; verify no documentation claims they prepare Spleeter for offline use.
- [ ] 5.4 Replace the README placeholder clone URL and machine-specific examples; document installation, system dependencies, model setup and offline use, exit codes, and batch results; verify each command on the tested platform.
- [ ] 5.5 Run automated CLI and batch behavior tests, `bash -n` on both shell wrappers, and a final clean-environment real-audio conversion; record any platform not tested.
- [x] 5.6 Fix the `run_vocal_remover.sh` ShellCheck warning and run ShellCheck on both wrappers.
- [x] 5.7 Add CI for the stub-backed tests, Python compilation, shell syntax, and ShellCheck; validate the workflow with actionlint and run the same checks locally.
