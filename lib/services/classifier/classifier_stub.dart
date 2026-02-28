import 'dart:io';
import 'package:flutter/foundation.dart';

import '../banana_classifier.dart';

/// Stub implementasi BananaClassifier untuk platform non-mobile (Web/Desktop)
/// karena flutter_litert (dart:ffi) tidak mendukung Web/Desktop.
class BananaClassifierImpl implements BananaClassifier {
  bool _isLoaded = false;

  @override
  bool get isLoaded => _isLoaded;

  @override
  Future<void> loadModel() async {
    // Pura-pura load sukses untuk mencegah crash UI
    _isLoaded = true;
    debugPrint('[Classifier Stub] Model dimuat dalam mode mock (Web/Desktop)');
  }

  @override
  Future<PredictionResult> predict(File imageFile) async {
    if (!_isLoaded) {
      throw Exception('Model belum dimuat!');
    }

    // Kembalikan hasil mock statis karena TFLite asli tidak bisa jalan di Web
    debugPrint('[Classifier Stub] Menjalankan prediksi mock untuk Web/Desktop');

    // Asumsikan web hanya untuk testing UI, jadi mock hasil
    return PredictionResult(
      label: 'LAYAK',
      confidence: 0.99,
      isFresh: true,
      timestamp: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _isLoaded = false;
  }
}

/// Factory function yang digunakan oleh conditional import
BananaClassifier getClassifierImpl() => BananaClassifierImpl();
