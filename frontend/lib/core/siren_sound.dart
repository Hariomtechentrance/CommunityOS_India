import 'dart:typed_data';

/// Generates a short, alternating two-tone siren as raw PCM wrapped in a
/// minimal WAV header - synthesized in Dart rather than bundling a licensed
/// sound asset. Played via `audioplayers`'s `BytesSource`.
Uint8List buildSirenWavBytes({
  int sampleRate = 8000,
  double durationSeconds = 2.0,
  double lowHz = 600,
  double highHz = 900,
  double toneSeconds = 0.3,
}) {
  final totalSamples = (sampleRate * durationSeconds).round();
  final samples = Int16List(totalSamples);

  for (var i = 0; i < totalSamples; i++) {
    final t = i / sampleRate;
    final toneIndex = (t / toneSeconds).floor();
    final freq = toneIndex.isEven ? lowHz : highHz;
    final value = _squareWave(t, freq);
    samples[i] = (value * 12000).round();
  }

  return _wrapPcm16Wav(samples, sampleRate);
}

double _squareWave(double t, double freq) {
  final phase = (t * freq) % 1.0;
  return phase < 0.5 ? 1.0 : -1.0;
}

Uint8List _wrapPcm16Wav(Int16List samples, int sampleRate) {
  final dataLength = samples.lengthInBytes;
  final buffer = ByteData(44 + dataLength);

  void writeString(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      buffer.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  writeString(0, 'RIFF');
  buffer.setUint32(4, 36 + dataLength, Endian.little);
  writeString(8, 'WAVE');
  writeString(12, 'fmt ');
  buffer.setUint32(16, 16, Endian.little); // fmt chunk size
  buffer.setUint16(20, 1, Endian.little); // PCM
  buffer.setUint16(22, 1, Endian.little); // mono
  buffer.setUint32(24, sampleRate, Endian.little);
  buffer.setUint32(28, sampleRate * 2, Endian.little); // byte rate
  buffer.setUint16(32, 2, Endian.little); // block align
  buffer.setUint16(34, 16, Endian.little); // bits per sample
  writeString(36, 'data');
  buffer.setUint32(40, dataLength, Endian.little);

  for (var i = 0; i < samples.length; i++) {
    buffer.setInt16(44 + i * 2, samples[i], Endian.little);
  }

  return buffer.buffer.asUint8List();
}
