import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class TrangThaiSan extends StatefulWidget {
  const TrangThaiSan({Key? key}) : super(key: key);

  @override
  State<TrangThaiSan> createState() => _TrangThaiSanState();
}

class _TrangThaiSanState extends State<TrangThaiSan> with WidgetsBindingObserver {
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  String? userId;

  DateTime selectedDate = DateTime.now();
  List<int> hours = [];
  int soSan = 4;
  Map<int, List<int>> states = {};
  List<Map<String, dynamic>> pendingChanges = [];
  StreamSubscription<QuerySnapshot>? subscription;
  bool isLoading = true;

  String formatDate(DateTime date) => DateFormat('dd_MM_yyyy').format(date);
  String displayDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  bool isPastHour(int hour) {
    final now = DateTime.now();
    if (selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day) {
      return hour <= now.hour;
    }
    return false;
  }

  String getHourLabel(int hour) {
    int nextHour = hour + 1;
    return "$hour-${nextHour}h";
  }

  Color getStatusColor(int status) {
    switch (status) {
      case 2:
        return Color(0xFFF39C12); // Orange
      case 3:
        return Color(0xFFC44536); // Red
      default:
        return Color(0xFF2E8B57); // Green
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserId().then((_) {
      _initializeData();
    });
    WidgetsBinding.instance.addObserver(this);
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

      await ensureDayDataExists(formatDate(selectedDate));
      setupListeners();

      setState(() => isLoading = false);

      debugPrint("✅ Đã load: $soSan sân, giờ $gioMo-$gioDong");
    } catch (e) {
      debugPrint("🔥 Lỗi _initializeData: $e");
      _showSnackBar('Lỗi tải dữ liệu: $e', Color(0xFFC44536));
      setState(() => isLoading = false);
    }
  }

  Future<void> ensureDayDataExists(String datePath) async {
    if (userId == null) return;

    final dateRef = firestore
        .collection("dat_san")
        .doc(userId)
        .collection(datePath);

    try {
      final snapshot = await dateRef.limit(1).get();

      if (snapshot.docs.isEmpty) {
        WriteBatch batch = firestore.batch();
        for (int hour in hours) {
          final ref = dateRef.doc("${hour.toString().padLeft(2, '0')}:00");
          Map<String, dynamic> data = {};
          for (int i = 1; i <= soSan; i++) {
            data['san$i'] = 1;
          }
          batch.set(ref, data);
        }
        await batch.commit();
        debugPrint("✅ Đã tạo dữ liệu cho ngày $datePath");
      }
    } catch (e) {
      debugPrint("🔥 Lỗi ensureDayDataExists: $e");
    }
  }

  void setupListeners() {
    if (userId == null) return;

    subscription?.cancel();

    String dayPath = formatDate(selectedDate);

    subscription = firestore
        .collection("dat_san")
        .doc(userId)
        .collection(dayPath)
        .snapshots()
        .listen((snapshot) {
      states.clear();
      for (var doc in snapshot.docs) {
        int hh = int.parse(doc.id.split(':')[0]);
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        List<int> sanStates = [];
        for (int i = 1; i <= soSan; i++) {
          sanStates.add(data['san$i'] ?? 1);
        }
        states[hh] = sanStates;
      }
      if (mounted) setState(() {});
    }, onError: (e) {
      debugPrint("🔥 Lỗi listener: $e");
    });
  }

