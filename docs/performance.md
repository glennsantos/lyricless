# Measuring separation results

The previous README reported Whisper word counts for three inputs, but did not identify those inputs or record the Whisper version and decoding settings. The measurements cannot be reproduced from this repository. Lyricless no longer presents those counts as performance evidence.

Use this protocol before publishing new transcription-based measurements.

## Record the inputs and environment

1. Choose audio that you have permission to publish or identify. Record each source's dataset, version, track identifier, license, duration, sample rate, channel count, and SHA-256 hash. Do not commit copyrighted audio without permission.
2. Record the operating system, CPU, GPU, Python version, `audio-separator` version, and transcription package version.
3. Record all downloaded model filenames and their SHA-256 hashes. Include the `instrumental_clean` preset and any separator options.
4. If comparing against another separator, record its version, model files, and options. Run each system on the same source files.

## Run the same transcription setup

Transcribe the original input and every separated output with the same Whisper package, model, language setting, and decoding options. Save the full JSON output, not only the word count. Normalize each transcript by lowercasing it and splitting on whitespace. Count the resulting tokens for every file. Transcription counts measure recognized words, not perceptual vocal absence.

## Publish the result record

Include a table with one row per input and columns for the track ID, audio hash, original word count, separated word count for each system, and listening notes. Include the commands or script used to run separation and transcription. Keep any result without its environment and input manifest out of the README.

This protocol makes a new result traceable. It does not recover the missing inputs or settings from the earlier README measurements.
