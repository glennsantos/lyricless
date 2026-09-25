# Supported environments and verification

## Project support status

| Environment | Status |
| --- | --- |
| macOS arm64, Python 3.11 | Clean dependency installation passed `pip check`. Two real MP3 outputs decoded with `ffmpeg`. |
| Ubuntu, Python 3.11 | CI runs command-level tests with a stub separator, Python compilation, shell syntax checks, and ShellCheck. CI does not install Audio Separator or run model inference. |
| Other Python versions and operating systems | Not verified end to end by this repository. |

The package requirement allows Python 3.10 and newer except 3.14.1. This is the dependency's installation range, not a claim that Lyricless has been tested on every allowed version. Audio Separator documents Apple Silicon MPS and CoreML support on macOS 14 or newer. Lyricless's recorded real-audio check does not record the macOS version or confirm which accelerator handled inference. See the [upstream installation and platform notes](https://github.com/nomadkaraoke/python-audio-separator/tree/v0.47.0#installation).

Install `ffmpeg` and make it available on `PATH`. Audio Separator's [FFmpeg setup notes](https://github.com/nomadkaraoke/python-audio-separator/tree/v0.47.0#-ffmpeg-dependency) describe platform installation and its environment check.

## What the checks establish

The automated suite uses a stub separator. It checks command behavior, path safety, output publication, progress records, and batch results. It does not test model downloads, audio quality, memory requirements, speed, or hardware acceleration.

The recorded manual check used a clean macOS arm64 Python 3.11 environment. `pip check` passed, and two complete MP3 outputs decoded with `ffmpeg`. The repository does not retain the audio inputs, outputs, or full environment report, so this check is evidence of a past run rather than a fully repeatable benchmark.

No minimum RAM, processing speed, or quality guarantee is published. The model ensemble can leave vocal bleed. Listen to each result before using it.
