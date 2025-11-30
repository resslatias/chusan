import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChinhSuaGioVaGiaPage extends StatefulWidget {
  const ChinhSuaGioVaGiaPage({super.key});

  @override
  State<ChinhSuaGioVaGiaPage> createState() => _ChinhSuaGioVaGiaPageState();
}

class _ChinhSuaGioVaGiaPageState extends State<ChinhSuaGioVaGiaPage> {
  static const primaryColor = Color(0xFF2E7D32);

  bool _isLoading = true;
  bool _isSaving = false;

  int _gioMoCua = 6;
  int _gioDongCua = 22;
  List<int> _bangGia = List.filled(24, 0);

  final List<TextEditingController> _priceControllers =
  List.generate(24, (_) => TextEditingController(text: '0'));

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (var controller in _priceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showMessage('Vui lòng đăng nhập', isError: true);
        return;
      }

      final docSnapshot = await FirebaseFirestore.instance
          .collection('co_so')
          .doc(user.uid)
          .get();

      if (!docSnapshot.exists) {
        _showMessage('Không tìm thấy thông tin cơ sở', isError: true);
        return;
      }

      final data = docSnapshot.data()!;

      // Load giờ mở cửa
      final gioMoString = data['gio_mo_cua'] as String?;
      if (gioMoString != null && gioMoString.contains(':')) {
        _gioMoCua = int.tryParse(gioMoString.split(':')[0]) ?? 6;
      }

      // Load giờ đóng cửa
      final gioDongString = data['gio_dong_cua'] as String?;
      if (gioDongString != null && gioDongString.contains(':')) {
        _gioDongCua = int.tryParse(gioDongString.split(':')[0]) ?? 22;
      }

      // Load bảng giá
      final bangGiaData = data['bang_gia'] as List<dynamic>?;
      if (bangGiaData != null && bangGiaData.length == 24) {
        _bangGia = bangGiaData.map((e) =>
        e is int ? e : (e as num).toInt()
        ).toList();

        // Cập nhật controllers
        for (int i = 0; i < 24; i++) {
          _priceControllers[i].text = _bangGia[i].toString();
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Lỗi tải dữ liệu: $e', isError: true);
    }
  }

  Future<void> _saveData() async {
    // Validate giờ
    if (_gioMoCua >= _gioDongCua) {
      _showMessage('Giờ mở cửa phải nhỏ hơn giờ đóng cửa', isError: true);
      return;
    }

    // Validate giá trong khoảng giờ mở cửa
    for (int i = _gioMoCua; i < _gioDongCua; i++) {
      final giaText = _priceControllers[i].text.trim();
      if (giaText.isEmpty) {
        _showMessage('Vui lòng nhập giá cho ${i}h-${i+1}h', isError: true);
        return;
      }

      final gia = int.tryParse(giaText);
      if (gia == null || gia < 1000) {
        _showMessage('Giá cho ${i}h-${i+1}h phải lớn hơn 1000', isError: true);
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showMessage('Vui lòng đăng nhập', isError: true);
        setState(() => _isSaving = false);
        return;
      }

      // Cập nhật bảng giá từ controllers
      for (int i = 0; i < 24; i++) {
        _bangGia[i] = int.tryParse(_priceControllers[i].text.trim()) ?? 0;
      }

      await FirebaseFirestore.instance
          .collection('co_so')
          .doc(user.uid)
          .update({
        'gio_mo_cua': '${_gioMoCua.toString().padLeft(2, '0')}:00',
        'gio_dong_cua': '${_gioDongCua.toString().padLeft(2, '0')}:00',
        'bang_gia': _bangGia,
      });

      setState(() => _isSaving = false);
      _showMessage('Cập nhật thành công!');

      // Quay lại sau 1 giây
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      setState(() => _isSaving = false);
      _showMessage('Lỗi cập nhật: $e', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: primaryColor),
      )
          : Column(
        children: [
          // ===== HEADER =====
          Container(
            padding: const EdgeInsets.only(
                top: 8, left: 16, right: 16, bottom: 8),
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
                const Text(
                  "Giờ mở cửa + Giá sân",
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // ===== NỘI DUNG =====
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimeSection(),
                  const SizedBox(height: 24),
                  _buildPriceSection(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // ===== NÚT LƯU =====
          _buildSaveButton(),
        ],
      ),
    );
  }


  Widget _buildTimeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Giờ hoạt động',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // GIỜ MỞ CỬA
          Row(
            children: [
              const SizedBox(
                width: 100,
                child: Text(
                  'Giờ mở cửa:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _gioMoCua,
                      isExpanded: true,
                      items: List.generate(24, (index) {
                        return DropdownMenuItem(
                          value: index,
                          child: Text('${index.toString().padLeft(2, '0')}:00'),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null && value < _gioDongCua) {
                          setState(() => _gioMoCua = value);
                        } else {
                          _showMessage(
                            'Giờ mở cửa phải nhỏ hơn giờ đóng cửa',
                            isError: true,
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // GIỜ ĐÓNG CỬA
          Row(
            children: [
              const SizedBox(
                width: 100,
                child: Text(
                  'Giờ đóng cửa:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _gioDongCua,
                      isExpanded: true,
                      items: List.generate(24, (index) {
                        return DropdownMenuItem(
                          value: index,
                          child: Text('${index.toString().padLeft(2, '0')}:00'),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null && value > _gioMoCua) {
                          setState(() => _gioDongCua = value);
                        } else {
                          _showMessage(
                            'Giờ đóng cửa phải lớn hơn giờ mở cửa',
                            isError: true,
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chỉ cần nhập giá cho các giờ trong khoảng mở cửa',
                    style: TextStyle(fontSize: 12, color: primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_money, color: primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Bảng giá theo giờ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // DANH SÁCH GIÁ
          ...List.generate(24, (index) {
            final isInRange = index >= _gioMoCua && index < _gioDongCua;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isInRange
                    ? primaryColor.withOpacity(0.05)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isInRange
                      ? primaryColor.withOpacity(0.3)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  // ICON & THỜI GIAN
                  Container(
                    width: 80,
                    child: Row(
                      children: [
                        Icon(
                          _getIconForHour(index),
                          size: 18,
                          color: isInRange ? primaryColor : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${index}h-${index+1}h',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isInRange ? Colors.black87 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // INPUT GIÁ
                  Expanded(
                    child: TextField(
                      controller: _priceControllers[index],
                      enabled: isInRange,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isInRange ? primaryColor : Colors.grey,
                      ),
                      decoration: InputDecoration(
                        hintText: isInRange ? 'Nhập giá' : 'Ngoài giờ',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                        suffixText: 'đ',
                        suffixStyle: TextStyle(
                          color: isInRange ? primaryColor : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        filled: true,
                        fillColor: isInRange ? Colors.white : Colors.grey.shade50,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _getIconForHour(int hour) {
    if (hour >= 6 && hour < 12) return Icons.wb_sunny;
    if (hour >= 12 && hour < 18) return Icons.cloud;
    return Icons.nightlight_round;
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveData,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text(
              'Lưu thay đổi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}