#!/usr/bin/env python3
"""Convert one audio file to an instrumental with Spleeter."""

import argparse
import json
import os
import shutil
import sys
import tempfile
from pathlib import Path

INPUT_FORMATS = {'.mp3', '.wav', '.m4a', '.flac'}
OUTPUT_CODECS = {'.mp3': 'mp3', '.wav': 'wav'}


def emit_progress(progress, status, json_mode, verbose):
    if json_mode:
        print(json.dumps({'progress': progress, 'status': status}), flush=True)
    elif verbose:
        print(f'{status} ({int(progress * 100)}%)', file=sys.stderr, flush=True)


def remove_vocals(input_path, output_path=None, verbose=True, json_progress=False, overwrite=False):
    input_file = Path(input_path)
    if not input_file.is_file():
        raise ValueError(f'Input file not found: {input_file}')
    if input_file.suffix.lower() not in INPUT_FORMATS:
        raise ValueError(f'Unsupported input format: {input_file.suffix}')

    output_file = Path(output_path) if output_path is not None else input_file.with_name(
        f'{input_file.stem}_instrumental.mp3'
    )
    codec = OUTPUT_CODECS.get(output_file.suffix.lower())
    if codec is None:
        raise ValueError(f'Unsupported output format: {output_file.suffix} (use .mp3 or .wav)')
    if not output_file.parent.is_dir():
        raise ValueError(f'Output directory not found: {output_file.parent}')
    if input_file.resolve() == output_file.resolve() or (
        output_file.exists() and os.path.samefile(input_file, output_file)
    ):
        raise ValueError('Output identifies the input file')
    if output_file.is_symlink():
        raise ValueError(f'Output is a symbolic link: {output_file}')
    if output_file.exists() and not overwrite:
        raise ValueError(f'Output already exists (pass --overwrite): {output_file}')
    if output_file.exists() and not output_file.is_file():
        raise ValueError(f'Output is not a regular file: {output_file}')

    emit_progress(0.0, 'Initializing', json_progress, verbose)
    emit_progress(0.1, 'Loading model', json_progress, verbose)
    try:
        from spleeter.separator import Separator
        separator = Separator('spleeter:2stems')
        with tempfile.TemporaryDirectory(prefix='.lyricless-', dir=output_file.parent) as run_dir:
            run_path = Path(run_dir)
            emit_progress(0.3, 'Separating audio', json_progress, verbose)
            separator.separate_to_file(
                str(input_file), str(run_path), codec=codec, bitrate='320k'
            )
            emit_progress(0.8, 'Processing output', json_progress, verbose)
            accompaniment = run_path / input_file.stem / f'accompaniment.{codec}'
            if not accompaniment.is_file():
                raise RuntimeError(f'Spleeter did not produce {accompaniment.name}')
            staged = run_path / f'completed.{codec}'
            shutil.move(str(accompaniment), str(staged))
            os.replace(staged, output_file)
    except KeyboardInterrupt:
        raise
    except Exception as exc:
        raise RuntimeError(f'Vocal removal failed: {exc}') from exc

    emit_progress(1.0, 'Complete', json_progress, verbose)
    if json_progress:
        print(json.dumps({'success': True, 'output_path': str(output_file)}), flush=True)
    elif verbose:
        print(f'Instrumental saved to: {output_file}', file=sys.stderr)
    return str(output_file)


def main():
    parser = argparse.ArgumentParser(description='Remove vocals from one audio file with Spleeter')
    parser.add_argument('input', help='Input MP3, WAV, M4A, or FLAC file')
    parser.add_argument('output', nargs='?', help='Output MP3 or WAV (default: <stem>_instrumental.mp3)')
    parser.add_argument('--overwrite', action='store_true', help='Replace an existing regular output file')
    parser.add_argument('-q', '--quiet', action='store_true', help='Suppress human-readable progress')
    parser.add_argument('--json-progress', action='store_true', help='Print JSON stage records to stdout')
    args = parser.parse_args()
    try:
        remove_vocals(args.input, args.output, not args.quiet, args.json_progress, args.overwrite)
    except ValueError as exc:
        print(f'Error: {exc}', file=sys.stderr)
        return 1
    except RuntimeError as exc:
        print(f'Error: {exc}', file=sys.stderr)
        return 2
    except KeyboardInterrupt:
        print('Interrupted by user', file=sys.stderr)
        return 130
    return 0


if __name__ == '__main__':
    sys.exit(main())
