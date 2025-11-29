import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChinhSuaThongTinCoBanPage extends StatefulWidget {
  const ChinhSuaThongTinCoBanPage({super.key});

  @override
  State<ChinhSuaThongTinCoBanPage> createState() => _ChinhSuaThongTinCoBanPageState();
}

class _ChinhSuaThongTinCoBanPageState extends State<ChinhSuaThongTinCoBanPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  String? _coSoKey;
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers
  final _tenController = TextEditingController();
  final _sdtController = TextEditingController();
  final _webController = TextEditingController();
  final _moTaController = TextEditingController();
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
    _sdtController.dispose();
    _webController.dispose();
    _moTaController.dispose();
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

        _tenController.text = data['ten'] ?? '';
        _sdtController.text = data['sdt'] ?? '';
        _webController.text = data['web'] ?? '';
        _moTaController.text = data['mo_ta'] ?? '';
        _diaChiChiTietController.text = data['dia_chi_chi_tiet'] ?? '';
        _xaController.text = data['xa'] ?? '';
        _huyenController.text = data['huyen'] ?? '';
        _tinhController.text = data['tinh'] ?? '';
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_coSoKey == null) return;

    setState(() => _isSaving = true);

    try {
      final updateData = {
        'ten': _tenController.text.trim(),
        'sdt': _sdtController.text.trim(),
        'web': _webController.text.trim(),
        'mo_ta': _moTaController.text.trim(),
        'dia_chi_chi_tiet': _diaChiChiTietController.text.trim(),
        'xa': _xaController.text.trim(),
        'huyen': _huyenController.text.trim(),
        'tinh': _tinhController.text.trim(),
      };

      await _firestore.collection('co_so').doc(_coSoKey).update(updateData);

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
                    "Chỉnh sửa thông tin cơ bản",
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
               /* if (_isSaving)
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
                  ),*/
              ],
            ),
          ),

          // ============================
          // BODY
          // ============================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                   /* // Tên sân
                    _buildSectionTitle('Tên sân'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _tenController,
                      label: 'Tên sân',
                      icon: Icons.business,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tên sân';
                        }
                        return null;
                      },
                    ),*/

                  //  const SizedBox(height: 24),

                    // Thông tin liên hệ
                    _buildSectionTitle('Thông tin liên hệ'),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _sdtController,
                      label: 'Số điện thoại',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập số điện thoại';
                        }
                        if (value.trim().length < 10) {
                          return 'Số điện thoại không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _webController,
                      label: 'Website (không bắt buộc)',
                      icon: Icons.language,
                      keyboardType: TextInputType.url,
                    ),

                 //   const SizedBox(height: 24),
/*
                    // Địa chỉ
                    _buildSectionTitle('Địa chỉ'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _diaChiChiTietController,
                      label: 'Địa chỉ chi tiết',
                      icon: Icons.home,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập địa chỉ chi tiết';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _xaController,
                      label: 'Phường/Xã',
                      icon: Icons.location_city,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập phường/xã';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _huyenController,
                      label: 'Quận/Huyện',
                      icon: Icons.map,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập quận/huyện';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _tinhController,
                      label: 'Tỉnh/Thành phố',
                      icon: Icons.location_on,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tỉnh/thành phố';
                        }
                        return null;
                      },
                    ),
*/
                    const SizedBox(height: 24),

                    // Mô tả
                    _buildSectionTitle('Mô tả sân'),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _moTaController,
                      label: 'Mô tả',
                      icon: Icons.description,
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập mô tả';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // Nút lưu lớn ở cuối
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
          ),
        ],
      ),
    );
  }

  // ==================== WIDGETS ====================
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF2E7D32),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
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
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          errorStyle: const TextStyle(fontSize: 12),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
      ),
    );
  }
}