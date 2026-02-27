import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_litert/flutter_litert.dart';

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

/// Service untuk menjalankan model TFLite
class BananaClassifier {
  static const String _modelPath = 'assets/model/banana_model.tflite';
  static const String _labelsPath = 'assets/model/labels.txt';
  static const int _inputSize = 224; // MobileNetV2 input size
  static const int _numClasses = 2;

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  /// Load model dan labels dari assets
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
      debugPrint('[Classifier] Model berhasil dimuat! Labels: $_labels');
    } catch (e) {
      debugPrint('[Classifier] ERROR load model: $e');
      rethrow;
    }
  }

  /// Prediksi gambar pisang dari File
  Future<PredictionResult> predict(File imageFile) async {
    if (!_isLoaded || _interpreter == null) {
      throw Exception(
          'Model belum dimuat! Panggil loadModel() terlebih dahulu.');
    }

    // 1. Baca dan preprocess gambar
    final imageBytes = await imageFile.readAsBytes();
    final inputTensor = _preprocessImage(imageBytes);

    // 2. Siapkan output tensor
    final output = List.filled(_numClasses, 0.0).reshape([1, _numClasses]);

    // 3. Jalankan inferensi
    _interpreter!.run(inputTensor, output);

    // 4. Ambil hasil
    final scores = output[0] as List<double>;
    final maxIndex = scores.indexOf(scores.reduce((a, b) => a > b ? a : b));
    final confidence = scores[maxIndex];
    final label = maxIndex < _labels.length ? _labels[maxIndex] : 'UNKNOWN';
    final isFresh = label.toUpperCase().contains('FRESH') ||
        label.toUpperCase().contains('LAYAK') &&
            !label.toUpperCase().contains('TIDAK');

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

  void dispose() {
    _interpreter?.close();
    _isLoaded = false;
  }
}