  Future<void> datSan(int hour, int index) async {
    if (userId == null) return;

    String datePath = formatDate(selectedDate);
    String hourPath = "${hour.toString().padLeft(2, '0')}:00";
    String sanKey = "san${index + 1}";

    final ref = firestore
        .collection("dat_san")
        .doc(userId)
        .collection(datePath)
        .doc(hourPath);

    try {
      final docSnapshot = await ref.get();
      Map<String, dynamic> data = docSnapshot.data() ?? {};
      int current = data[sanKey] ?? 1;

      // Toggle trạng thái: 1 -> 2, 2 -> 1, 3 -> không làm gì
      if (current == 3) {
        _showSnackBar('Sân này đã được khóa', Color(0xFFC44536));
        return;
      }

      if (current == 2) {
        // Kiểm tra xem có phải sân mình đang chọn không
        bool isMyPending = pendingChanges.any(
                (p) => p['hour'] == hour && p['san'] == index
        );

        if (isMyPending) {
          // Bỏ chọn: 2 -> 1
          await ref.update({sanKey: 1});
          pendingChanges.removeWhere(
                  (p) => p['hour'] == hour && p['san'] == index
          );
          debugPrint("✅ Bỏ chọn $sanKey");
        } else {
          _showSnackBar('Sân này đang được chọn', Color(0xFFF39C12));
          return;
        }
      } else if (current == 1) {
        // Chọn: 1 -> 2
        await ref.update({sanKey: 2});

        pendingChanges.add({
          'hour': hour,
          'san': index,
          'ref': ref,
          'sanKey': sanKey,
        });

        debugPrint("✅ Đã chọn $sanKey");
      }

      setState(() {});
    } catch (e) {
      debugPrint("🔥 Lỗi datSan: $e");
      _showSnackBar("Lỗi đặt sân: $e", Color(0xFFC44536));
    }
  }

  Future<void> rollbackPending() async {
    if (pendingChanges.isEmpty) return;

    debugPrint("🔄 Đang rollback ${pendingChanges.length} sân đang chọn...");

    for (var p in pendingChanges) {
      String sanKey = p['sanKey'];

      try {
        await (p['ref'] as DocumentReference).update({
          sanKey: 1,
        });
        debugPrint("✅ Đã rollback $sanKey: 2→1");
      } catch (e) {
        debugPrint("❌ Lỗi rollback $sanKey: $e");
      }
    }

    pendingChanges.clear();
    debugPrint("✅ Rollback hoàn tất");
  }

