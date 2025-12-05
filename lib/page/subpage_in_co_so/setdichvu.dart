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
  List<TextEditingController> _donViControllers = [];
  List<TextEditingController> _soLuongControllers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (var c in _tenDVControllers) c.dispose();
    for (var c in _giaDVControllers) c.dispose();
    for (var c in _donViControllers) c.dispose();
    for (var c in _soLuongControllers) c.dispose();
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
          _donViControllers = _dichVuKhac
              .map((e) => TextEditingController(text: '${e['don_vi'] ?? ''}'))
              .toList();
          _soLuongControllers = _dichVuKhac
              .map((e) => TextEditingController(text: '${e['so_luong'] ?? 0}'))
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
        _dichVuKhac[i]['don_vi'] = _donViControllers[i].text;
        _dichVuKhac[i]['so_luong'] = int.tryParse(_soLuongControllers[i].text) ?? 0;
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
      _dichVuKhac.add({
        'ten': 'Tiện ích mới',
        'gia': 0,
        'don_vi': '',
        'so_luong': 0,
      });
      _tenDVControllers.add(TextEditingController(text: 'Tiện ích mới'));
      _giaDVControllers.add(TextEditingController(text: '0'));
      _donViControllers.add(TextEditingController(text: ''));
      _soLuongControllers.add(TextEditingController(text: '0'));
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
      _donViControllers[index].dispose();
      _soLuongControllers[index].dispose();
      _tenDVControllers.removeAt(index);
      _giaDVControllers.removeAt(index);
      _donViControllers.removeAt(index);
      _soLuongControllers.removeAt(index);
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
                    "Chỉnh sửa tiện ích",
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
                                'Danh sách tiện ích',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              Text(
                                '${_dichVuKhac.length} tiện ích',
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
                                      'Chưa có tiện ích nào',
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
                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // TIÊU ĐỀ NHỎ + NÚT XÓA
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Tiện ích ${index + 1}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF2E7D32),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                                              onPressed: () => _xoaDichVu(index),
                                              splashRadius: 20,
                                            )
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        // TÊN TIỆN ÍCH
                                        TextField(
                                          controller: _tenDVControllers[index],
                                          decoration: InputDecoration(
                                            labelText: 'Tên tiện ích',
                                            filled: true,
                                            fillColor: Colors.grey[100],
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),

                                        // ĐƠN VỊ + SỐ LƯỢNG
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: _donViControllers[index],
                                                decoration: InputDecoration(
                                                  labelText: 'Đơn vị',
                                                  filled: true,
                                                  fillColor: Colors.grey[100],
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: TextField(
                                                controller: _soLuongControllers[index],
                                                keyboardType: TextInputType.number,
                                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                decoration: InputDecoration(
                                                  labelText: 'Số lượng',
                                                  filled: true,
                                                  fillColor: Colors.grey[100],
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        // GIÁ
                                        TextField(
                                          controller: _giaDVControllers[index],
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          decoration: InputDecoration(
                                            labelText: 'Giá (VNĐ)',
                                            filled: true,
                                            fillColor: Colors.grey[100],
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
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
                            'Thêm tiện ích mới',
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