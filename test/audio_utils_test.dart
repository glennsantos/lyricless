import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyricless/utils/audio_utils.dart';

void main() {
  group('AudioUtils', () {
    test('encodeWav creates valid WAV header', () {
      final pcmData = Float32List(100); // 100 samples of silence
      final wavBytes = AudioUtils.encodeWav(pcmData);

      expect(wavBytes.length, equals(44 + 200)); // Header + 100 * 2 bytes
      
      final view = ByteData.view(wavBytes.buffer);
      expect(String.fromCharCodes(wavBytes.sublist(0, 4)), equals('RIFF'));
      expect(String.fromCharCodes(wavBytes.sublist(8, 12)), equals('WAVE'));
      expect(view.getUint16(22, Endian.little), equals(1)); // Channels
      expect(view.getUint32(24, Endian.little), equals(44100)); // Sample rate
    });

    test('parseWav decodes encoded WAV correctly', () {
      final pcmData = Float32List(100);
      for (int i = 0; i < 100; i++) {
        pcmData[i] = (i % 2 == 0) ? 0.5 : -0.5;
      }

      final wavBytes = AudioUtils.encodeWav(pcmData);
      final decodedPcm = AudioUtils.parseWav(wavBytes);

      expect(decodedPcm.length, equals(100));
      // Allow small precision error due to 16-bit quantization
      expect(decodedPcm[0], closeTo(0.5, 0.0001));
      expect(decodedPcm[1], closeTo(-0.5, 0.0001));
    });
  });
}
