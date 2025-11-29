import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MoKhoaSanPage extends StatefulWidget {
  const MoKhoaSanPage({Key? key}) : super(key: key);

  @override
  State<MoKhoaSanPage> createState() => _MoKhoaSanPageState();
}

class _MoKhoaSanPageState extends State<MoKhoaSanPage> {
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  String? userId;

  DateTime selectedDate = DateTime.now();
  List<int> hours = [];
  int soSan = 4;
  bool isLoading = true;
  List<Map<String, dynamic>> lockedCourts = [];

  String formatDate(DateTime date) => DateFormat('dd_MM_yyyy').format(date);
  String displayDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  @override
  void initState() {
    super.initState();
    _loadUserId().then((_) {
      _initializeData();
    });
  }

  Future<void> _loadUserId() async {
    User? currentUser = auth.currentUser;
    if (currentUser != null) {
      setState(() {
        userId = currentUser.uid;
      });
      debugPrint("✅ Loaded userId: $userId");
    } else {
      debugPrint("❌ Chưa đăng nhập");
    }
  }

  Future<void> _initializeData() async {
    if (userId == null) return;

    setState(() => isLoading = true);

    try {
      // Đọc thông tin cơ sở
      final coSoDoc = await firestore.collection('co_so').doc(userId).get();

      if (!coSoDoc.exists) {
        _showSnackBar('Không tìm thấy thông tin cơ sở', Color(0xFFC44536));
        setState(() => isLoading = false);
        return;
      }

      final coSoData = coSoDoc.data()!;

      // Lấy số sân
      soSan = (coSoData['so_san'] as num?)?.toInt() ?? 4;

      // Lấy giờ mở - đóng cửa
      final gioMo = int.tryParse((coSoData['gio_mo_cua'] as String?)?.split(':')[0] ?? '6') ?? 6;
      final gioDong = int.tryParse((coSoData['gio_dong_cua'] as String?)?.split(':')[0] ?? '22') ?? 22;

      hours = List.generate(gioDong - gioMo, (i) => gioMo + i);

      await _loadLockedCourts();

      setState(() => isLoading = false);

      debugPrint("✅ Đã load: $soSan sân, giờ $gioMo-$gioDong");
    } catch (e) {
      debugPrint("🔥 Lỗi _initializeData: $e");
      _showSnackBar('Lỗi tải dữ liệu: $e', Color(0xFFC44536));
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadLockedCourts() async {
    if (userId == null) return;

    lockedCourts.clear();

    String dayPath = formatDate(selectedDate);

    try {
      final snapshot = await firestore
          .collection("dat_san")
          .doc(userId)
          .collection(dayPath)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final hourStr = doc.id; // "06:00", "07:00"...
        final hour = int.parse(hourStr.split(':')[0]);

        for (int i = 1; i <= soSan; i++) {
          String sanKey = 'san$i';
          int status = data[sanKey] ?? 1;
          String? name = data['${sanKey}_name'] as String?;

          // Chỉ lấy sân có trạng thái 3 VÀ name = 'chu_san'
          if (status == 3 && name == 'chu_san') {
            lockedCourts.add({
              'hour': hour,
              'san': i,
              'sanKey': sanKey,
              'hourPath': hourStr,
              'docRef': doc.reference,
            });
          }
        }
      }

      // Sắp xếp theo giờ và sân
      lockedCourts.sort((a, b) {
        int hourCompare = (a['hour'] as int).compareTo(b['hour'] as int);
        if (hourCompare != 0) return hourCompare;
        return (a['san'] as int).compareTo(b['san'] as int);
      });

      debugPrint("✅ Tìm thấy ${lockedCourts.length} sân đã khóa bởi chủ sân");

      setState(() {});
    } catch (e) {
      debugPrint("🔥 Lỗi _loadLockedCourts: $e");
      _showSnackBar('Lỗi tải dữ liệu: $e', Color(0xFFC44536));
    }
  }

  Future<void> _unlockCourt(Map<String, dynamic> court) async {
    final hour = court['hour'] as int;
    final san = court['san'] as int;
    final sanKey = court['sanKey'] as String;

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.lock_open, color: Color(0xFF2E8B57)),
            const SizedBox(width: 8),
            const Text("Xác nhận mở khóa"),
          ],
        ),
        content: Text(
          "Bạn có chắc muốn mở khóa Sân $san lúc $hour-${hour + 1}h không?",
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2E8B57),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Mở khóa",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final docRef = court['docRef'] as DocumentReference;

        await docRef.update({
          sanKey: 1,
          '${sanKey}_name': FieldValue.delete(),
        });

        debugPrint("✅ Đã mở khóa $sanKey");

        _showSnackBar(
          'Đã mở khóa Sân $san lúc $hour-${hour + 1}h',
          Color(0xFF2E8B57),
        );

        // Reload danh sách
        await _loadLockedCourts();
      } catch (e) {
        debugPrint("🔥 Lỗi mở khóa: $e");
        _showSnackBar('Lỗi mở khóa: $e', Color(0xFFC44536));
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Scaffold(
        body: Center(child: Text("Đang tải user...")),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFECF0F1),
      body: Column(
        children: [
          _buildCustomAppBar(),
          _buildDateSelector(),
          Expanded(
            child: isLoading
                ? Center(
              child: CircularProgressIndicator(color: Color(0xFFC44536)),
            )
                : lockedCourts.isEmpty
                ? _buildEmptyState()
                : _buildLockedCourtsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Color(0xFF2C3E50), size: 20),
              padding: EdgeInsets.all(6),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              "Mở khóa sân",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: InkWell(
        onTap: () async {
          DateTime today = DateTime.now();
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: selectedDate,
            firstDate: DateTime(today.year, today.month, today.day),
            lastDate: DateTime(2030),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: Color(0xFFC44536),
                  ),
                ),
                child: child!,
              );
            },
          );

          if (picked != null && picked != selectedDate) {
            setState(() {
              selectedDate = picked;
              isLoading = true;
            });
            await _loadLockedCourts();
            setState(() => isLoading = false);
            _showSnackBar(
              'Đã chuyển sang ngày ${displayDate(picked)}',
              Color(0xFF3498DB),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(0xFFBDC3C7)),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: Color(0xFFC44536), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayDate(selectedDate),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.arrow_drop_down, color: Color(0xFFC44536)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_open,
            size: 80,
            color: Color(0xFFBDC3C7),
          ),
          const SizedBox(height: 16),
          Text(
            'Không có sân nào bị khóa',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7F8C8D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chọn ngày khác để xem',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFBDC3C7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedCourtsList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header thống kê
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFC44536).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lock,
                    color: Color(0xFFC44536),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tổng số sân bị khóa',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF7F8C8D),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${lockedCourts.length} sân',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC44536),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Danh sách sân
          Expanded(
            child: ListView.builder(
              itemCount: lockedCourts.length,
              itemBuilder: (context, index) {
                return _buildCourtCard(lockedCourts[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourtCard(Map<String, dynamic> court) {
    final hour = court['hour'] as int;
    final san = court['san'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon sân
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color(0xFFC44536).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.sports_tennis,
                color: Color(0xFFC44536),
                size: 24,
              ),
            ),

            const SizedBox(width: 16),

            // Thông tin sân
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sân $san',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Color(0xFF7F8C8D),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$hour:00 - ${hour + 1}:00',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7F8C8D),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Nút mở khóa
            ElevatedButton.icon(
              onPressed: () => _unlockCourt(court),
              icon: Icon(Icons.lock_open, size: 16),
              label: Text('Mở khóa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2E8B57),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}