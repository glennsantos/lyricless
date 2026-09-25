import os
import time
from pathlib import Path


class Separator:
    def __init__(self, **kwargs):
        if kwargs['ensemble_preset'] != 'instrumental_clean':
            raise ValueError('wrong separation preset')
        if kwargs['output_single_stem'] != 'Instrumental':
            raise ValueError('wrong output stem')
        self.output_dir = Path(kwargs['output_dir'])
        self.extension = kwargs['output_format'].lower()

    def load_model(self):
        if os.environ.get('STUB_FAIL') == 'load':
            raise RuntimeError('model unavailable')

    def separate(self, input_path, custom_output_names=None):
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
        name = custom_output_names['Instrumental']
        target = self.output_dir / f'{name}.{self.extension}'
        target.write_bytes(f'{self.extension} audio'.encode())
        return [str(target)]
