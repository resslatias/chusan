
import 'package:chusan/page/subpage_in_co_so/ChinhSuaDiaChiPage.dart';
import 'package:chusan/page/subpage_in_co_so/ChinhSuaGioVaGiaPage.dart';
import 'package:chusan/page/subpage_in_co_so/ChinhSuaNhomKhacPage.dart';
import 'package:chusan/page/subpage_in_co_so/ChinhSuaThongTinCoBanPage.dart';
import 'package:chusan/page/subpage_in_co_so/PaymentConfigPage.dart';
import 'package:chusan/page/subpage_in_co_so/TrangThaiSanPage.dart';
import 'package:chusan/page/subpage_in_co_so/setdichvu.dart';
import 'package:chusan/page/subpage_in_co_so/setomage.dart';
import 'package:flutter/material.dart';
// Import trang mới

class CoSoPage extends StatelessWidget {
  const CoSoPage({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // ============================
          // HEADER
          // ============================
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
            child: const Row(
              children: [
                Text(
                  "Chỉnh sửa thông tin sân bãi",
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                )
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
                  // ---------------------------
                  // NHÓM 1: CHỈNH SỬA CƠ BẢN
                  // ---------------------------
                  const Text(
                    "Chỉnh sửa cơ bản",
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Kết nối đến trang ChinhSuaAnhPage
                  _buildButton(
                    context,
                    Icons.image,
                    "Chỉnh sửa ảnh",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChinhSuaAnhPage()),
                      );
                    },
                  ),

                  _buildButton(
                    context,
                    Icons.home_repair_service,
                    "Chỉnh sửa tiện ích",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChinhSuaDichVuPage()),
                      );
                    },
                  ),

                  _buildButton(
                    context,
                    Icons.info_outline,
                    "Chỉnh sửa thông tin cơ bản",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChinhSuaThongTinCoBanPage()),
                      );
                    },
                  ),
                  _buildButton(
                    context,
                    Icons.group_outlined,
                    "Chỉnh sửa nhóm sé vé",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChinhSuaNhomKhacPage()),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // ---------------------------
                  // NHÓM 2: CHỈNH SỬA NÂNG CAO
                  // ---------------------------
                  const Text(
                    "Chỉnh sửa nâng cao",
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildButton(
                    context,
                    Icons.access_time,
                    "Giờ mở cửa + giá sân",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChinhSuaGioVaGiaPage()),
                      );
                    },
                  ),

                  _buildButton(
                    context,
                    Icons.location_on_outlined,
                    "Chỉnh sửa tên + địa chỉ sân",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChinhSuaDiaChiPage()),
                      );
                    },
                  ),
                  _buildButton(
                    context,
                    Icons.payments_outlined,
                    "Cấu hình thanh toán",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CauHinhThanhToanPage()),
                      );
                    },
                  ),

                  _buildButton(
                    context,
                    Icons.visibility_outlined,
                    "Bật / tắt hiển thị sân",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TrangThaiSanPage()),
                      );
                    },
                  ),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================
  // WIDGET BUTTON DÙNG CHUNG
  // ================================================
  Widget _buildButton(
      BuildContext context,
      IconData icon,
      String label,
      {VoidCallback? onTap}
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap ?? () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DummyPage(title: label)),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF2E7D32)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}


// ==========================================================================
// Dummy Page – Trang tạm để bạn sau này thay bằng các trang thật
// ==========================================================================
class DummyPage extends StatelessWidget {
  final String title;
  const DummyPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2E7D32);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: Text(title, style: const TextStyle(color: primaryColor)),
        iconTheme: const IconThemeData(color: primaryColor),
      ),
      body: Center(
        child: Text(
          "Trang: $title\n(Bạn sẽ bổ sung nội dung sau)",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ),
    );
  }
}