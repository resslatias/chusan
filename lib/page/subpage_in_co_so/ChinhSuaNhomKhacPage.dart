import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChinhSuaNhomKhacPage extends StatefulWidget {
  const ChinhSuaNhomKhacPage({super.key});

  @override
  State<ChinhSuaNhomKhacPage> createState() => _ChinhSuaNhomKhacPageState();
}

class _ChinhSuaNhomKhacPageState extends State<ChinhSuaNhomKhacPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _coSoKey;
  bool _isLoading = true;
  bool _isSaving = false;

  // Danh sách nhóm
  List<Map<String, dynamic>> _nhomList = [];
  List<TextEditingController> _linkControllers = [];
  List<TextEditingController> _nenTangControllers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (var c in _linkControllers) {
      c.dispose();
    }
    for (var c in _nenTangControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ==================== LOAD DATA ====================
  Future<void> _loadData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng đăng nhập')),
          );
          Navigator.pop(context);
        }
        return;
      }

      _coSoKey = user.uid;
      final doc = await _firestore.collection('co_so').doc(_coSoKey).get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        final nhomSeVe = data['nhom_xe_ve'] ?? data['nhom_xe_ve'] ?? [];

        if (nhomSeVe is List) {
          _nhomList = List<Map<String, dynamic>>.from(
            nhomSeVe.map((item) {
              if (item is Map<String, dynamic>) {
                return {
                  'link': item['link'] ?? '',
                  'nen_tang': item['nen_tang'] ?? 'Zalo',
                };
              }
              return {'link': '', 'nen_tang': 'Zalo'};
            }),
          );
        }

        // Tạo controllers
        _linkControllers = _nhomList
            .map((e) => TextEditingController(text: e['link'] ?? ''))
            .toList();
        _nenTangControllers = _nhomList
            .map((e) => TextEditingController(text: e['nen_tang'] ?? 'Zalo'))
            .toList();
      }
    } catch (e) {
      debugPrint('Lỗi load data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==================== SAVE DATA ====================
  Future<void> _saveData() async {
    if (_coSoKey == null) return;

    // Kiểm tra dữ liệu hợp lệ
    for (int i = 0; i < _nhomList.length; i++) {
      if (_linkControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nhóm ${i + 1}: Vui lòng nhập link')),
        );
        return;
      }
      if (_nenTangControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nhóm ${i + 1}: Vui lòng nhập tên nền tảng')),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      // Cập nhật dữ liệu từ controllers
      for (int i = 0; i < _nhomList.length; i++) {
        _nhomList[i]['link'] = _linkControllers[i].text.trim();
        _nhomList[i]['nen_tang'] = _nenTangControllers[i].text.trim();
      }

      // Lưu vào Firestore (dùng nhom_xe_ve thống nhất)
      await _firestore.collection('co_so').doc(_coSoKey).update({
        'nhom_xe_ve': _nhomList,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu thành công'),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Lỗi save: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // ==================== THÊM NHÓM ====================
  void _addNhom() {
    setState(() {
      _nhomList.add({
        'link': '',
        'nen_tang': 'Zalo',
      });
      _linkControllers.add(TextEditingController());
      _nenTangControllers.add(TextEditingController(text: 'Zalo'));
    });
  }

  // ==================== XÓA NHÓM ====================
  void _removeNhom(int index) {
    setState(() {
      _nhomList.removeAt(index);
      _linkControllers[index].dispose();
      _nenTangControllers[index].dispose();
      _linkControllers.removeAt(index);
      _nenTangControllers.removeAt(index);
    });
  }

  // ==================== BUILD UI ====================
  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2E7D32);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
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
                    "Chỉnh sửa nhóm khác",
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (_isSaving)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryColor,
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.save, color: primaryColor),
                    onPressed: _saveData,
                    tooltip: 'Lưu',
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
                  // Tiêu đề + nút thêm
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Danh sách nhóm Zalo/Facebook',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addNhom,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Thêm'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Hướng dẫn
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Thêm link nhóm Zalo/Facebook để khách hàng dễ dàng liên hệ và trao đổi',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Danh sách nhóm
                  if (_nhomList.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          Icon(Icons.group_off, size: 60, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'Chưa có nhóm nào',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Nhấn nút "Thêm" để tạo nhóm mới',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _nhomList.length,
                      itemBuilder: (context, index) {
                        return _buildNhomCard(index);
                      },
                    ),

                  const SizedBox(height: 32),

                  // Nút lưu lớn ở cuối
                  if (_nhomList.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveData,
                        icon: _isSaving
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(Icons.save),
                        label: Text(
                          _isSaving ? 'Đang lưu...' : 'Lưu thay đổi',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BUILD NHOM CARD ====================
  Widget _buildNhomCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Số thứ tự + nút xóa
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Nhóm',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _showDeleteConfirmation(index),
                tooltip: 'Xóa',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Nền tảng
          TextField(
            controller: _nenTangControllers[index],
            decoration: InputDecoration(
              labelText: 'Nền tảng (Zalo, Facebook, ...)',
              prefixIcon: const Icon(Icons.groups, color: Color(0xFF2E7D32)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),

          const SizedBox(height: 12),

          // Link
          TextField(
            controller: _linkControllers[index],
            decoration: InputDecoration(
              labelText: 'Link nhóm',
              prefixIcon: const Icon(Icons.link, color: Color(0xFF2E7D32)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            keyboardType: TextInputType.url,
          ),
        ],
      ),
    );
  }

  // ==================== XÁC NHẬN XÓA ====================
  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa nhóm ${index + 1}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removeNhom(index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}