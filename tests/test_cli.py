import json
import os
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CLI = ROOT / 'python/vocal_remover_cli.py'
BATCH = ROOT / 'python/batch_process.sh'
STUB = ROOT / 'tests/stub_spleeter'


class CliTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.dir = Path(self.tmp.name)
        self.env = {**os.environ, 'PYTHONPATH': str(STUB), 'LYRICLESS_PYTHON': sys.executable}

    def run_cli(self, *args, fail=None):
        env = {**self.env}
        if fail:
            env['STUB_FAIL'] = fail
        return subprocess.run([sys.executable, str(CLI), *map(str, args)], env=env,
                              capture_output=True, text=True)

    def test_alias_and_existing_output(self):
        source = self.dir / 'song.mp3'
        source.write_bytes(b'source')
        hard = self.dir / 'hard.mp3'
        os.link(source, hard)
        symbolic = self.dir / 'symbolic.mp3'
        symbolic.symlink_to(source)
        for output in (source, hard, symbolic):
            result = self.run_cli(source, output, '--overwrite')
            self.assertEqual(result.returncode, 1, result.stderr)
            self.assertEqual(source.read_bytes(), b'source')
        output = self.dir / 'old.mp3'
        output.write_bytes(b'previous')
        self.assertEqual(self.run_cli(source, output).returncode, 1)
        self.assertEqual(output.read_bytes(), b'previous')
        self.assertEqual(self.run_cli(source, output, '--overwrite', fail='separate').returncode, 2)
        self.assertEqual(output.read_bytes(), b'previous')
        self.assertEqual(list(self.dir.glob('.lyricless-*')), [])
        self.assertEqual(self.run_cli(source, output, '--overwrite').returncode, 0)
        self.assertEqual(output.read_bytes(), b'mp3 audio')

    def test_formats_and_json(self):
        for extension in ('.mp3', '.wav', '.m4a', '.flac'):
            source = self.dir / f'song{extension}'
            source.write_bytes(b'input')
            result = self.run_cli(source, '--json-progress')
            self.assertEqual(result.returncode, 0, result.stderr)
            output = self.dir / 'song_instrumental.mp3'
            self.assertEqual(output.read_bytes(), b'mp3 audio')
            records = [json.loads(line) for line in result.stdout.splitlines()]
            self.assertEqual(records[-1], {'success': True, 'output_path': str(output)})
            output.unlink()
        source = self.dir / 'song.mp3'
        wav = self.dir / 'out.wav'
        self.assertEqual(self.run_cli(source, wav).returncode, 0)
        self.assertEqual(wav.read_bytes(), b'wav audio')
        bad = self.run_cli(source, self.dir / 'bad.flac')
        self.assertEqual(bad.returncode, 1)
        self.assertNotIn('Loading model', bad.stderr)

    def test_interrupt_cleans_up(self):
        source = self.dir / 'song.mp3'
        source.write_bytes(b'input')
        result = self.run_cli(source, fail='interrupt')
        self.assertEqual(result.returncode, 130)
        self.assertEqual(list(self.dir.glob('.lyricless-*')), [])
        self.assertEqual(source.read_bytes(), b'input')

    def test_output_created_after_preflight_is_not_replaced(self):
        source = self.dir / 'song.mp3'
        source.write_bytes(b'input')
        output = self.dir / 'instrumental.mp3'
        ready = self.dir / 'separator-ready'
        proceed = self.dir / 'separator-continue'
        env = {**self.env, 'STUB_READY': str(ready), 'STUB_CONTINUE': str(proceed)}
        process = subprocess.Popen(
            [sys.executable, str(CLI), str(source), str(output)],
            env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
        )
        deadline = time.monotonic() + 10
        while not ready.exists() and process.poll() is None and time.monotonic() < deadline:
            time.sleep(0.01)
        if not ready.exists():
            process.kill()
            stdout, stderr = process.communicate()
            self.fail(f'separator did not reach pause point: {stdout}\n{stderr}')
        output.write_bytes(b'created concurrently')
        proceed.write_text('continue')
        _, stderr = process.communicate(timeout=10)
        self.assertEqual(process.returncode, 2, stderr)
        self.assertEqual(output.read_bytes(), b'created concurrently')
        self.assertEqual(list(self.dir.glob('.lyricless-*')), [])

    def test_batch_layout_and_failure(self):
        for folder in ('a', 'b'):
            path = self.dir / folder
            path.mkdir()
            (path / 'song.mp3').write_bytes(b'input')
        (self.dir / 'a' / 'line\nbreak.mp3').write_bytes(b'input')
        result = subprocess.run(['bash', str(BATCH), str(self.dir)], env=self.env,
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        for relative in ('a/song_instrumental.mp3', 'b/song_instrumental.mp3',
                         'a/line\nbreak_instrumental.mp3'):
            self.assertEqual((self.dir / 'instrumentals' / relative).read_bytes(), b'mp3 audio')
        self.assertIn('Processed: 3', result.stdout)
        again = subprocess.run(['bash', str(BATCH), str(self.dir)], env=self.env,
                               capture_output=True, text=True)
        self.assertIn('Skipped: 3', again.stdout)
        (self.dir / 'new.mp3').write_bytes(b'input')
        failed = subprocess.run(['bash', str(BATCH), str(self.dir)],
                                env={**self.env, 'STUB_FAIL': 'separate'},
                                capture_output=True, text=True)
        self.assertNotEqual(failed.returncode, 0)
        self.assertIn('Failed: 1', failed.stdout)

    def test_batch_symlink_output_is_not_skipped(self):
        source = self.dir / 'song.mp3'
        source.write_bytes(b'input')
        output_dir = self.dir / 'instrumentals'
        output_dir.mkdir()
        target = self.dir / 'external.mp3'
        target.write_bytes(b'preserve me')
        output = output_dir / 'song_instrumental.mp3'
        output.symlink_to(target)
        result = subprocess.run(['bash', str(BATCH), str(self.dir)], env=self.env,
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 2)
        self.assertIn('Failed: 1', result.stdout)
        self.assertIn('Skipped: 0', result.stdout)
        self.assertTrue(output.is_symlink())
        self.assertEqual(target.read_bytes(), b'preserve me')


if __name__ == '__main__':
    unittest.main()
