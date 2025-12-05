import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TrangThaiSanPage extends StatefulWidget {
  const TrangThaiSanPage({super.key});

  @override
  State<TrangThaiSanPage> createState() => _TrangThaiSanPageState();
}

class _TrangThaiSanPageState extends State<TrangThaiSanPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _coSoKey;
  Map<String, dynamic> _coSoData = {};
  bool _isLoading = true;
  bool _hasAvatar = false;
  bool _hasPrice = false;
  bool _hasPayment = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      _coSoKey = user.uid;
      final doc = await _firestore.collection('co_so').doc(_coSoKey).get();

      if (doc.exists) {
        setState(() {
          _coSoData = doc.data() ?? {};
          _checkConditions();
        });
      }
    } catch (e) {
      debugPrint('Lỗi load data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _checkConditions() {
    // Kiểm tra ảnh đại diện
    _hasAvatar = _coSoData['anh_dai_dien'] != null &&
        (_coSoData['anh_dai_dien'] as String).isNotEmpty;

    // Kiểm tra bảng giá
    final bangGia = _coSoData['bang_gia'] as List<dynamic>?;
    _hasPrice = bangGia != null && bangGia.any((gia) => (gia as num) > 0);

    // Kiểm tra thanh toán
    _hasPayment = _coSoData['client_Id'] != null &&
        _coSoData['client_Id'].toString().isNotEmpty &&
        _coSoData['api_Key'] != null &&
        _coSoData['api_Key'].toString().isNotEmpty &&
        _coSoData['checksum_Key'] != null &&
        _coSoData['checksum_Key'].toString().isNotEmpty;
  }

  Future<void> _toggleIsOke(bool value) async {
    if (value && !(_hasAvatar && _hasPrice && _hasPayment)) {
      _showErrorDialog();
      return;
    }

    try {
      await _firestore.collection('co_so').doc(_coSoKey).update({
        'is_oke': value ? 1 : 0
      });

      setState(() {
        _coSoData['is_oke'] = value ? 1 : 0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(value ? 'Đã bật hiển thị sân' : 'Đã tắt hiển thị sân'),
              backgroundColor: value ? Colors.green : Colors.orange,
            )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Không thể bật hiển thị sân'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cần hoàn thành các điều kiện sau:'),
            const SizedBox(height: 12),
            _buildConditionItem('Ảnh đại diện', _hasAvatar),
            _buildConditionItem('Bảng giá', _hasPrice),
            _buildConditionItem('Cấu hình thanh toán', _hasPayment),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionItem(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.error,
          color: isMet ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isMet ? Colors.green : Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOke = (_coSoData['is_oke'] ?? 0) == 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Trạng thái sân'),
        backgroundColor: Colors.white,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Card trạng thái
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      isOke ? Icons.visibility : Icons.visibility_off,
                      size: 64,
                      color: isOke ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isOke ? 'Sân đang hiển thị' : 'Sân đang ẩn',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isOke ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isOke
                          ? 'Sân của bạn đang được hiển thị cho người dùng'
                          : 'Sân của bạn đang bị ẩn khỏi người dùng',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Switch bật/tắt
            Card(
              child: SwitchListTile(
                title: const Text(
                  'Hiển thị sân trên app',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  isOke
                      ? 'Bật - Người dùng có thể thấy '
                      : 'Tắt - Người dùng không thể thấy sân',
                ),
                value: isOke,
                onChanged: _toggleIsOke,
                activeColor: Colors.green,
              ),
            ),

            const SizedBox(height: 24),

            // Điều kiện cần thiết
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Điều kiện để bật hiển thị sân:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildConditionRow('Ảnh đại diện', _hasAvatar),
                    const Divider(),
                    _buildConditionRow('Bảng giá (ít nhất 1 khung giờ có giá > 0)', _hasPrice),
                    const Divider(),
                    _buildConditionRow('Cấu hình thanh toán PayOS', _hasPayment),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Thông báo nếu chưa đủ điều kiện
            if (!_hasAvatar || !_hasPrice || !_hasPayment) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange[800]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hoàn thành tất cả điều kiện để bật hiển thị sân',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConditionRow(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.circle,
          color: isMet ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isMet ? Colors.green : Colors.grey,
              decoration: isMet ? null : TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }
}