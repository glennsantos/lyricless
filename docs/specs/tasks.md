# Implementation and verification record

The command behavior below is implemented in the current repository.

| Area | Implemented behavior | Automated coverage |
| --- | --- | --- |
| Single-file safety | Reject missing inputs, unsupported formats, input aliases, and existing outputs without `--overwrite` | `test_alias_and_existing_output` |
| Output handling | Stage output in an isolated directory, clean up after failure or interruption, and publish atomically | `test_interrupt_cleans_up`, `test_output_created_after_preflight_is_not_replaced` |
| Formats and progress | Accept four input formats, default to MP3, accept MP3 or WAV output, and emit line-delimited JSON progress | `test_formats_and_json` |
| Batch conversion | Preserve relative paths, handle newline names, skip nonempty regular files, and report failures | `test_batch_layout_and_failure`, `test_batch_symlink_output_is_not_skipped` |
| CI checks | Run the stub-backed suite, Python compilation, shell syntax checks, and ShellCheck on Ubuntu | `.github/workflows/ci.yml` |

The test suite uses a stub separator. It does not verify model quality or real audio conversion. See [support and verification](../support.md) for the recorded end-to-end check and platform limits.
