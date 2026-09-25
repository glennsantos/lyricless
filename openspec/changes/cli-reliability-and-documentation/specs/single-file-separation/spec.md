# Spec Delta

## Purpose

Defines the command-line contract for converting one local audio file into an instrumental while preserving source and previous output files on failure.

## ADDED Requirements

### Requirement: Input and output formats
The CLI SHALL accept MP3, WAV, M4A, and FLAC inputs. The default output SHALL be `<input-stem>_instrumental.mp3` beside the input. Explicit output paths SHALL use only verified encoder formats and SHALL contain audio in the format named by their extension. Unsupported extensions SHALL fail before separation.

#### Scenario: Default output for each input format
- **WHEN** a user processes a supported input without an output argument
- **THEN** the CLI writes an MP3 with the documented default name

#### Scenario: Unsupported output extension
- **WHEN** a user requests an output extension outside the verified encoder set
- **THEN** the CLI fails before model loading or separation and leaves all files intact

### Requirement: Safe output publication
The CLI SHALL reject an output that identifies the input, including symbolic links and hard links, before separation. It SHALL isolate each run's temporary files and clean only those files after success, error, or interruption. It SHALL publish completed output atomically. Existing output SHALL require an explicit `--overwrite` option; a failed overwrite SHALL preserve the previous output.

#### Scenario: Output aliases input
- **WHEN** output is the input path, a symbolic link to it, or an existing hard link to it
- **THEN** the CLI fails before separation and preserves the input bytes

#### Scenario: Failure while producing output
- **WHEN** separation fails or the process is interrupted before publication
- **THEN** no partial output is published, any previous output remains intact, and this run's temporary files are removed

#### Scenario: Existing output
- **WHEN** output already exists and `--overwrite` is absent
- **THEN** the CLI fails before separation and preserves that output

#### Scenario: Concurrent output creation
- **WHEN** another process creates the destination after preflight and before publication, and `--overwrite` is absent
- **THEN** publication fails without replacing the other process's file

### Requirement: Process results
The CLI SHALL return exit code 0 on success, 1 for invalid arguments or input/output conditions, 2 for separation or encoding failure, and 130 for user interruption. Errors SHALL be human readable on stderr. With `--json-progress`, each stdout line SHALL be a JSON object; stage markers SHALL include numeric `progress` in [0, 1] and a `status`, and a final success object SHALL include `success: true` and `output_path`. Progress values SHALL be described as stage markers rather than measured separation percentage.

#### Scenario: Machine-readable run
- **WHEN** a user invokes `--json-progress` on a successful conversion
- **THEN** every stdout line parses as JSON and the final line identifies the completed output

#### Scenario: Conversion error
- **WHEN** the separator fails
- **THEN** the command exits 2 and writes a useful error to stderr

### Requirement: Model availability
Documentation SHALL state that the first run needs the Spleeter model downloaded, and SHALL give a checked way to prepare the model before offline use. If the model is absent while offline, the CLI SHALL fail with a useful error and no published output.

#### Scenario: Offline without model
- **WHEN** the model is unavailable and the machine is offline
- **THEN** conversion fails without modifying input or existing output
