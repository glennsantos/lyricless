# Spec Delta

## Purpose

Defines recursive MP3 batch conversion with distinct output paths, robust filename handling, and an accurate aggregate command result.

## ADDED Requirements

### Requirement: Discovery and output layout
The batch command SHALL discover MP3 inputs recursively with filenames containing whitespace or newlines intact, excluding its `instrumentals/` output tree. It SHALL write each result under `instrumentals/` with the source's relative directory preserved and `_instrumental.mp3` appended to the source stem.

#### Scenario: Duplicate basenames
- **WHEN** `a/song.mp3` and `b/song.mp3` are present
- **THEN** outputs are `instrumentals/a/song_instrumental.mp3` and `instrumentals/b/song_instrumental.mp3`

#### Scenario: Unusual filename
- **WHEN** an MP3 filename contains spaces or newlines
- **THEN** the batch command passes the complete filename to the converter and creates the corresponding output

### Requirement: Skip and failure policy
The batch command SHALL skip an output only when a nonempty regular file already exists at the target path. It SHALL document that this check does not establish decodability. It SHALL count processed, skipped, and failed inputs and print those counts. If any conversion fails, it SHALL exit nonzero.

#### Scenario: Existing output
- **WHEN** a nonempty regular output already exists
- **THEN** the batch command skips that input and includes it in the skipped count

#### Scenario: Symlink at output path
- **WHEN** the target output path is a symbolic link
- **THEN** the batch command does not count it as skipped and reports the conversion as failed without changing the link target

#### Scenario: Failed conversion
- **WHEN** any input conversion fails
- **THEN** the batch command continues with remaining inputs, reports the failed count, and exits nonzero
