import 'dart:io';

import 'classifier/classifier_stub.dart'
    if (dart.library.ffi) 'classifier/classifier_native.dart';

/// Hasil prediksi dari model
class PredictionResult {
  final String label; // "LAYAK" atau "TIDAK_LAYAK"
  final double confidence; // 0.0 - 1.0
  final bool isFresh; // true jika layak
  final DateTime timestamp;

  PredictionResult({
    required this.label,
    required this.confidence,
    required this.isFresh,
    required this.timestamp,
  });

  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';

  String get statusText => isFresh ? 'LAYAK DIKONSUMSI' : 'TIDAK LAYAK';

  String get emoji => isFresh ? '✅' : '❌';
}

/// Interface/Abstract class untuk BananaClassifier.
/// Memanfaatkan conditional import agar Flutter Web (yang tidak mendukung dart:ffi)
/// bisa dikompilasi tanpa crash, menggunakan implementasi Stub.
abstract class BananaClassifier {
  bool get isLoaded;

  Future<void> loadModel();

  Future<PredictionResult> predict(File imageFile);

  void dispose();

  /// Factory yang secara otomatis mengembalikan Native (Mobile) atau Stub (Web)
  factory BananaClassifier() => getClassifierImpl();
}
