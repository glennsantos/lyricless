# Contributing

Contributions that improve the CLI, documentation, or command-level coverage are welcome. Open an issue before a large change so the maintainer can confirm its scope.

## Set up a development environment

Install Python 3.11 and `ffmpeg`. Create the virtual environment and install the runtime dependency:

```sh
python3.11 -m venv python/separator_venv
python/separator_venv/bin/python -m pip install -r python/requirements.txt
python/separator_venv/bin/python -m pip check
```

## Run the repository checks

The command-level suite uses a stub separator, so it does not download models or process real audio.

```sh
python3 -m unittest discover -s tests -v
python3 -m py_compile python/vocal_remover_cli.py tests/test_cli.py tests/stub_audio_separator/audio_separator/separator.py
bash -n python/run_vocal_remover.sh python/batch_process.sh
shellcheck python/run_vocal_remover.sh python/batch_process.sh
```

CI runs these checks on Ubuntu with Python 3.11. A real model conversion is not part of CI.

## Open an issue or pull request

For a bug report, include the operating system, architecture, Python version, install method, exact command, exit code, and complete error output. Do not attach audio unless you have permission to share it. For audio-specific reports, include its format, duration, and sample rate.

For a pull request, describe the user-visible change and add or update command-level tests when behavior changes. Keep the README and `docs/specs/requirements.md` aligned with the CLI.
