import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _userId;

  /// Inisialisasi Player ID anonim via Firebase Auth
  Future<void> initUser() async {
    try {
      // Masuk secara Anonim
      UserCredential userCredential = await _auth.signInAnonymously();
      _userId = userCredential.user?.uid;

      // Mendaftarkan profil devais jika belum ada di dalam koleksi global 'leaderboard'
      if (_userId != null) {
        final doc =
            await _firestore.collection('leaderboard').doc(_userId).get();
        if (!doc.exists) {
          // Hanya set awal profil (Nama Acak Sementara)
          await _firestore.collection('leaderboard').doc(_userId).set({
            'deviceName': 'Player_${_userId!.substring(0, 5)}',
            'points': 0,
            'lastActive': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print('Gagal inisialisasi Firebase Auth Anonim: $e');
    }
  }

  /// Tambahkan poin gamifikasi ke Firestore setelah pemindaian berhasil
  Future<void> incrementPoints(int pointsToAdd) async {
    if (_userId == null) return;
    try {
      await _firestore.collection('leaderboard').doc(_userId).update({
        'points': FieldValue.increment(pointsToAdd),
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Gagal upload sinkronisasi poin: $e');
    }
  }

  /// Membaca urutan Peringkat Pemain Top Global dari Firestore
  Stream<QuerySnapshot> getTopLeaderboard(int limit) {
    return _firestore
        .collection('leaderboard')
        .orderBy('points', descending: true)
        .limit(limit)
        .snapshots();
  }
}
