import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class HoanTienPage extends StatefulWidget {
  const HoanTienPage({super.key});

  @override
  State<HoanTienPage> createState() => _HoanTienPageState();
}

class _HoanTienPageState extends State<HoanTienPage> {
  String _filter = 'all';
  String _phoneFilter = '';
  String _maDonFilter = '';
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _maDonController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _maDonController.dispose();
    super.dispose();
  }

  void _showDateFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lọc theo khoảng ngày'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Từ ngày'),
              subtitle: _startDate == null
                  ? const Text('Chưa chọn')
                  : Text('${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _startDate = picked);
                }
                Navigator.pop(context);
                _showDateFilterDialog(context);
              },
            ),
            ListTile(
              title: const Text('Đến ngày'),
              subtitle: _endDate == null
                  ? const Text('Chưa chọn')
                  : Text('${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _endDate = picked);
                }
                Navigator.pop(context);
                _showDateFilterDialog(context);
              },
            ),
            if (_startDate != null || _endDate != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Xóa lọc ngày'),
              ),
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

  void _showPhoneFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lọc theo số điện thoại'),
        content: TextField(
          controller: _phoneController,
          decoration: const InputDecoration(
            hintText: 'Nhập số điện thoại',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
        actions: [
          if (_phoneFilter.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _phoneFilter = '';
                  _phoneController.clear();
                });
                Navigator.pop(context);
              },
              child: const Text('Xóa lọc'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _phoneFilter = _phoneController.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }

  void _showMaDonFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lọc theo mã đơn'),
        content: TextField(
          controller: _maDonController,
          decoration: const InputDecoration(
            hintText: 'Nhập mã đơn',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          if (_maDonFilter.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _maDonFilter = '';
                  _maDonController.clear();
                });
                Navigator.pop(context);
              },
              child: const Text('Xóa lọc'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _maDonFilter = _maDonController.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 16),
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
                const Text(
                  'Hoàn tiền',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    _buildFilterButton(
                      icon: Icons.phone,
                      label: 'Lọc SĐT',
                      onPressed: () => _showPhoneFilterDialog(context),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterButton(
                      icon: Icons.qr_code,
                      label: 'Mã đơn',
                      onPressed: () => _showMaDonFilterDialog(context),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterButton(
                      icon: Icons.calendar_today,
                      label: 'Lọc ngày',
                      onPressed: () => _showDateFilterDialog(context),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterButton(
                      icon: Icons.filter_list,
                      label: 'Trạng thái',
                      onPressed: null,
                      isPopup: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isPopup = false,
  }) {
    if (isPopup) {
      return PopupMenuButton<String>(
        onSelected: (val) => setState(() => _filter = val),
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'all', child: Text('Tất cả')),
          const PopupMenuItem(value: 'chua_hoan', child: Text('Chưa hoàn')),
          const PopupMenuItem(value: 'da_hoan', child: Text('Đã hoàn')),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Chưa đăng nhập'));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('cho_hoan_tien_2')
          .doc(uid)
          .collection('khach_hang')
          .snapshots(),
      builder: (context, khachSnapshot) {
        if (khachSnapshot.hasError) {
          return Center(child: Text('Lỗi: ${khachSnapshot.error}'));
        }
        if (khachSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final khachDocs = khachSnapshot.data?.docs ?? [];
        if (khachDocs.isEmpty) {
          return const Center(child: Text('Không có đơn hoàn tiền'));
        }

        return _OrderListBuilder(
          khachDocs: khachDocs,
          coSoId: uid,
          filter: _filter,
          phoneFilter: _phoneFilter,
          maDonFilter: _maDonFilter,
          startDate: _startDate,
          endDate: _endDate,
        );
      },
    );
  }
}

class _OrderListBuilder extends StatelessWidget {
  final List<QueryDocumentSnapshot> khachDocs;
  final String coSoId;
  final String filter;
  final String phoneFilter;
  final String maDonFilter;
  final DateTime? startDate;
  final DateTime? endDate;

  const _OrderListBuilder({
    required this.khachDocs,
    required this.coSoId,
    required this.filter,
    required this.phoneFilter,
    required this.maDonFilter,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadAllOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        var orders = snapshot.data ?? [];

        // Lọc theo trạng thái
        if (filter == 'chua_hoan') {
          orders = orders.where((data) => data['da_hoan_tien'] != true).toList();
        } else if (filter == 'da_hoan') {
          orders = orders.where((data) => data['da_hoan_tien'] == true).toList();
        }

        // Lọc theo số điện thoại
        if (phoneFilter.isNotEmpty) {
          orders = orders.where((data) {
            final sdt = data['sdt'] as String? ?? '';
            return sdt.contains(phoneFilter);
          }).toList();
        }

        // Lọc theo mã đơn
        if (maDonFilter.isNotEmpty) {
          orders = orders.where((data) {
            final maDon = data['ma_don'] as String? ?? '';
            return maDon.toLowerCase().contains(maDonFilter.toLowerCase());
          }).toList();
        }

        // Lọc theo khoảng ngày
        if (startDate != null || endDate != null) {
          orders = orders.where((data) {
            final ngayYeuCauHuy = data['ngay_yeu_cau_huy'] as Timestamp?;
            if (ngayYeuCauHuy == null) return false;

            final ngay = ngayYeuCauHuy.toDate();

            if (startDate != null && ngay.isBefore(startDate!)) {
              return false;
            }
            if (endDate != null && ngay.isAfter(endDate!)) {
              return false;
            }
            return true;
          }).toList();
        }

        // Sắp xếp theo thời gian
        orders.sort((a, b) {
          final timeA = a['ngay_yeu_cau_huy'] as Timestamp?;
          final timeB = b['ngay_yeu_cau_huy'] as Timestamp?;
          if (timeA == null || timeB == null) return 0;
          return timeB.compareTo(timeA);
        });

        if (orders.isEmpty) {
          return const Center(child: Text('Không có đơn hoàn tiền'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) => _OrderCard(data: orders[index]),
        );
      },
    );
  }

  // 🔥 FIX: Thêm user_id vào mỗi đơn hàng
  Future<List<Map<String, dynamic>>> _loadAllOrders() async {
    final List<Map<String, dynamic>> allOrders = [];

    for (var khachDoc in khachDocs) {
      final userId = khachDoc.id; // 👈 Lấy userId từ document ID

      final donDatSnapshot = await FirebaseFirestore.instance
          .collection('cho_hoan_tien_2')
          .doc(coSoId)
          .collection('khach_hang')
          .doc(userId)
          .collection('don_dat')
          .get();

      for (var donDoc in donDatSnapshot.docs) {
        final orderData = donDoc.data();
        // 🔥 Thêm user_id vào dữ liệu đơn hàng
        orderData['user_id'] = userId;
        allOrders.add(orderData);
      }
    }

    return allOrders;
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _OrderCard({required this.data});

  String _fmt(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
  );

  @override
  Widget build(BuildContext context) {
    final maDon = data['ma_don'] as String? ?? '';
    final tenKhach = data['ten_nguoi_dat'] as String? ?? '';
    final sdt = data['sdt'] as String? ?? '';
    final tongTien = (data['tong_tien'] as num?)?.toInt() ?? 0;
    final daHoan = data['da_hoan_tien'] == true;
    final minhChung = data['minh_chung'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenKhach,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'SĐT: $sdt',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      Text(
                        'Mã: #${maDon.substring(0, 8).toUpperCase()}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: daHoan ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    daHoan ? 'Đã hoàn' : 'Chưa hoàn',
                    style: TextStyle(
                      color: daHoan ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Số tiền hoàn (80%):'),
                  Text(
                    '${_fmt((tongTien * 0.8).toInt())}đ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            if (!daHoan) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showConfirm(context),
                  icon: const Icon(Icons.upload, size: 18),
                  label: const Text('Xác nhận đã hoàn tiền'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ] else if (minhChung.isNotEmpty) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _showImage(context, minhChung),
                child: Row(
                  children: [
                    const Icon(Icons.image, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    const Text(
                      'Xem minh chứng',
                      style: TextStyle(color: Colors.blue, fontSize: 13),
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

  void _showImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Image.network(url, fit: BoxFit.contain),
      ),
    );
  }

  void _showConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ConfirmDialog(data: data),
    );
  }
}

class _ConfirmDialog extends StatefulWidget {
  final Map<String, dynamic> data;

  const _ConfirmDialog({required this.data});

  @override
  State<_ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<_ConfirmDialog> {
  File? _image;
  bool _uploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _confirm() async {
    if (_image == null) {
      _showSnack('Vui lòng chọn ảnh minh chứng');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Cảnh báo quan trọng'),
        content: const Text(
          'Bạn hoàn toàn chịu trách nhiệm nếu chưa hoàn tiền mà nhấn xác nhận.\n\n'
              'Nếu bị người dùng báo cáo, bạn sẽ phải hoàn lại gấp 10 lần số tiền này.\n\n'
              'Bạn chắc chắn đã chuyển khoản?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _uploading = true);

    try {
      final url = await _uploadImage();
      await _updateFirestore(url);
      await _sendNotifications();

      if (mounted) {
        Navigator.pop(context);
        _showSnack('Cập nhật thành công');
      }
    } catch (e) {
      if (mounted) _showSnack('Lỗi: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<String> _uploadImage() async {
    final maDon = widget.data['ma_don'] as String;
    final ref = FirebaseStorage.instance
        .ref()
        .child('minh_chung_hoan_tien')
        .child('$maDon.jpg');
    await ref.putFile(_image!);
    return await ref.getDownloadURL();
  }

  Future<void> _updateFirestore(String url) async {
    final maDon = widget.data['ma_don'] as String;
    //  FIX: Lấy user_id từ data (đã được thêm trong _loadAllOrders)
    final userId = widget.data['user_id'] as String;
    final coSoId = widget.data['co_so_id'] as String;

    final updateData = {
      'da_hoan_tien': true,
      'time_hoan_tien': FieldValue.serverTimestamp(),
      'minh_chung': url,
    };

    final batch = FirebaseFirestore.instance.batch();

    // cho_hoan_tien
    final ref1 = FirebaseFirestore.instance
        .collection('cho_hoan_tien')
        .doc(userId)
        .collection('co_so')
        .doc(coSoId)
        .collection('don_dat')
        .doc(maDon);
    batch.update(ref1, updateData);

    // cho_hoan_tien_2
    final ref2 = FirebaseFirestore.instance
        .collection('cho_hoan_tien_2')
        .doc(coSoId)
        .collection('khach_hang')
        .doc(userId)
        .collection('don_dat')
        .doc(maDon);
    batch.update(ref2, updateData);

    // Giảm so_don_huy của người dùng về 0
    final ref3 = FirebaseFirestore.instance
        .collection('nguoi_thue')
        .doc(userId);
    batch.update(ref3, {
      'so_don_huy': 0,
    });

    await batch.commit();
  }

  Future<void> _sendNotifications() async {
    final maDon = widget.data['ma_don'] as String;
    final userId = widget.data['user_id'] as String;
    final coSoId = widget.data['co_so_id'] as String;
    final tenCoSo = widget.data['ten_co_so'] as String? ?? '';

    final firestore = FirebaseFirestore.instance;

    // Thông báo cho user
    await firestore
        .collection('thong_bao')
        .doc(userId)
        .collection('notifications')
        .add({
      'tieu_de': 'Đã nhận hoàn tiền',
      'noi_dung': 'Chủ sân $tenCoSo đã xác nhận hoàn 80% tiền cho đơn #${maDon.substring(0, 8).toUpperCase()}',
      'da_xem_chua': false,
      'Urlweb': null,
      'Urlimage': null,
      'ngay_tao': FieldValue.serverTimestamp(),
    });

    // Thông báo cho chủ sân
    await firestore
        .collection('thong_bao_chu_san')
        .doc(coSoId)
        .collection('notifications')
        .add({
      'tieu_de': 'Đã hoàn tiền thành công',
      'noi_dung': 'Bạn đã xác nhận hoàn tiền cho đơn #${maDon.substring(0, 8).toUpperCase()}',
      'da_xem_chua': false,
      'ma_don': maDon,
      'ngay_tao': FieldValue.serverTimestamp(),
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tongTien = (widget.data['tong_tien'] as num?)?.toInt() ?? 0;
    final tienHoan = (tongTien * 0.8).toInt();

    return AlertDialog(
      title: const Text('Xác nhận hoàn tiền'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Số tiền hoàn: ${tienHoan.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}đ',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_image != null)
              Image.file(_image!, height: 200, fit: BoxFit.cover)
            else
              Container(
                height: 150,
                color: Colors.grey[200],
                child: const Center(child: Text('Chưa chọn ảnh')),
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _uploading ? null : _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Chọn ảnh chuyển khoản'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _uploading ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _uploading ? null : _confirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
          ),
          child: _uploading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Xác nhận'),
        ),
      ],
    );
  }
}