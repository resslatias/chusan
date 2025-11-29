import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChinhSuaDichVuPage extends StatefulWidget {
  const ChinhSuaDichVuPage({super.key});

  @override
  State<ChinhSuaDichVuPage> createState() => _ChinhSuaDichVuPageState();
}

class _ChinhSuaDichVuPageState extends State<ChinhSuaDichVuPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _coSoKey;
  bool _isLoading = true;
  bool _isSaving = false;

  List<Map<String, dynamic>> _dichVuKhac = [];
  List<TextEditingController> _tenDVControllers = [];
  List<TextEditingController> _giaDVControllers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (var c in _tenDVControllers) c.dispose();
    for (var c in _giaDVControllers) c.dispose();
    super.dispose();
  }

  // ==================== LOAD DATA ====================
  Future<void> _loadData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      _coSoKey = user.uid;
      final doc = await _firestore.collection('co_so').doc(_coSoKey).get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        setState(() {
          _dichVuKhac = List<Map<String, dynamic>>.from(data['dich_vu_khac'] ?? []);
          _tenDVControllers = _dichVuKhac
              .map((e) => TextEditingController(text: '${e['ten'] ?? ''}'))
              .toList();
          _giaDVControllers = _dichVuKhac
              .map((e) => TextEditingController(text: '${e['gia'] ?? 0}'))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Lỗi load data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ==================== SAVE DATA ====================
  Future<void> _saveData() async {
    if (_coSoKey == null) return;

    setState(() => _isSaving = true);

    try {
      // Cập nhật dữ liệu từ controllers
      for (int i = 0; i < _dichVuKhac.length; i++) {
        _dichVuKhac[i]['ten'] = _tenDVControllers[i].text;
        _dichVuKhac[i]['gia'] = int.tryParse(_giaDVControllers[i].text) ?? 0;
      }

      await _firestore.collection('co_so').doc(_coSoKey).update({
        'dich_vu_khac': _dichVuKhac,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu thành công')),
        );
      }
    } catch (e) {
      debugPrint('Lỗi save: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ==================== THÊM DỊCH VỤ ====================
  void _themDichVu() {
    setState(() {
      _dichVuKhac.add({'ten': 'Dịch vụ mới', 'gia': 0});
      _tenDVControllers.add(TextEditingController(text: 'Dịch vụ mới'));
      _giaDVControllers.add(TextEditingController(text: '0'));
    });
  }

  // ==================== XÓA DỊCH VỤ ====================
  Future<void> _xoaDichVu(int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xóa dịch vụ này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    setState(() {
      _dichVuKhac.removeAt(index);
      _tenDVControllers[index].dispose();
      _giaDVControllers[index].dispose();
      _tenDVControllers.removeAt(index);
      _giaDVControllers.removeAt(index);
    });
  }

  // ==================== BUILD UI ====================
  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2E7D32);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // ============================
          // HEADER
          // ============================
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
                    "Chỉnh sửa dịch vụ",
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Nút lưu
                if (_isSaving)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.save, color: primaryColor),
                    onPressed: _saveData,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),

          // ============================
          // BODY
          // ============================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================== DANH SÁCH DỊCH VỤ ====================
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Danh sách dịch vụ',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              Text(
                                '${_dichVuKhac.length} dịch vụ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Danh sách dịch vụ
                          if (_dichVuKhac.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Icon(Icons.home_repair_service,
                                        size: 60,
                                        color: Colors.grey[400]),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Chưa có dịch vụ nào',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _dichVuKhac.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Row(
                                    children: [
                                      // Tên dịch vụ
                                      Expanded(
                                        flex: 2,
                                        child: TextField(
                                          controller: _tenDVControllers[index],
                                          decoration: const InputDecoration(
                                            labelText: 'Tên dịch vụ',
                                            border: OutlineInputBorder(),
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 10
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Giá
                                      Expanded(
                                        child: TextField(
                                          controller: _giaDVControllers[index],
                                          decoration: const InputDecoration(
                                            labelText: 'Giá (VND)',
                                            border: OutlineInputBorder(),
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 10
                                            ),
                                          ),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly
                                          ],
                                        ),
                                      ),

                                      // Nút xóa
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _xoaDichVu(index),
                                        padding: const EdgeInsets.all(8),
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ==================== NÚT THÊM DỊCH VỤ ====================
                  InkWell(
                    onTap: _themDichVu,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: primaryColor, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline, color: primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Thêm dịch vụ mới',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}