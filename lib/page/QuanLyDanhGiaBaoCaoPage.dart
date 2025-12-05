import 'package:chusan/page/subpage_in_khac/CreateReportChuSanPage.dart';
import 'package:chusan/page/subpage_in_khac/DanhGiaPage.dart';
import 'package:flutter/material.dart';

class QuanLyDanhGiaBaoCaoPage extends StatelessWidget {
  const QuanLyDanhGiaBaoCaoPage({super.key});

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
                  "Khác",
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
                  // NHÓM: QUẢN LÝ ĐÁNH GIÁ
                  // ---------------------------
                  const Text(
                    "Quản lý đánh giá",
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Nút Xem đánh giá
                  _buildButton(
                    context,
                    Icons.star_rate,
                    "Xem đánh giá",
                    onTap: () {
                      // Điều hướng đến trang Xem đánh giá
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DanhGiaPage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // ---------------------------
                  // NHÓM: BÁO CÁO
                  // ---------------------------
                  const Text(
                    "Báo cáo",
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Nút Tạo báo cáo
                  _buildButton(
                    context,
                    Icons.assessment,
                    "Tạo báo cáo",
                    onTap: () {
                      // Điều hướng đến trang Tạo báo cáo
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateReportChuSanPage(),
                        ),
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
      String label, {
        VoidCallback? onTap,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
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