  Future<void> confirmAll() async {
    if (pendingChanges.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text("Chưa chọn sân"),
          content: const Text("Vui lòng chọn ít nhất một sân trước khi xác nhận."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );
      return;
    }

    String dateStr = displayDate(selectedDate);
    String selectedInfo = pendingChanges
        .map((p) => "Sân ${p['san'] + 1} lúc ${p['hour']}-${p['hour'] + 1}h")
        .join("\n");

    bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: EdgeInsets.symmetric(horizontal: 16),
        titlePadding: EdgeInsets.zero,
        contentPadding: EdgeInsets.all(16),

        title: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFFC44536),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.block, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                "Xác nhận khóa sân tại khung giờ này",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),

        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFC44536).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFFC44536).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Ngày: $dateStr",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const Divider(),
                    Text(
                      "Danh sách khóa:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC44536),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(selectedInfo, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFC44536),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Xác nhận", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Cập nhật trạng thái sân lên 3 và lưu tên chủ sân
        for (var p in pendingChanges) {
          String sanKey = p['sanKey'];
          await (p['ref'] as DocumentReference).update({
            sanKey: 3,
            '${sanKey}_name': 'chu_san',
          });
          debugPrint("✅ Đã khóa $sanKey");
        }

        _showSnackBar('Đã khóa ${pendingChanges.length} sân thành công', Color(0xFF2E8B57));
      } catch (e) {
        debugPrint("🔥 Lỗi confirm: $e");
        _showSnackBar("Lỗi xác nhận: $e", Color(0xFFC44536));
      }
    } else {
      await rollbackPending();
    }

    pendingChanges.clear();
    setState(() {});
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

  Future<void> _handleBackPressed() async {
    if (pendingChanges.isNotEmpty) {
      bool? shouldBack = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text("Hủy chọn sân?"),
          content: Text(
            "Bạn có ${pendingChanges.length} sân đang chọn. Bạn có muốn hủy và thoát không?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Ở lại"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFFC44536),
              ),
              child: const Text("Hủy và thoát"),
            ),
          ],
        ),
      );

      if (shouldBack == true) {
        await rollbackPending();
        _showSnackBar('Đã hủy ${pendingChanges.length} sân đang chọn', Color(0xFFF39C12));
      } else {
        return;
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      if (pendingChanges.isNotEmpty) {
        debugPrint("🔄 App background - tự động rollback trạng thái 2");
        rollbackPending();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    subscription?.cancel();

    if (pendingChanges.isNotEmpty) {
      debugPrint("🔄 Dispose - tự động rollback trạng thái 2");
      rollbackPending();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Scaffold(
        body: Center(child: Text("Đang tải user...")),
      );
    }

    if (isLoading) {
      return Scaffold(
        body: Column(
          children: [
            _buildCustomAppBar(),
            Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFC44536)),
              ),
            ),
          ],
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        await _handleBackPressed();
        return true;
      },
      child: Scaffold(
        backgroundColor: Color(0xFFECF0F1),
        body: Column(
          children: [
            _buildCustomAppBar(),
            _buildDateSelector(),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildLegend(),
                    const SizedBox(height: 8),
                    Expanded(child: _buildCourtTable()),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
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
              onPressed: () => _handleBackPressed().then((_) {
                if (pendingChanges.isEmpty) Navigator.pop(context);
              }),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              "Trạng thái sân - Chủ sân",
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
            await rollbackPending();
            setState(() {
              selectedDate = picked;
              states = {};
              pendingChanges.clear();
              isLoading = true;
            });
            await ensureDayDataExists(formatDate(picked));
            setupListeners();
            setState(() => isLoading = false);
            _showSnackBar('Đã chuyển sang ngày ${displayDate(picked)}. Hãy chọn lại sân.', Color(0xFF3498DB));
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

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _LegendItem(color: Color(0xFF2E8B57), text: "Trống"),
          _LegendItem(color: Color(0xFFF39C12), text: "Đang chọn"),
          _LegendItem(color: Color(0xFFC44536), text: "Đã khóa"),
        ],
      ),
    );
  }

  Widget _buildCourtTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF2C3E50),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  _buildHeaderCell("Thời gian", flex: 2),
                  for (int i = 1; i <= soSan; i++)
                    _buildHeaderCell("Sân $i", flex: 2),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: hours.map((hour) {
                    bool past = isPastHour(hour);
                    List<int> sanStates = states[hour] ?? List.filled(soSan, 1);

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Color(0xFFECF0F1)),
                      ),
                      child: Row(
                        children: [
                          _buildHourCell(hour),
                          for (int i = 0; i < soSan; i++)
                            Expanded(
                              flex: 2,
                              child: GestureDetector(
                                onTap: past ? null : () => datSan(hour, i),
                                child: Container(
                                  height: 48,
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: past
                                        ? Colors.grey.shade300
                                        : getStatusColor(sanStates[i]),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: past
                                          ? Colors.grey.shade400
                                          : getStatusColor(sanStates[i]).withOpacity(0.3),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: past
                                      ? Icon(Icons.block, color: Colors.white70, size: 16)
                                      : Text(
                                    sanStates[i] == 3
                                        ? '✓'
                                        : sanStates[i].toString(),
                                    style: TextStyle(
                                      color: sanStates[i] == 3
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: sanStates[i] == 3 ? 18 : 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeaderCell(String title, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildHourCell(int hour) {
    return Expanded(
      flex: 2,
      child: Container(
        padding: const EdgeInsets.all(8),
        alignment: Alignment.center,
        child: Text(
          getHourLabel(hour),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF2C3E50),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFECF0F1)),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pendingChanges.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Color(0xFFC44536).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFFC44536).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đã chọn: ${pendingChanges.length} sân',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await rollbackPending();
                        setState(() {});
                        _showSnackBar('Đã hủy chọn', Color(0xFF7F8C8D));
                      },
                      icon: Icon(Icons.clear, size: 16),
                      label: Text('Hủy chọn', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: Color(0xFFC44536),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: confirmAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFC44536),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  pendingChanges.isEmpty ? 'Chọn sân để khóa' : 'Xác nhận khóa sân',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade400),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}