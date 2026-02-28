import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_litert/flutter_litert.dart';

import '../banana_classifier.dart';

/// Implementasi BananaClassifier menggunakan model TensorFlow Lite yang sesungguhnya.
/// Ini dijembatani via FFI, yang hanya bekerja di Mobile (Android/iOS).
class BananaClassifierImpl implements BananaClassifier {
  static const String _modelPath = 'assets/model/banana_model.tflite';
  static const String _labelsPath = 'assets/model/labels.txt';
  static const int _inputSize = 224; // MobileNetV2 input size

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isLoaded = false;

  @override
  bool get isLoaded => _isLoaded;

  @override
  Future<void> loadModel() async {
    try {
      // Load TFLite model
      final interpreterOptions = InterpreterOptions()
        ..threads = 4; // Gunakan 4 thread untuk inferensi lebih cepat

      _interpreter = await Interpreter.fromAsset(
        _modelPath,
        options: interpreterOptions,
      );

      // Load labels
      final labelsData = await rootBundle.loadString(_labelsPath);
      _labels = labelsData
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      _isLoaded = true;
      debugPrint('[Classifier Native] Model berhasil dimuat! Labels: $_labels');
    } catch (e) {
      debugPrint('[Classifier Native] ERROR load model: $e');
      rethrow;
    }
  }

  @override
  Future<PredictionResult> predict(File imageFile) async {
    if (!_isLoaded || _interpreter == null) {
      throw Exception(
          'Model belum dimuat! Panggil loadModel() terlebih dahulu.');
    }

    // 1. Baca dan preprocess gambar
    final imageBytes = await imageFile.readAsBytes();
    final inputTensor = _preprocessImage(imageBytes);

    // 2. Siapkan output tensor [1, 1]
    final output = List.filled(1, 0.0).reshape([1, 1]);

    // 3. Jalankan inferensi
    _interpreter!.run(inputTensor, output);

    // 4. Ambil hasil output (Model Sigmoid 1 Node)
    // Label 0: LAYAK
    // Label 1: TIDAK_LAYAK
    final score = (output[0] as List)[0] as double;

    // Jika probabilitas < 0.5 berarti cenderung ke 0 (LAYAK)
    // Jika probabilitas >= 0.5 berarti cenderung ke 1 (TIDAK_LAYAK)
    final bool isFresh = score < 0.5;

    // Akurasi dari kelas yang terpilih
    // Jika isFresh (score mendekati 0), confidence adalah (1 - score)
    // Jika Tidak Fresh (score mendekati 1), confidence adalah score
    final confidence = isFresh ? (1.0 - score) : score;

    if (confidence < 0.75) {
      return PredictionResult(
        label: 'BUKAN_PISANG',
        confidence: confidence,
        isFresh: false,
        timestamp: DateTime.now(),
      );
    }

    return PredictionResult(
      label: isFresh ? 'LAYAK' : 'TIDAK_LAYAK',
      confidence: confidence,
      isFresh: isFresh,
      timestamp: DateTime.now(),
    );
  }

  /// Preprocess gambar: resize → normalize → reshape ke [1, 224, 224, 3]
  List<List<List<List<double>>>> _preprocessImage(Uint8List imageBytes) {
    // Decode gambar
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) throw Exception('Gagal decode gambar');

    // Resize ke 224x224
    img.Image resized = img.copyResize(
      image,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    // Konversi ke float array [1, 224, 224, 3] dengan normalisasi 0-1
    final tensor = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );

    return tensor;
  }

  @override
  void dispose() {
    _interpreter?.close();
    _isLoaded = false;
  }
}

/// Factory function yang digunakan oleh conditional import
BananaClassifier getClassifierImpl() => BananaClassifierImpl();
