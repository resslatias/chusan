import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DanhGiaPage extends StatefulWidget {
  const DanhGiaPage({super.key});

  @override
  State<DanhGiaPage> createState() => _DanhGiaPageState();
}

class _DanhGiaPageState extends State<DanhGiaPage> {
  String? _coSoId;
  bool _isLoadingCoSo = true;
  Map<String, dynamic>? _coSoData;
  int _selectedStarFilter = 0; // 0 = Tất cả, 1-5 = theo sao

  @override
  void initState() {
    super.initState();
    _loadCoSoInfo();
  }

  Future<void> _loadCoSoInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoadingCoSo = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('co_so')
          .doc(user.uid)
          .get();

      if (mounted && doc.exists) {
        setState(() {
          _coSoId = user.uid;
          _coSoData = doc.data();
          _isLoadingCoSo = false;
        });
      } else {
        setState(() => _isLoadingCoSo = false);
      }
    } catch (e) {
      debugPrint('❌ Lỗi load cơ sở: $e');
      setState(() => _isLoadingCoSo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: null, // Xóa AppBar
      body: Column(
        children: [
          // Header mới
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
            child: const Row(
              children: [
                BackButton(), // Nút quay lại
                SizedBox(width: 8),
                Text(
                  'Đánh giá của khách hàng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),

          // Body content
          Expanded(
            child: _isLoadingCoSo
                ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2E7D32),
              ),
            )
                : _coSoId == null
                ? _buildEmptyState()
                : _buildReviewsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.store_outlined,
                size: 64,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chưa có thông tin cơ sở',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vui lòng thiết lập thông tin cơ sở trước',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF7F8C8D),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('danh_gia')
          .doc(_coSoId)
          .collection('reviews')
          .orderBy('createAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState('Lỗi: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF2E7D32),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildNoReviewsState();
        }

        final allReviews = snapshot.data!.docs;
        final filteredReviews = _selectedStarFilter == 0
            ? allReviews
            : allReviews.where((doc) {
          final review = doc.data() as Map<String, dynamic>;
          final stars = (review['so_sao'] as num?)?.toInt() ?? 0;
          return stars == _selectedStarFilter;
        }).toList();

        final starCounts = _calculateStarCounts(allReviews);

        return Column(
          children: [
            // Bộ lọc theo sao
            _buildStarFilter(starCounts, allReviews.length),

            // Thống kê đơn giản
            _buildSimpleStats(filteredReviews.length),

            // Danh sách đánh giá
            Expanded(
              child: filteredReviews.isEmpty
                  ? _buildNoFilteredReviewsState()
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: filteredReviews.length,
                itemBuilder: (context, index) {
                  final doc = filteredReviews[index];
                  final review = doc.data() as Map<String, dynamic>;
                  return _buildReviewCard(review); // Chỉ truyền review, không truyền reviewId
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Map<int, int> _calculateStarCounts(List<QueryDocumentSnapshot> reviews) {
    Map<int, int> starCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    for (var doc in reviews) {
      final data = doc.data() as Map<String, dynamic>;
      final stars = (data['so_sao'] as num?)?.toInt() ?? 0;
      if (stars >= 1 && stars <= 5) {
        starCounts[stars] = (starCounts[stars] ?? 0) + 1;
      }
    }

    return starCounts;
  }

  Widget _buildStarFilter(Map<int, int> starCounts, int totalReviews) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lọc theo số sao:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Nút "Tất cả"
                _buildFilterChip(
                  label: 'Tất cả',
                  count: totalReviews,
                  isSelected: _selectedStarFilter == 0,
                  onTap: () => setState(() => _selectedStarFilter = 0),
                ),

                // Các nút sao từ 5 đến 1
                ...List.generate(5, (index) {
                  final star = 5 - index;
                  final count = starCounts[star] ?? 0;
                  return _buildFilterChip(
                    label: '$star sao',
                    count: count,
                    isSelected: _selectedStarFilter == star,
                    onTap: () => setState(() => _selectedStarFilter = star),
                    showStars: true,
                    starCount: star,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    bool showStars = false,
    int starCount = 0,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFBDC3C7),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showStars)
                  Row(
                    children: List.generate(starCount, (i) {
                      return const Icon(
                        Icons.star,
                        size: 14,
                        color: Colors.amber,
                      );
                    }),
                  ),
                if (showStars) const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : const Color(0xFFECF0F1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFF7F8C8D),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleStats(int count) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.comment_outlined,
            size: 16,
            color: Color(0xFF2E7D32),
          ),
          const SizedBox(width: 8),
          Text(
            'Hiển thị $count đánh giá',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFilteredReviewsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_outlined,
                size: 64,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _selectedStarFilter == 0
                  ? 'Chưa có đánh giá nào'
                  : 'Không có đánh giá $_selectedStarFilter sao',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedStarFilter == 0
                  ? 'Các đánh giá từ khách hàng sẽ hiển thị tại đây'
                  : 'Không tìm thấy đánh giá nào với $_selectedStarFilter sao',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF7F8C8D),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoReviewsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.comment_outlined,
                size: 64,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chưa có đánh giá nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Các đánh giá từ khách hàng sẽ hiển thị tại đây',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF7F8C8D),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFFC44536),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF7F8C8D),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Sửa hàm _buildReviewCard - chỉ hiển thị, không có chức năng xóa
  Widget _buildReviewCard(Map<String, dynamic> review) {
    final nguoiDanhGia = review['nguoi_danh_gia'] as String? ?? 'Ẩn danh';
    final noiDung = review['noi_dung'] as String? ?? '';
    final soSao = (review['so_sao'] as num?)?.toInt() ?? 0;
    final createAt = review['createAt'] as Timestamp?;
    final maNguoiDanhGia = review['ma_nguoi_danh_gia'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECF0F1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar + Tên + Sao + Thời gian
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 24,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 12),

                // Thông tin người đánh giá
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nguoiDanhGia,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Sao đánh giá
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                i < soSao ? Icons.star : Icons.star_border,
                                size: 16,
                                color: Colors.amber,
                              );
                            }),
                          ),
                          const SizedBox(width: 8),
                          // Thời gian
                          if (createAt != null)
                            Text(
                              _formatDateTime(createAt.toDate()),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF7F8C8D),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Nội dung đánh giá
            if (noiDung.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  noiDung,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
            ],

            // Mã người đánh giá (hiển thị nhỏ ở cuối)
            if (maNguoiDanhGia.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'ID: ${maNguoiDanhGia.substring(0, 8)}...',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFBDC3C7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Vừa xong';
        }
        return '${difference.inMinutes} phút trước';
      }
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}