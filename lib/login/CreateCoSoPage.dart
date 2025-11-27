import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateCoSoPage extends StatefulWidget {
  const CreateCoSoPage({super.key});

  @override
  State<CreateCoSoPage> createState() => _CreateCoSoPageState();
}

class _CreateCoSoPageState extends State<CreateCoSoPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _tenCoSoCtrl = TextEditingController();
  final _diaChiChiTietCtrl = TextEditingController();
  final _xaCtrl = TextEditingController();
  final _huyenCtrl = TextEditingController();
  final _tinhCtrl = TextEditingController();
  final _sdtCtrl = TextEditingController();
  final _webCtrl = TextEditingController();
  final _moTaCtrl = TextEditingController();

  String _gioMoCua = '06:00';
  String _gioDongCua = '22:00';
  int _soSan = 4;

  bool _isCreating = false;

  @override
  void dispose() {
    _tenCoSoCtrl.dispose();
    _diaChiChiTietCtrl.dispose();
    _xaCtrl.dispose();
    _huyenCtrl.dispose();
    _tinhCtrl.dispose();
    _sdtCtrl.dispose();
    _webCtrl.dispose();
    _moTaCtrl.dispose();
    super.dispose();
  }

  Future<void> _createCoSo() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Không tìm thấy thông tin đăng nhập');
      return;
    }

    setState(() => _isCreating = true);

    try {
      // Tạo bảng giá mặc định (24 giá trị)
      final bangGia = _createDefaultBangGia();

      // Tạo document cơ sở
      await FirebaseFirestore.instance
          .collection('co_so')
          .doc(user.uid)
          .set({
        'ten_co_so': _tenCoSoCtrl.text.trim(),
        'anh_dai_dien': '',
        'danh_sach_anh': [],
        'dia_chi_chi_tiet': _diaChiChiTietCtrl.text.trim(),
        'xa': _xaCtrl.text.trim(),
        'huyen': _huyenCtrl.text.trim(),
        'tinh': _tinhCtrl.text.trim(),
        'sdt': _sdtCtrl.text.trim(),
        'web': _webCtrl.text.trim(),
        'gio_mo_cua': _gioMoCua,
        'gio_dong_cua': _gioDongCua,
        'so_san': _soSan,
        'mo_ta': _moTaCtrl.text.trim(),
        'is_oke': 0, // Mặc định tắt
        'vi_tri': null, // Sẽ cập nhật sau
        'gia_san': [], // Sẽ cập nhật sau
        'dich_vu_khac': [], // Sẽ cập nhật sau
        'nhom_se_ve': [], // Sẽ cập nhật sau
        'bang_gia': bangGia,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showMessage('Tạo cơ sở thành công!');
        // Chuyển sang màn hình chính
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      debugPrint('❌ Lỗi tạo cơ sở: $e');
      if (mounted) {
        _showMessage('Lỗi: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  List<int> _createDefaultBangGia() {
    // Tạo bảng giá 24 giờ với logic:
    // - Sáng (6h-16h): 60.000đ
    // - Tối (16h-22h): 120.000đ
    // - Đóng cửa (22h-6h): 0đ
    List<int> bangGia = List.filled(24, 0);

    final gioMo = int.tryParse(_gioMoCua.split(':')[0]) ?? 6;
    final gioDong = int.tryParse(_gioDongCua.split(':')[0]) ?? 22;

    for (int i = 0; i < 24; i++) {
      if (i >= gioMo && i < gioDong) {
        if (i < 16) {
          bangGia[i] = 60000; // Giờ sáng
        } else {
          bangGia[i] = 120000; // Giờ tối
        }
      } else {
        bangGia[i] = 0; // Đóng cửa
      }
    }

    return bangGia;
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Tạo cơ sở mới'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon và tiêu đề
                Icon(
                  Icons.store,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(height: 16),
                Text(
                  'Chào mừng đến KL10!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Tạo cơ sở đầu tiên của bạn',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 32),

                // THÔNG TIN CƠ BẢN
                _buildSectionTitle('Thông tin cơ bản'),
                SizedBox(height: 12),

                _buildTextField(
                  controller: _tenCoSoCtrl,
                  label: 'Tên cơ sở',
                  hint: 'VD: Sân Cầu 120 Định Công',
                  icon: Icons.store,
                  validator: (v) => v?.trim().isEmpty == true ? 'Vui lòng nhập tên cơ sở' : null,
                ),
                SizedBox(height: 16),

                _buildTextField(
                  controller: _sdtCtrl,
                  label: 'Số điện thoại',
                  hint: 'VD: 0367273632',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v?.trim().isEmpty == true) return 'Vui lòng nhập số điện thoại';
                    if (v!.length < 10) return 'Số điện thoại không hợp lệ';
                    return null;
                  },
                ),
                SizedBox(height: 16),

                _buildTextField(
                  controller: _webCtrl,
                  label: 'Website (không bắt buộc)',
                  hint: 'VD: https://example.com',
                  icon: Icons.language,
                  keyboardType: TextInputType.url,
                ),
                SizedBox(height: 24),

                // ĐỊA CHỈ
                _buildSectionTitle('Địa chỉ'),
                SizedBox(height: 12),

                _buildTextField(
                  controller: _diaChiChiTietCtrl,
                  label: 'Địa chỉ chi tiết',
                  hint: 'VD: 120 Định Công',
                  icon: Icons.location_on,
                  validator: (v) => v?.trim().isEmpty == true ? 'Vui lòng nhập địa chỉ' : null,
                ),
                SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _xaCtrl,
                        label: 'Phường/Xã',
                        hint: 'VD: Thanh Xuân',
                        icon: Icons.home,
                        validator: (v) => v?.trim().isEmpty == true ? 'Nhập phường/xã' : null,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _huyenCtrl,
                        label: 'Quận/Huyện',
                        hint: 'VD: Hoàng Mai',
                        icon: Icons.location_city,
                        validator: (v) => v?.trim().isEmpty == true ? 'Nhập quận/huyện' : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                _buildTextField(
                  controller: _tinhCtrl,
                  label: 'Tỉnh/Thành phố',
                  hint: 'VD: Hà Nội',
                  icon: Icons.location_city,
                  validator: (v) => v?.trim().isEmpty == true ? 'Vui lòng nhập tỉnh/thành phố' : null,
                ),
                SizedBox(height: 24),

                // THÔNG TIN SÂN
                _buildSectionTitle('Thông tin sân'),
                SizedBox(height: 12),

                // Số sân
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.sports_tennis, color: Theme.of(context).colorScheme.primary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Số sân',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '$_soSan sân',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline),
                        onPressed: _soSan > 1 ? () => setState(() => _soSan--) : null,
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline),
                        onPressed: () => setState(() => _soSan++),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Giờ mở cửa - đóng cửa
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeSelector(
                        label: 'Giờ mở cửa',
                        value: _gioMoCua,
                        onChanged: (v) => setState(() => _gioMoCua = v!),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildTimeSelector(
                        label: 'Giờ đóng cửa',
                        value: _gioDongCua,
                        onChanged: (v) => setState(() => _gioDongCua = v!),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                _buildTextField(
                  controller: _moTaCtrl,
                  label: 'Mô tả',
                  hint: 'Mô tả về cơ sở của bạn...',
                  icon: Icons.description,
                  maxLines: 4,
                ),
                SizedBox(height: 32),

                // Nút tạo
                FilledButton(
                  onPressed: _isCreating ? null : _createCoSo,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isCreating
                      ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Text(
                    'Tạo cơ sở',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Note
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bạn có thể cập nhật ảnh, bảng giá, dịch vụ sau khi tạo xong.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required String value,
    required void Function(String?) onChanged,
  }) {
    final hours = List.generate(24, (i) {
      final h = i.toString().padLeft(2, '0');
      return '$h:00';
    });

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: SizedBox.shrink(),
            items: hours.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}