import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ThongTinCoSoPage extends StatefulWidget {
  const ThongTinCoSoPage({super.key});

  @override
  State<ThongTinCoSoPage> createState() => _ThongTinCoSoPageState();
}

class _ThongTinCoSoPageState extends State<ThongTinCoSoPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  String? _coSoKey;
  bool _isLoading = true;
  bool _isSaving = false;

  // Dữ liệu cơ sở
  Map<String, dynamic> _coSoData = {};

  // Controllers
  final _sdtController = TextEditingController();
  final _webController = TextEditingController();
  final _moTaController = TextEditingController();
  final _clientIdController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _checksumKeyController = TextEditingController();

  // Bảng giá 24 giờ & dịch vụ
  List<int> _bangGia = List.filled(24, 0);
  List<TextEditingController> _bangGiaControllers = [];

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
    _sdtController.dispose();
    _webController.dispose();
    _moTaController.dispose();
    _clientIdController.dispose();
    _apiKeyController.dispose();
    _checksumKeyController.dispose();
    for (var c in _bangGiaControllers) c.dispose();
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
        _coSoData = doc.data() ?? {};
        _populateControllers();
      }
    } catch (e) {
      debugPrint('Lỗi load data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _populateControllers() {
    _sdtController.text = _coSoData['sdt'] ?? '';
    _webController.text = _coSoData['web'] ?? '';
    _moTaController.text = _coSoData['mo_ta'] ?? '';
    _clientIdController.text = _coSoData['client_Id'] ?? '';
    _apiKeyController.text = _coSoData['api_Key'] ?? '';
    _checksumKeyController.text = _coSoData['checksum_Key'] ?? '';

    // Load bảng giá 24 giờ
    final bangGiaData = _coSoData['bang_gia'] as List<dynamic>?;
    if (bangGiaData != null && bangGiaData.length == 24) {
      _bangGia = bangGiaData.map((e) => (e is int ? e : (e as num).toInt())).toList();
    } else {
      _bangGia = List.filled(24, 0);
    }

    _bangGiaControllers = _bangGia.map((e) => TextEditingController(text: '$e')).toList();

    // Dịch vụ
    _dichVuKhac = List<Map<String, dynamic>>.from(_coSoData['dich_vu_khac'] ?? []);
    _tenDVControllers = _dichVuKhac.map((e) => TextEditingController(text: '${e['ten'] ?? ''}')).toList();
    _giaDVControllers = _dichVuKhac.map((e) => TextEditingController(text: '${e['gia'] ?? 0}')).toList();
  }

  // ==================== SAVE DATA ====================
  Future<void> _saveData() async {
    if (_coSoKey == null) return;

    setState(() => _isSaving = true);

    try {
      // Cập nhật bảng giá từ controllers
      for (int i = 0; i < _bangGia.length; i++) {
        _bangGia[i] = int.tryParse(_bangGiaControllers[i].text) ?? 0;
      }

      for (int i = 0; i < _dichVuKhac.length; i++) {
        _dichVuKhac[i]['ten'] = _tenDVControllers[i].text;
        _dichVuKhac[i]['gia'] = int.tryParse(_giaDVControllers[i].text) ?? 0;
      }

      final updateData = {
        'sdt': _sdtController.text,
        'web': _webController.text,
        'mo_ta': _moTaController.text,
        'client_Id': _clientIdController.text,
        'api_Key': _apiKeyController.text,
        'checksum_Key': _checksumKeyController.text,
        'bang_gia': _bangGia,
        'dich_vu_khac': _dichVuKhac,
      };

      await _firestore.collection('co_so').doc(_coSoKey).update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã lưu thành công'))
        );
      }
    } catch (e) {
      debugPrint('Lỗi save: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'))
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ==================== TOGGLE IS_OKE ====================
  Future<void> _toggleIsOke(bool value) async {
    if (value) {
      // Kiểm tra điều kiện trước khi bật
      final hasAvatar = _coSoData['anh_dai_dien'] != null && (_coSoData['anh_dai_dien'] as String).isNotEmpty;
      final hasPrice = _bangGia.any((gia) => gia > 0);
      final hasPayment = _clientIdController.text.isNotEmpty &&
          _apiKeyController.text.isNotEmpty &&
          _checksumKeyController.text.isNotEmpty;

      if (!hasAvatar || !hasPrice || !hasPayment) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cần có: ảnh đại diện, bảng giá và thông tin thanh toán'))
        );
        return;
      }
    }

    try {
      await _firestore.collection('co_so').doc(_coSoKey).update({'is_oke': value ? 1 : 0});
      setState(() => _coSoData['is_oke'] = value ? 1 : 0);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(value ? 'Đã bật hiển thị sân' : 'Đã tắt hiển thị sân'))
      );
    } catch (e) {
      debugPrint('Lỗi toggle: $e');
    }
  }

  // ==================== UPLOAD AVATAR ====================
  Future<void> _uploadAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image == null) return;

      setState(() => _isSaving = true);

      final bytes = await image.readAsBytes();
      final ref = FirebaseStorage.instance.ref().child('co_so/$_coSoKey/avatar.jpg');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();

      await _firestore.collection('co_so').doc(_coSoKey).update({
        'anh_dai_dien': '$url?t=${DateTime.now().millisecondsSinceEpoch}'
      });

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã cập nhật ảnh đại diện'))
        );
      }
    } catch (e) {
      debugPrint('Lỗi upload: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ==================== THÊM DỊCH VỤ ====================
  void _addDichVu() {
    setState(() {
      _dichVuKhac.add({'ten': 'Dịch vụ mới', 'gia': 0});
      _tenDVControllers.add(TextEditingController(text: 'Dịch vụ mới'));
      _giaDVControllers.add(TextEditingController(text: '0'));
    });
  }

  void _removeDichVu(int index) {
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Thông Tin Cơ Sở'),
        actions: [
          if (_isSaving)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ))
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveData,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIsOkeSection(),
            const SizedBox(height: 16),
            _buildAvatarSection(),
            const SizedBox(height: 16),
            _buildBasicInfoSection(),
            const SizedBox(height: 16),
            _buildPriceSection(),
            const SizedBox(height: 16),
            _buildServiceSection(),
            const SizedBox(height: 16),
            _buildPaymentSection(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ==================== SECTIONS ====================
  Widget _buildIsOkeSection() {
    final isOke = (_coSoData['is_oke'] ?? 0) == 1;
    return Card(
      child: SwitchListTile(
        title: const Text('Hiển thị sân trên app'),
        subtitle: Text(isOke ? 'Đang bật' : 'Đang tắt'),
        value: isOke,
        onChanged: _toggleIsOke,
      ),
    );
  }

  Widget _buildAvatarSection() {
    final avatar = _coSoData['anh_dai_dien'] as String?;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: (avatar != null && avatar.isNotEmpty) ? NetworkImage(avatar) : null,
              child: (avatar == null || avatar.isEmpty) ? const Icon(Icons.store, size: 40) : null,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Đổi ảnh đại diện'),
              onPressed: _uploadAvatar,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thông tin cơ bản', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _sdtController,
              decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _webController,
              decoration: const InputDecoration(labelText: 'Website (không bắt buộc)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _moTaController,
              decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder()),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSection() {
    final gioMoCua = _coSoData['gio_mo_cua'] as String?;
    final gioDongCua = _coSoData['gio_dong_cua'] as String?;

    final gioMo = gioMoCua != null ? int.tryParse(gioMoCua.split(':')[0]) ?? 6 : 6;
    final gioDong = gioDongCua != null ? int.tryParse(gioDongCua.split(':')[0]) ?? 22 : 22;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bảng giá sân (24 giờ)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Giờ hoạt động: ${gioMo}h - ${gioDong}h',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 24,
              itemBuilder: (context, index) {
                final isActive = index >= gioMo && index < gioDong;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${index}h - ${index + 1}h',
                          style: TextStyle(
                            color: isActive ? Colors.black : Colors.grey,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _bangGiaControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Giá (VND)',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            filled: !isActive,
                            fillColor: isActive ? null : Colors.grey[200],
                          ),
                          enabled: isActive,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Dịch vụ khác', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.add), onPressed: _addDichVu),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _dichVuKhac.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tenDVControllers[index],
                          decoration: const InputDecoration(
                            labelText: 'Tên',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _giaDVControllers[index],
                          decoration: const InputDecoration(
                            labelText: 'Giá',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeDichVu(index),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cấu hình thanh toán PayOS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _clientIdController,
              decoration: const InputDecoration(labelText: 'Client ID', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(labelText: 'API Key', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _checksumKeyController,
              decoration: const InputDecoration(labelText: 'Checksum Key', border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
    );
  }
}