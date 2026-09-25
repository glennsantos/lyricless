import os
from pathlib import Path

class Separator:
    def __init__(self, model):
        if os.environ.get('STUB_FAIL') == 'load':
            raise RuntimeError('model unavailable')

    def separate_to_file(self, input_path, output_path, codec='mp3', bitrate='320k'):
        if os.environ.get('STUB_FAIL') == 'separate':
            raise RuntimeError('separator failed')
        if os.environ.get('STUB_FAIL') == 'interrupt':
            raise KeyboardInterrupt
        target = Path(output_path) / Path(input_path).stem
        target.mkdir(parents=True)
        (target / f'accompaniment.{codec}').write_bytes(f'{codec} audio'.encode())
