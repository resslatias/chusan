import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? _lastError;
  String? get lastError => _lastError;

  /// Kiểm tra đăng nhập (true/false)
  Future<bool> isLoggedInOnce() async {
    final user = await _auth.authStateChanges().first;
    return user != null;
  }

  /// Lấy thông tin cơ sở hiện tại
  Future<Map<String, dynamic>?> currentCoSoData() async {
    final u = _auth.currentUser;
    if (u == null) return null;

    try {
      final snap = await _db.collection('co_so').doc(u.uid).get();
      return snap.data();
    } catch (e) {
      debugPrint('❌ Lỗi lấy dữ liệu cơ sở: $e');
      return null;
    }
  }

  /// Kiểm tra có phải chủ sân không
  Future<bool> isOwner() async {
    final u = _auth.currentUser;
    if (u == null) return false;

    try {
      final doc = await _db.collection('check_chu_san').doc(u.uid).get();
      return doc.exists;
    } catch (e) {
      debugPrint('❌ Lỗi kiểm tra quyền: $e');
      return false;
    }
  }

  /// Đăng nhập (true nếu thành công)
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _lastError = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _lastError = _mapAuthError(e);
      return false;
    } catch (e) {
      _lastError = 'Có lỗi không xác định khi đăng nhập';
      debugPrint('❌ Lỗi đăng nhập: $e');
      return false;
    }
  }

  /// Quên mật khẩu
  Future<void> sendResetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _lastError = null;
    } on FirebaseAuthException catch (e) {
      _lastError = _mapAuthError(e);
    } catch (e) {
      _lastError = 'Không thể gửi email đặt lại mật khẩu';
      debugPrint('❌ Lỗi reset password: $e');
    }
  }

  /// Đăng xuất
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _lastError = null;
    } catch (e) {
      _lastError = 'Không thể đăng xuất';
      debugPrint('❌ Lỗi đăng xuất: $e');
    }
  }

  /// Map lỗi FirebaseAuth -> tiếng Việt
  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'user-disabled':
        return 'Tài khoản đã bị khóa';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản';
      case 'wrong-password':
        return 'Mật khẩu không đúng';
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng';
      case 'too-many-requests':
        return 'Thao tác quá nhiều lần, vui lòng thử lại sau';
      case 'network-request-failed':
        return 'Mất kết nối mạng';
      case 'operation-not-allowed':
        return 'Phương thức đăng nhập này chưa được kích hoạt';
      default:
        return 'Lỗi không xác định (${e.code})';
    }
  }

  /// Lấy User hiện tại
  User? get currentUser => _auth.currentUser;

  /// Stream theo dõi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}

/// Extension để dễ sử dụng
extension UserExtension on User {
  /// Lấy UID
  String get uid => this.uid;

  /// Lấy email
  String? get email => this.email;

  /// Lấy tên hiển thị
  String? get displayName => this.displayName;

  /// Lấy ảnh đại diện
  String? get photoURL => this.photoURL;
}