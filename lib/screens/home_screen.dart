import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../main.dart';
import '../services/banana_classifier.dart';
import '../services/history_database.dart';
import '../widgets/result_card.dart';
import '../widgets/stats_widget.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {

  final BananaClassifier _classifier = BananaClassifier();
  final HistoryDatabase  _db         = HistoryDatabase();
  final ImagePicker      _picker     = ImagePicker();

  File?             _selectedImage;
  PredictionResult? _result;
  bool              _isLoading    = false;
  bool              _isModelReady = false;
  String            _statusMsg    = 'Memuat model AI...';

  late AnimationController _resultAnimController;
  late Animation<double>   _resultFadeAnim;
  late Animation<Offset>   _resultSlideAnim;

  @override
  void initState() {
    super.initState();

    _resultAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _resultFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _resultAnimController, curve: Curves.easeOut),
    );

    _resultSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _resultAnimController,
      curve: Curves.easeOutCubic,
    ));

    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      await _classifier.loadModel();
      setState(() {
        _isModelReady = true;
        _statusMsg = 'Model siap! Pilih gambar pisang.';
      });
    } catch (e) {
      setState(() {
        _statusMsg = 'Gagal load model: $e';
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!_isModelReady) {
      _showSnackbar('Model belum siap, harap tunggu...');
      return;
    }

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );

      if (picked == null) return;

      setState(() {
        _selectedImage = File(picked.path);
        _result = null;
        _isLoading = true;
      });

      // Jalankan deteksi
      await _runDetection(File(picked.path));

    } catch (e) {
      _showSnackbar('Error memilih gambar: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runDetection(File imageFile) async {
    try {
      final result = await _classifier.predict(imageFile);

      // Simpan gambar ke direktori app
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'banana_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = p.join(appDir.path, fileName);
      await imageFile.copy(savedPath);

      // Simpan ke database
      await _db.insertDetection(result: result, imagePath: savedPath);

      setState(() {
        _result    = result;
        _isLoading = false;
      });

      // Animasi hasil muncul
      _resultAnimController.reset();
      _resultAnimController.forward();

    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar('Gagal mendeteksi: $e');
    }
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Sumber Gambar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _SourceButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Kamera',
                    color: AppTheme.primary,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SourceButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Galeri',
                    color: AppTheme.primaryDark,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _classifier.dispose();
    _resultAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: AppTheme.bgLight,
              elevation: 0,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🍌', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  const Text(
                    'BanaSnap',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.history_rounded, color: AppTheme.textDark),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                ),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // Status model
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _isModelReady
                          ? AppTheme.fresh.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isModelReady
                              ? Icons.check_circle_rounded
                              : Icons.hourglass_empty_rounded,
                          color: _isModelReady ? AppTheme.fresh : Colors.orange,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _statusMsg,
                          style: TextStyle(
                            fontSize: 13,
                            color: _isModelReady ? AppTheme.fresh : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Area gambar
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _selectedImage != null
                              ? AppTheme.primary
                              : Colors.grey.shade200,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: _buildImageArea(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tombol deteksi
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isModelReady ? _showImageSourceDialog : null,
                      icon: const Icon(Icons.search_rounded, size: 22),
                      label: const Text('Pilih Gambar & Deteksi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.textDark,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Hasil deteksi (muncul dengan animasi)
                  if (_isLoading)
                    const _LoadingCard()
                  else if (_result != null)
                    FadeTransition(
                      opacity: _resultFadeAnim,
                      child: SlideTransition(
                        position: _resultSlideAnim,
                        child: ResultCard(result: _result!),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Statistik
                  StatsWidget(db: _db),

                  const SizedBox(height: 20),

                  // Tips
                  _TipsCard(),

                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageArea() {
    if (_isLoading) {
      return Container(
        color: Colors.grey.shade50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.primary),
            const SizedBox(height: 16),
            Text(
              'Menganalisa gambar...',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_selectedImage != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(_selectedImage!, fit: BoxFit.cover),
          // Overlay gradien di bawah
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app_rounded, size: 14, color: AppTheme.textGrey),
                  SizedBox(width: 4),
                  Text('Tap untuk ganti', style: TextStyle(fontSize: 12, color: AppTheme.textGrey)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Center(child: Text('🍌', style: TextStyle(fontSize: 40))),
        ),
        const SizedBox(height: 16),
        const Text(
          'Tap untuk pilih gambar pisang',
          style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Dari kamera atau galeri',
          style: TextStyle(fontSize: 13, color: AppTheme.textGrey),
        ),
      ],
    );
  }
}

// ============================================================
// Widget pembantu
// ============================================================

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 32, height: 32,
            child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 3),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Menganalisa...', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              Text('Model AI sedang bekerja', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  final List<Map<String, String>> _tips = const [
    {'icon': '📸', 'text': 'Foto dengan pencahayaan cukup'},
    {'icon': '🍌', 'text': 'Pastikan pisang terlihat jelas'},
    {'icon': '🔍', 'text': 'Ambil dari jarak 20-30 cm'},
    {'icon': '🚫', 'text': 'Hindari bayangan pada buah'},
  ];

  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 Tips Foto Terbaik',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 12),
          ..._tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Text(tip['icon']!, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Text(tip['text']!, style: const TextStyle(fontSize: 13, color: AppTheme.textDark)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
