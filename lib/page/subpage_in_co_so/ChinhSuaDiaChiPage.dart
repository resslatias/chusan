import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChinhSuaDiaChiPage extends StatefulWidget {
  const ChinhSuaDiaChiPage({super.key});

  @override
  State<ChinhSuaDiaChiPage> createState() => _ChinhSuaDiaChiPageState();
}

class _ChinhSuaDiaChiPageState extends State<ChinhSuaDiaChiPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _coSoKey;
  bool _isLoading = true;

  // Controllers
  final _tenController = TextEditingController();
  final _diaChiChiTietController = TextEditingController();
  final _xaController = TextEditingController();
  final _huyenController = TextEditingController();
  final _tinhController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _tenController.dispose();
    _diaChiChiTietController.dispose();
    _xaController.dispose();
    _huyenController.dispose();
    _tinhController.dispose();
    super.dispose();
  }

  // ==================== LOAD DATA ====================
  Future<void> _loadData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập')));
          Navigator.pop(context);
        }
        return;
      }

      _coSoKey = user.uid;

      final doc = await _firestore.collection('co_so').doc(_coSoKey).get();
      if (doc.exists) {
        final data = doc.data() ?? {};

        _tenController.text = data['ten'] ?? '';
        _diaChiChiTietController.text = data['dia_chi_chi_tiet'] ?? '';
        _xaController.text = data['xa'] ?? '';
        _huyenController.text = data['huyen'] ?? '';
        _tinhController.text = data['tinh'] ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Lỗi tải dữ liệu: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==================== BUILD UI ====================
  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2E7D32);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  blurRadius: 6,
                  color: Colors.black26,
                  offset: Offset(0, 3),
                )
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: primaryColor),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Thông tin địa chỉ sân",
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // BODY
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLockedField("Tên sân", _tenController),
                  const SizedBox(height: 16),
                  _buildLockedField("Địa chỉ chi tiết", _diaChiChiTietController),
                  const SizedBox(height: 16),
                  _buildLockedField("Tỉnh / Thành phố", _tinhController),
                  const SizedBox(height: 16),
                  _buildLockedField("Quận / Huyện", _huyenController),
                  const SizedBox(height: 16),
                  _buildLockedField("Phường / Xã", _xaController),
                  const SizedBox(height: 24),

                  // THÔNG BÁO ĐỎ
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Để sửa các thông tin này, vui lòng liên hệ CSKH qua số điện thoại 0915033623 hoặc email n2ui9323@gmail.com",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // FIELD CHỈ ĐỂ XEM
  Widget _buildLockedField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF2E7D32),
            )),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: TextFormField(
            controller: controller,
            readOnly: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
