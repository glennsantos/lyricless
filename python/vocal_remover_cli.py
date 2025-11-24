#!/usr/bin/env python3
"""
Terminal-based vocal remover CLI for Lyricless
Accepts MP3 input and outputs instrumental MP3 using Spleeter
"""

import os
import sys
import argparse
from pathlib import Path
from spleeter.separator import Separator
from spleeter.audio.adapter import AudioAdapter


def remove_vocals(input_path: str, output_path: str = None, verbose: bool = True) -> str:
    """
    Remove vocals from an audio file using Spleeter
    
    Args:
        input_path: Path to input MP3 file
        output_path: Path to output MP3 file (optional)
        verbose: Print progress messages
        
    Returns:
        Path to output file
        
    Raises:
        FileNotFoundError: If input file doesn't exist
        ValueError: If input file format is invalid
    """
    # Validate input file
    input_file = Path(input_path)
    if not input_file.exists():
        raise FileNotFoundError(f"Input file not found: {input_path}")
    
    if input_file.suffix.lower() not in ['.mp3', '.wav', '.m4a', '.flac']:
        raise ValueError(f"Unsupported audio format: {input_file.suffix}")
    
    # Generate output path if not provided
    if output_path is None:
        output_path = input_file.parent / f"{input_file.stem}_instrumental{input_file.suffix}"
    else:
        output_path = Path(output_path)
    
    if verbose:
        print(f"Input:  {input_file}")
        print(f"Output: {output_path}")
        print("\nProcessing...")
    
    try:
        # Initialize Spleeter separator
        # Use the pretrained 2stems model (vocals and accompaniment)
        separator = Separator('spleeter:2stems')
        
        # Perform separation
        # By default, Spleeter outputs to a directory with the source filename
        # We'll use a temporary directory then extract what we need
        temp_output_dir = input_file.parent / f".spleeter_temp_{input_file.stem}"
        temp_output_dir.mkdir(exist_ok=True)
        
        if verbose:
            print("Separating audio... (this may take a minute)")
        
        # Separate the audio
        separator.separate_to_file(
            str(input_file),
            str(temp_output_dir),
            codec='mp3' if output_path.suffix.lower() == '.mp3' else 'wav',
            bitrate='320k'  # High quality MP3
        )
        
        # Spleeter creates a subdirectory with the input filename
        # and puts 'vocals.mp3' and 'accompaniment.mp3' inside
        spleeter_output_dir = temp_output_dir / input_file.stem
        instrumental_file = spleeter_output_dir / f"accompaniment{output_path.suffix}"
        
        # Move the instrumental file to the desired output location
        if instrumental_file.exists():
            # Move file to final location
            import shutil
            shutil.move(str(instrumental_file), str(output_path))
            
            # Clean up temporary directory
            shutil.rmtree(temp_output_dir)
            
            if verbose:
                print(f"✓ Success! Instrumental saved to: {output_path}")
                file_size_mb = output_path.stat().st_size / (1024 * 1024)
                print(f"  File size: {file_size_mb:.2f} MB")
            
            return str(output_path)
        else:
            raise RuntimeError(f"Spleeter did not produce expected output at {instrumental_file}")
            
    except Exception as e:
        # Clean up temp directory on error
        if temp_output_dir.exists():
            import shutil
            shutil.rmtree(temp_output_dir)
        raise RuntimeError(f"Vocal removal failed: {e}")


def main():
    """Main CLI entry point"""
    parser = argparse.ArgumentParser(
        description='Remove vocals from audio files using Spleeter',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Basic usage (creates input_instrumental.mp3)
  python vocal_remover_cli.py song.mp3
  
  # Specify output filename
  python vocal_remover_cli.py song.mp3 karaoke.mp3
  
  # Quiet mode
  python vocal_remover_cli.py song.mp3 -q
        """
    )
    
    parser.add_argument(
        'input',
        type=str,
        help='Input audio file (MP3, WAV, M4A, or FLAC)'
    )
    
    parser.add_argument(
        'output',
        type=str,
        nargs='?',
        default=None,
        help='Output audio file (optional, defaults to <input>_instrumental.mp3)'
    )
    
    parser.add_argument(
        '-q', '--quiet',
        action='store_true',
        help='Suppress progress messages'
    )
    
    args = parser.parse_args()
    
    try:
        output_file = remove_vocals(
            args.input,
            args.output,
            verbose=not args.quiet
        )
        sys.exit(0)
        
    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
        
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
        
    except RuntimeError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(2)
        
    except KeyboardInterrupt:
        print("\n\nInterrupted by user", file=sys.stderr)
        sys.exit(130)
        
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(3)


if __name__ == '__main__':
    main()
