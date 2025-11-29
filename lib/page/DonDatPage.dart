import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DonDatPage extends StatefulWidget {
  const DonDatPage({super.key});

  @override
  State<DonDatPage> createState() => _DonDatPageState();
}

class _DonDatPageState extends State<DonDatPage> {
  String _filter = 'all'; // all, da_thanh_toan, da_huy
  String _phoneFilter = '';
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header mới - tất cả trong một hàng
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
                // Tiêu đề
                const Text(
                  'Đơn đặt sân',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Các nút lọc - giảm kích thước để vừa một hàng
                Row(
                  children: [
                    // Nút lọc SĐT
                    _buildFilterButton(
                      icon: Icons.phone,
                      label: 'Lọc SĐT',
                      onPressed: () => _showPhoneFilterDialog(context),
                    ),
                    const SizedBox(width: 8),
                    // Nút lọc ngày
                    _buildFilterButton(
                      icon: Icons.calendar_today,
                      label: 'Lọc ngày',
                      onPressed: () => _showDateFilterDialog(context),
                    ),
                    const SizedBox(width: 8),
                    // Nút lọc trạng thái
                    _buildFilterButton(
                      icon: Icons.filter_list,
                      label: 'Trạng thái',
                      onPressed: null, // Sẽ dùng PopupMenuButton riêng
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
          const PopupMenuItem(value: 'da_thanh_toan', child: Text('Đã thanh toán')),
          const PopupMenuItem(value: 'da_huy', child: Text('Đã hủy')),
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
    if (uid == null) {
      return const Center(child: Text('Chưa đăng nhập'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lich_su_san')
          .doc(uid)
          .collection('khach_dat')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var orders = snapshot.data?.docs ?? [];

        // Lọc chỉ lấy đơn đã thanh toán hoặc đã hủy
        orders = orders.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final trangThai = data['trang_thai'] as String? ?? '';
          return trangThai == 'da_thanh_toan' || trangThai == 'da_huy';
        }).toList();

        // Lọc theo trạng thái
        if (_filter == 'da_thanh_toan') {
          orders = orders.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['trang_thai'] == 'da_thanh_toan';
          }).toList();
        } else if (_filter == 'da_huy') {
          orders = orders.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['trang_thai'] == 'da_huy';
          }).toList();
        }

        // Lọc theo số điện thoại
        if (_phoneFilter.isNotEmpty) {
          orders = orders.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final sdt = data['sdt'] as String? ?? '';
            return sdt.contains(_phoneFilter);
          }).toList();
        }

        // Lọc theo khoảng ngày
        if (_startDate != null || _endDate != null) {
          orders = orders.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final ngayDatStr = data['ngay_dat'] as String?;
            if (ngayDatStr == null) return false;

            try {
              final parts = ngayDatStr.split('_');
              // Sửa lại thứ tự parse: năm, tháng, ngày
              final ngayDat = DateTime(
                int.parse(parts[2]),  // năm (2025)
                int.parse(parts[1]),  // tháng (11)
                int.parse(parts[0]),  // ngày (29)
              );

              if (_startDate != null && ngayDat.isBefore(_startDate!)) {
                return false;
              }
              if (_endDate != null && ngayDat.isAfter(_endDate!)) {
                return false;
              }
              return true;
            } catch (e) {
              return false;
            }
          }).toList();
        }

        // Sắp xếp theo thời gian
        orders.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          final timeA = dataA['ngay_tao'] as Timestamp?;
          final timeB = dataB['ngay_tao'] as Timestamp?;
          if (timeA == null || timeB == null) return 0;
          return timeB.compareTo(timeA);
        });

        if (orders.isEmpty) {
          return const Center(child: Text('Không có đơn đặt sân'));
        }

        return Column(
          children: [
            // Hiển thị các bộ lọc đang active
            if (_phoneFilter.isNotEmpty || _startDate != null || _endDate != null)
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.grey[100],
                child: Row(
                  children: [
                    const Text('Bộ lọc: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (_phoneFilter.isNotEmpty)
                          Chip(
                            label: Text('SĐT: $_phoneFilter'),
                            onDeleted: () {
                              setState(() {
                                _phoneFilter = '';
                                _phoneController.clear();
                              });
                            },
                          ),
                        if (_startDate != null)
                          Chip(
                            label: Text('Từ: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'),
                            onDeleted: () => setState(() => _startDate = null),
                          ),
                        if (_endDate != null)
                          Chip(
                            label: Text('Đến: ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'),
                            onDeleted: () => setState(() => _endDate = null),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final data = orders[index].data() as Map<String, dynamic>;
                  return _OrderCard(data: data);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// Giữ nguyên các class _OrderCard và _OrderDetailSheet như cũ
class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _OrderCard({required this.data});

  String _fmt(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
  );

  String _fmtDate(String s) {
    try {
      final parts = s.split('_');
      return '${parts[0]}/${parts[1]}/${parts[2]}';
    } catch (e) {
      return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final maDon = data['ma_don'] as String? ?? '';
    final tenKhach = data['ten_nguoi_dat'] as String? ?? '';
    final sdt = data['sdt'] as String? ?? '';
    final ngayDat = _fmtDate(data['ngay_dat'] as String? ?? '');
    final tongTien = (data['tong_tien'] as num?)?.toInt() ?? 0;
    final trangThai = data['trang_thai'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.sports_tennis,
                      color: Color(0xFF2E7D32),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                      ],
                    ),
                  ),
                  _buildStatus(trangThai),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildRow('Mã đơn', '#${maDon.substring(0, 8).toUpperCase()}'),
                    const SizedBox(height: 8),
                    _buildRow('Ngày đặt', ngayDat),
                    const SizedBox(height: 8),
                    _buildRow(
                      'Tổng tiền',
                      '${_fmt(tongTien)}đ',
                      valueColor: const Color(0xFF2E7D32),
                      valueBold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatus(String status) {
    final isCompleted = status == 'da_thanh_toan';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green[50] : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: isCompleted ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            isCompleted ? 'Đã TT' : 'Đã hủy',
            style: TextStyle(
              color: isCompleted ? Colors.green : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? valueColor, bool valueBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: valueColor ?? Colors.black87,
            fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OrderDetailSheet(data: data),
    );
  }
}

class _OrderDetailSheet extends StatefulWidget {
  final Map<String, dynamic> data;

  const _OrderDetailSheet({required this.data});

  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  List<Map<String, dynamic>> chiTiet = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final maDon = widget.data['ma_don'] as String;
      final snapshot = await FirebaseFirestore.instance
          .collection('chi_tiet_dat')
          .doc(maDon)
          .collection('danh_sach')
          .get();

      setState(() {
        chiTiet = snapshot.docs.map((doc) => doc.data()).toList();
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  String _fmt(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
  );

  String _fmtDate(String s) {
    try {
      final parts = s.split('_');
      return '${parts[0]}/${parts[1]}/${parts[2]}';
    } catch (e) {
      return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final maDon = widget.data['ma_don'] as String? ?? '';
    final tenKhach = widget.data['ten_nguoi_dat'] as String? ?? '';
    final sdt = widget.data['sdt'] as String? ?? '';
    final ngayDat = _fmtDate(widget.data['ngay_dat'] as String? ?? '');
    final tongTien = (widget.data['tong_tien'] as num?)?.toInt() ?? 0;
    final trangThai = widget.data['trang_thai'] as String? ?? '';

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.sports_tennis,
                            color: Color(0xFF2E7D32),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tenKhach,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                'SĐT: $sdt',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Divider(color: Colors.grey[300]),
                    const SizedBox(height: 20),
                    const Text(
                      'Thông tin đơn đặt',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    _buildInfo('Mã đơn', '#${maDon.toUpperCase()}'),
                    _buildInfo('Ngày đặt', ngayDat),
                    _buildInfo('Trạng thái', trangThai == 'da_thanh_toan' ? 'Đã thanh toán' : 'Đã hủy'),
                    const SizedBox(height: 24),
                    Divider(color: Colors.grey[300]),
                    const SizedBox(height: 20),
                    const Text(
                      'Chi tiết sân đặt',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    if (loading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (chiTiet.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Không có chi tiết'),
                        ),
                      )
                    else
                      ...chiTiet.map((ct) {
                        final maSan = ct['ma_san'] as String? ?? '';
                        final gio = ct['gio'] as String? ?? '';
                        final gia = (ct['gia'] as num?)?.toInt() ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF2E7D32).withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.sports_tennis,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      maSan.toUpperCase().replaceAll('SAN', 'Sân '),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          gio,
                                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${_fmt(gia)}đ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tổng thanh toán:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_fmt(tongTien)}đ',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}