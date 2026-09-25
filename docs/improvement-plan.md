# CLI improvement plan

## Current state

Lyricless is a Python command-line vocal remover. `python/vocal_remover_cli.py` processes one audio file with Spleeter. `python/batch_process.sh` processes MP3 files in a directory. `python/run_vocal_remover.sh` selects a Python interpreter and runs the CLI.

The `.kiro/specs` documents still describe a mobile music player with playback, queueing, caching, and a user interface. Those features are absent from the current repository. The specifications need to describe the CLI that exists now.

The work below is ordered by risk. Complete and verify each phase before starting the next.

## 1. Replace the player specifications

Rewrite `.kiro/specs/lyricless/requirements.md` and `.kiro/specs/local-vocal-remover/{design,tasks}.md` for the CLI. Remove requirements for Flutter, playback, queues, mobile inference, and cache eviction. Specify:

- Single-file and batch inputs, supported formats, output naming, and overwrite behavior.
- The output formats the encoder can actually produce.
- Exit codes, human-readable errors, and the `--json-progress` output contract.
- Behavior when a batch contains duplicate basenames, existing outputs, or failed files.
- Temporary-file cleanup and protection of the source audio.
- Model download requirements for the first run and behavior when offline.

**Done when:** each acceptance criterion can be checked by running a CLI command or inspecting its output. No active requirement refers to a music player.

## 2. Protect input and output files

In `python/vocal_remover_cli.py`, reject an output path that refers to the input file, including an existing hard link or symbolic link. Use a unique temporary directory for each run. Clean up only that run's files after success, failure, or interruption. Move the completed output into place atomically, so a failed process cannot publish a partial file. Define whether an existing output is replaced or requires an explicit option, then document that choice.

**Done when:** a failed or interrupted run leaves the input and any previous output intact. Two runs using the same input do not share a temporary directory. A request to write onto the input fails before separation starts.

## 3. Make format behavior consistent

The CLI accepts MP3, WAV, M4A, and FLAC inputs. For M4A and FLAC inputs, its default output path keeps the input extension, while the Spleeter call requests WAV and then looks for a file with the original extension. The README instead promises an MP3 default.

Choose MP3 as the default output for every supported input. Accept explicit output paths only for encoder formats verified against the installed Spleeter version. Derive the encoder codec and expected temporary filename from that one output-format choice. Update the CLI help and README to match.

**Done when:** each supported input type produces the documented default filename, and each accepted explicit output extension contains audio in the named format. Unsupported output extensions fail before processing.

## 4. Make batch results reliable

`python/batch_process.sh` currently puts every result in one directory using only the source basename. Two source files named `song.mp3` in different subdirectories therefore target the same output. The script also prints a completion message and exits successfully after individual failures.

Preserve the source's relative directory structure under `instrumentals/`. Use null-delimited file discovery so unusual filenames remain intact. Exclude the output tree from discovery. Count processed, skipped, and failed files. Return a nonzero exit code when any file fails. Check whether an existing output is valid before skipping it, or document a narrower skip rule.

**Done when:** duplicate basenames produce distinct outputs, filenames containing whitespace or newlines work, and a failed conversion makes the batch command fail with an accurate summary.

## 5. Reproduce installation and test real behavior

`python/requirements.txt` pins TensorFlow, NumPy, and Librosa but leaves Spleeter unpinned. The existing local virtual environment fails `pip check`, so it is not evidence that a clean installation works. Establish one supported Python and dependency set in a fresh environment. Verify it on the target platform with a short audio file. Keep only direct dependencies and necessary version constraints in the requirements file.

Add focused tests that call the CLI as a user would. Cover path safety, output format selection, cleanup after a separator failure, JSON output, batch basename collisions, and batch failure status. Use a stub separator for fast failure cases and one real short-audio smoke test for the documented installation. Run shell syntax checks for both wrappers.

**Done when:** a clean install passes its dependency check, the automated tests pass, and a real short input produces a playable instrumental at the documented path.

## 6. Align the README and repository contents

Replace the placeholder clone URL and the machine-specific batch example in `README.md`. Document the tested Python version, system dependencies, supported inputs and outputs, first-run model download, offline use after model setup, exit codes, and batch layout. Explain that progress values are stage markers unless the CLI reports measured separation progress.

The tracked files under `assets/models/` are not loaded by the current CLI. Confirm whether they are needed for another supported workflow. If not, remove them from the active tree or move them to a clearly labeled archive; do not imply that they make the Spleeter CLI offline-ready.

**Done when:** a new user can install and run the documented command without repo-specific paths, and every documented behavior matches a checked command.

## Verification workflow

Use Poteto's pstack principles of **Test Behavior, Not Implementation**, **Sequence Work into Verifiable Units**, and **Prove It Works**. Capture a failing command or test for each defect, make the smallest change that fixes it, and rerun the same check. Finish with a clean-environment install and a real audio conversion. Record any platform that was not tested instead of claiming support for it.
