import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChinhSuaAnhPage extends StatefulWidget {
  const ChinhSuaAnhPage({super.key});

  @override
  State<ChinhSuaAnhPage> createState() => _ChinhSuaAnhPageState();
}

class _ChinhSuaAnhPageState extends State<ChinhSuaAnhPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  String? _coSoKey;
  bool _isLoading = true;
  bool _isUploadingAvatar = false;
  bool _isUploadingAlbum = false;

  String? _anhDaiDien;
  List<String> _danhSachAnh = [];

  @override
  void initState() {
    super.initState();
    _loadData();
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
          _anhDaiDien = data['anh_dai_dien'] as String?;
          _danhSachAnh = List<String>.from(data['danh_sach_anh'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Lỗi load data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ==================== UPLOAD ẢNH ĐẠI DIỆN ====================
  Future<void> _uploadAnhDaiDien() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image == null) return;

      setState(() => _isUploadingAvatar = true);

      final bytes = await image.readAsBytes();
      final ref = FirebaseStorage.instance
          .ref()
          .child('co_so/$_coSoKey/avatar.jpg');

      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();

      // Thêm timestamp để tránh cache
      final urlWithTimestamp = '$url?t=${DateTime.now().millisecondsSinceEpoch}';

      await _firestore.collection('co_so').doc(_coSoKey).update({
        'anh_dai_dien': urlWithTimestamp,
      });

      setState(() => _anhDaiDien = urlWithTimestamp);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật ảnh đại diện')),
        );
      }
    } catch (e) {
      debugPrint('Lỗi upload ảnh đại diện: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      setState(() => _isUploadingAvatar = false);
    }
  }

  // ==================== THÊM ẢNH VÀO DANH SÁCH ====================
  Future<void> _themAnhVaoDanhSach() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 80);
      if (images.isEmpty) return;

      setState(() => _isUploadingAlbum = true);

      List<String> newUrls = [];

      for (var image in images) {
        final bytes = await image.readAsBytes();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final ref = FirebaseStorage.instance
            .ref()
            .child('co_so/$_coSoKey/album/img_$timestamp.jpg');

        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        final url = await ref.getDownloadURL();
        newUrls.add(url);
      }

      _danhSachAnh.addAll(newUrls);

      await _firestore.collection('co_so').doc(_coSoKey).update({
        'danh_sach_anh': _danhSachAnh,
      });

      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã thêm ${newUrls.length} ảnh')),
        );
      }
    } catch (e) {
      debugPrint('Lỗi thêm ảnh: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      setState(() => _isUploadingAlbum = false);
    }
  }

  // ==================== XÓA ẢNH ====================
  Future<void> _xoaAnh(int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xóa ảnh này?'),
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

    try {
      setState(() => _isUploadingAlbum = true);

      // Xóa khỏi Storage (optional - có thể bỏ qua nếu muốn giữ file)
      final url = _danhSachAnh[index];
      try {
        final ref = FirebaseStorage.instance.refFromURL(url);
        await ref.delete();
      } catch (e) {
        debugPrint('Không thể xóa file từ Storage: $e');
      }

      // Xóa khỏi danh sách
      _danhSachAnh.removeAt(index);

      await _firestore.collection('co_so').doc(_coSoKey).update({
        'danh_sach_anh': _danhSachAnh,
      });

      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa ảnh')),
        );
      }
    } catch (e) {
      debugPrint('Lỗi xóa ảnh: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      setState(() => _isUploadingAlbum = false);
    }
  }

  // ==================== XEM ẢNH FULL ====================
  void _xemAnhFull(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
          // HEADER NHỎ GỌN
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
                const Text(
                  "Chỉnh sửa ảnh",
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
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
                  // ==================== ẢNH ĐẠI DIỆN ====================
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ảnh đại diện',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Stack(
                              children: [
                                InkWell(
                                  onTap: (_anhDaiDien != null && _anhDaiDien!.isNotEmpty)
                                      ? () => _xemAnhFull(_anhDaiDien!)
                                      : null,
                                  child: CircleAvatar(
                                    radius: 70,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage: (_anhDaiDien != null && _anhDaiDien!.isNotEmpty)
                                        ? NetworkImage(_anhDaiDien!)
                                        : null,
                                    child: (_anhDaiDien == null || _anhDaiDien!.isEmpty)
                                        ? const Icon(Icons.store, size: 50, color: Colors.grey)
                                        : null,
                                  ),
                                ),
                                if (_isUploadingAvatar)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(color: Colors.white),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Đổi ảnh đại diện'),
                              onPressed: _isUploadingAvatar ? null : _uploadAnhDaiDien,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ==================== DANH SÁCH ẢNH ====================
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
                                'Album ảnh',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              Text(
                                '${_danhSachAnh.length} ảnh',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Nút thêm ảnh với loading
                          InkWell(
                            onTap: _isUploadingAlbum ? null : _themAnhVaoDanhSach,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: _isUploadingAlbum ? Colors.grey : primaryColor,
                                    width: 2
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: _isUploadingAlbum
                                    ? Colors.grey.withOpacity(0.05)
                                    : primaryColor.withOpacity(0.05),
                              ),
                              child: _isUploadingAlbum
                                  ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Đang tải ảnh lên...',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              )
                                  : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, color: primaryColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Thêm ảnh mới',
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

                          const SizedBox(height: 16),

                          // Grid ảnh
                          if (_danhSachAnh.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Icon(Icons.photo_library, size: 60, color: Colors.grey[400]),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Chưa có ảnh nào',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: _danhSachAnh.length,
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    InkWell(
                                      onTap: () => _xemAnhFull(_danhSachAnh[index]),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          image: DecorationImage(
                                            image: NetworkImage(_danhSachAnh[index]),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: InkWell(
                                        onTap: _isUploadingAlbum ? null : () => _xoaAnh(index),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: _isUploadingAlbum ? Colors.grey : Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
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