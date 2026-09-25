import os
import time
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
        ready = os.environ.get('STUB_READY')
        proceed = os.environ.get('STUB_CONTINUE')
        if ready and proceed:
            Path(ready).write_text('ready')
            deadline = time.monotonic() + 10
            while not Path(proceed).exists():
                if time.monotonic() >= deadline:
                    raise RuntimeError('test separator timed out')
                time.sleep(0.01)
        target = Path(output_path) / Path(input_path).stem
        target.mkdir(parents=True)
        (target / f'accompaniment.{codec}').write_bytes(f'{codec} audio'.encode())
