import 'dart:typed_data';
import 'dart:typed_data';
import 'dart:math';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

/// Utility class for audio file handling and processing
class AudioUtils {
  static const int _wavHeaderSize = 44;

  /// Parses a WAV file and returns the PCM data as Float32List
  /// Currently supports 16-bit PCM WAV files
  static Float32List parseWav(Uint8List bytes) {
    if (bytes.length < _wavHeaderSize) {
      throw FormatException('File too small to be a WAV file');
    }

    // Basic WAV validation
    final riff = String.fromCharCodes(bytes.sublist(0, 4));
    final wave = String.fromCharCodes(bytes.sublist(8, 12));
    if (riff != 'RIFF' || wave != 'WAVE') {
      throw FormatException('Invalid WAV file format');
    }

    // Extract format info
    final channels = bytes[22] + (bytes[23] << 8);
    final sampleRate = bytes[24] + (bytes[25] << 8) + (bytes[26] << 16) + (bytes[27] << 24);
    final bitsPerSample = bytes[34] + (bytes[35] << 8);

    if (bitsPerSample != 16) {
      throw FormatException('Only 16-bit PCM WAV files are currently supported');
    }

    // Extract data
    final dataSize = bytes[40] + (bytes[41] << 8) + (bytes[42] << 16) + (bytes[43] << 24);
    final dataOffset = _wavHeaderSize;
    
    if (bytes.length < dataOffset + dataSize) {
      // Some WAV files might have extra metadata chunks, we should look for 'data' chunk
      // For now, simplistic parsing assuming standard header
      // TODO: Implement robust chunk parsing
    }

    // Convert 16-bit integer PCM to Float32 (-1.0 to 1.0)
    final numSamples = dataSize ~/ 2;
    final floatData = Float32List(numSamples);
    final byteData = ByteData.sublistView(bytes, dataOffset);

    for (var i = 0; i < numSamples; i++) {
      final sample = byteData.getInt16(i * 2, Endian.little);
      floatData[i] = sample / 32768.0;
    }

    // If stereo, mix down to mono for processing (simplification)
    // Or keep as stereo if model supports it. 
    // For this implementation, we'll mix to mono if stereo
    if (channels == 2) {
      final monoSamples = numSamples ~/ 2;
      final monoData = Float32List(monoSamples);
      for (var i = 0; i < monoSamples; i++) {
        monoData[i] = (floatData[i * 2] + floatData[i * 2 + 1]) / 2;
      }
      return monoData;
    }

    return floatData;
  }

  /// Creates a WAV file header and returns the full WAV file bytes
  static Uint8List encodeWav(Float32List pcmData, {int sampleRate = 44100, int channels = 1}) {
    final numSamples = pcmData.length;
    final byteRate = sampleRate * channels * 2; // 16-bit = 2 bytes
    final dataSize = numSamples * 2;
    final fileSize = 36 + dataSize;

    final header = ByteData(44);
    final view = header;

    // RIFF chunk
    _writeString(view, 0, 'RIFF');
    view.setUint32(4, fileSize, Endian.little);
    _writeString(view, 8, 'WAVE');

    // fmt chunk
    _writeString(view, 12, 'fmt ');
    view.setUint32(16, 16, Endian.little); // PCM chunk size
    view.setUint16(20, 1, Endian.little); // Audio format 1 = PCM
    view.setUint16(22, channels, Endian.little);
    view.setUint32(24, sampleRate, Endian.little);
    view.setUint32(28, byteRate, Endian.little);
    view.setUint16(32, channels * 2, Endian.little); // Block align
    view.setUint16(34, 16, Endian.little); // Bits per sample

    // data chunk
    _writeString(view, 36, 'data');
    view.setUint32(40, dataSize, Endian.little);

    // Convert Float32 to Int16
    final pcmBytes = Uint8List(dataSize);
    final pcmView = ByteData.view(pcmBytes.buffer);

    for (var i = 0; i < numSamples; i++) {
      var sample = pcmData[i];
      // Clip
      if (sample > 1.0) sample = 1.0;
      if (sample < -1.0) sample = -1.0;
      
      final int16Sample = (sample * 32767).round();
      pcmView.setInt16(i * 2, int16Sample, Endian.little);
    }

    final wavFile = BytesBuilder();
    wavFile.add(header.buffer.asUint8List());
    wavFile.add(pcmBytes);

    return wavFile.toBytes();
  }

  static void _writeString(ByteData view, int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      view.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  /// Converts any supported audio file to a 16-bit PCM WAV file at 44.1kHz mono
  /// Returns true if successful
  static Future<bool> convertAudioToWav(String inputPath, String outputPath) async {
    // -y: overwrite output
    // -i: input
    // -ar 44100: sample rate
    // -ac 1: channels (mono)
    // -c:a pcm_s16le: codec 16-bit PCM
    final command = '-y -i "$inputPath" -ar 44100 -ac 1 -c:a pcm_s16le "$outputPath"';
    
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    return ReturnCode.isSuccess(returnCode);
  }
}
