# Model sources and terms

Lyricless pins `audio-separator[cpu]` to version `0.47.0` in `python/requirements.txt`. The CLI selects the `instrumental_clean` ensemble. In that tagged release, the preset names these checkpoints:

- `mel_band_roformer_instrumental_fv7z_gabox.ckpt`, attributed to Gabox.
- `bs_roformer_instrumental_resurrection_unwa.ckpt`, attributed to unwa.

The preset and model registry are maintained by [Audio Separator v0.47.0](https://github.com/nomadkaraoke/python-audio-separator/tree/v0.47.0/audio_separator). The library downloads the checkpoint files on the first conversion and stores them under `python/model_cache/`. Lyricless does not include those files in this repository.

## License scope

The root [MIT license](../LICENSE) applies to the Lyricless repository. The pinned Audio Separator project also declares an MIT license for its software in its [v0.47.0 project metadata](https://github.com/nomadkaraoke/python-audio-separator/blob/v0.47.0/pyproject.toml). Neither statement establishes the license or permitted uses of every downloaded checkpoint.

The model preset and registry identify checkpoint names and contributors, but do not provide a license for each weight file. Check the checkpoint creator's terms before redistributing model files or relying on them for commercial use. This repository makes no claim that the checkpoints are covered by Lyricless's MIT license.

Model registries and remote download locations can change. For an exact run, record the installed `audio-separator` version, the downloaded checkpoint filenames, and their SHA-256 hashes. The pinned preset source identifies the expected filenames; it does not freeze the remote file contents.
