import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DoanhThuPage extends StatefulWidget {
  const DoanhThuPage({Key? key}) : super(key: key);

  @override
  State<DoanhThuPage> createState() => _DoanhThuPageState();
}

class _DoanhThuPageState extends State<DoanhThuPage> {
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  // Biến lưu dữ liệu
  Map<String, dynamic>? coSoData;
  bool isLoading = true;
  String selectedPeriod = 'today'; // today, week, month, year, custom_month, custom_year
  DateTime? selectedMonth; // Tháng được chọn
  DateTime? selectedYear; // Năm được chọn

  // Dữ liệu thống kê
  int tongDoanhThu = 0;
  int soDonDaThanhToan = 0;
  int soDonDaHuy = 0;
  double tiLeLapDay = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    try {
      final userId = auth.currentUser?.uid;
      if (userId == null) return;

      // Load thông tin cơ sở
      final coSoDoc = await firestore.collection('co_so').doc(userId).get();
      coSoData = coSoDoc.data();

      // Tính toán thống kê
      await _calculateStats(userId);

      setState(() => isLoading = false);
    } catch (e) {
      debugPrint('❌ Lỗi load dữ liệu: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _calculateStats(String coSoId) async {
    try {
      // Xác định khoảng thời gian
      DateTime now = DateTime.now();
      DateTime startDate;
      DateTime endDate = now;

      switch (selectedPeriod) {
        case 'today':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'week':
          startDate = now.subtract(Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'year':
          startDate = DateTime(now.year, 1, 1);
          break;
        case 'custom_month':
          if (selectedMonth != null) {
            startDate = DateTime(selectedMonth!.year, selectedMonth!.month, 1);
            endDate = DateTime(selectedMonth!.year, selectedMonth!.month + 1, 0, 23, 59, 59);
          } else {
            startDate = DateTime(now.year, now.month, 1);
          }
          break;
        case 'custom_year':
          if (selectedYear != null) {
            startDate = DateTime(selectedYear!.year, 1, 1);
            endDate = DateTime(selectedYear!.year, 12, 31, 23, 59, 59);
          } else {
            startDate = DateTime(now.year, 1, 1);
          }
          break;
        default:
          startDate = DateTime(now.year, now.month, now.day);
      }

      // Lấy danh sách đơn đặt
      final snapshot = await firestore
          .collection('lich_su_san')
          .doc(coSoId)
          .collection('khach_dat')
          .where('ngay_tao', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('ngay_tao', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // Reset các biến
      tongDoanhThu = 0;
      soDonDaThanhToan = 0;
      soDonDaHuy = 0;
      int tongSlotDaDat = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final trangThai = data['trang_thai'] ?? '';
        final tongTien = (data['tong_tien'] ?? 0) as int;

        if (trangThai == 'da_thanh_toan') {
          soDonDaThanhToan++;
          tongDoanhThu += tongTien;

          // Đếm số slot trong đơn này
          final chiTietSnapshot = await firestore
              .collection('chi_tiet_dat')
              .doc(doc.id)
              .collection('danh_sach')
              .get();
          tongSlotDaDat += chiTietSnapshot.docs.length;

        } else if (trangThai == 'da_huy') {
          soDonDaHuy++;

          // Đếm số slot đã hủy
          final chiTietSnapshot = await firestore
              .collection('chi_tiet_dat')
              .doc(doc.id)
              .collection('danh_sach')
              .get();
          tongSlotDaDat += chiTietSnapshot.docs.length;
        }
      }

      // Tính tỉ lệ lấp đầy
      if (coSoData != null) {
        final soSan = (coSoData!['so_san'] ?? 4) as int;
        final gioMo = int.tryParse((coSoData!['gio_mo_cua'] as String?)?.split(':')[0] ?? '6') ?? 6;
        final gioDong = int.tryParse((coSoData!['gio_dong_cua'] as String?)?.split(':')[0] ?? '22') ?? 22;
        final soGioMoCua = gioDong - gioMo;

        // Tính số ngày trong khoảng thời gian
        int soNgay = endDate.difference(startDate).inDays + 1;

        // Tổng slot có thể đặt
        int tongSlotCoThe = soSan * soGioMoCua * soNgay;

        // Tỉ lệ lấp đầy
        tiLeLapDay = tongSlotCoThe > 0
            ? (tongSlotDaDat / tongSlotCoThe) * 100
            : 0.0;
      }

      setState(() {});

    } catch (e) {
      debugPrint('❌ Lỗi tính toán thống kê: $e');
    }
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  String _getPeriodLabel() {
    switch (selectedPeriod) {
      case 'today':
        return 'Hôm nay';
      case 'week':
        return '7 ngày qua';
      case 'month':
        return 'Tháng này';
      case 'year':
        return 'Năm nay';
      case 'custom_month':
        if (selectedMonth != null) {
          return 'Tháng ${selectedMonth!.month}/${selectedMonth!.year}';
        }
        return 'Chọn tháng';
      case 'custom_year':
        if (selectedYear != null) {
          return 'Năm ${selectedYear!.year}';
        }
        return 'Chọn năm';
      default:
        return 'Hôm nay';
    }
  }

  // Hàm chọn tháng
  Future<void> _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF2E7D32),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedMonth = picked;
        selectedPeriod = 'custom_month';
      });
      _loadData();
    }
  }

  // Hàm chọn năm
  Future<void> _selectYear() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedYear ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF2E7D32),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedYear = picked;
        selectedPeriod = 'custom_year';
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : RefreshIndicator(
        color: Color(0xFF2E7D32),
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề
              Text(
                'Thống kê doanh thu',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              SizedBox(height: 8),
              Text(
                coSoData?['ten'] ?? 'Cơ sở của bạn',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 20),

              // Chọn khoảng thời gian
              _buildPeriodSelector(),
              SizedBox(height: 12),

              // Nút chọn tháng/năm cụ thể
              Row(
                children: [
                  Expanded(
                    child: _buildCustomButton(
                      label: selectedPeriod == 'custom_month'
                          ? 'Tháng ${selectedMonth?.month ?? "?"}/${selectedMonth?.year ?? "?"}'
                          : 'Chọn tháng',
                      icon: Icons.calendar_month,
                      onTap: _selectMonth,
                      isActive: selectedPeriod == 'custom_month',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildCustomButton(
                      label: selectedPeriod == 'custom_year'
                          ? 'Năm ${selectedYear?.year ?? "?"}'
                          : 'Chọn năm',
                      icon: Icons.calendar_today,
                      onTap: _selectYear,
                      isActive: selectedPeriod == 'custom_year',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Các card thống kê
              _buildStatCard(
                title: 'Tổng doanh thu',
                value: '${_formatCurrency(tongDoanhThu)}đ',
                icon: Icons.attach_money,
                color: Color(0xFF2E7D32),
              ),
              SizedBox(height: 12),

              _buildStatCard(
                title: 'Tỉ lệ lấp đầy',
                value: '${tiLeLapDay.toStringAsFixed(1)}%',
                icon: Icons.trending_up,
                color: Color(0xFF1976D2),
              ),
              SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Đã thanh toán',
                      value: '$soDonDaThanhToan',
                      icon: Icons.check_circle,
                      color: Color(0xFF388E3C),
                      compact: true,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Đã hủy',
                      value: '$soDonDaHuy',
                      icon: Icons.cancel,
                      color: Color(0xFFD32F2F),
                      compact: true,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Ghi chú
              _buildNoteSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? Color(0xFF2E7D32) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Color(0xFF2E7D32) : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Color(0xFF2E7D32),
              size: 20,
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey[700],
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildPeriodButton('today', 'Hôm nay'),
          _buildPeriodButton('week', '7 ngày'),
          _buildPeriodButton('month', 'Tháng'),
          _buildPeriodButton('year', 'Năm'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String period, String label) {
    final isSelected = selectedPeriod == period;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => selectedPeriod = period);
          _loadData();
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFF2E7D32) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(compact ? 8 : 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: compact ? 20 : 24),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: compact ? 13 : 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 12),
          Text(
            value,
            style: TextStyle(
              fontSize: compact ? 20 : 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2E7D32).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFF2E7D32).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline,
                  color: Color(0xFF2E7D32),
                  size: 20),
              SizedBox(width: 8),
              Text(
                'Ghi chú',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• Tỉ lệ lấp đầy = (Tổng slot đã đặt ÷ Tổng slot có thể) × 100%\n'
                '• Chỉ tính các đơn đã thanh toán và đã hủy\n'
                '• Kéo xuống để làm mới dữ liệu',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}