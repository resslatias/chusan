// =============================================
// APP CHỦ SÂN CẦU LÔNG - MAIN.DART
// Màu chủ đạo: XANH (đối lập với đỏ của app người dùng)
// =============================================

import 'dart:async';
import 'package:chusan/page/DanhGiaPage.dart';
import 'package:chusan/page/DoanhThuPage.dart';
import 'package:chusan/page/DonDatPage.dart';
import 'package:chusan/page/HoanTienPage.dart';
import 'package:chusan/page/KhoaSanPage.dart';
import 'package:chusan/page/co_so.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login/AuthService.dart';
import 'login/CreateCoSoPage.dart';
import 'login/LoginPage.dart';
import 'netw/app_navigator.dart';
import 'netw/network_service.dart';

// Import các trang con


// Enum các tab chính
enum TabItem { doanhThu, donDat, thongTin, datSan, hoanTien, danhGia }

// =============================================
// MAIN - Khởi tạo Firebase & Check Auth
// =============================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hiển thị splash
  runApp(const SplashApp());

  // Init Firebase
  await Firebase.initializeApp();

  // Chuyển sang app chính
  runApp(const ChuSanApp());
}

// =============================================
// SPLASH SCREEN - Màu xanh
// =============================================
class SplashApp extends StatelessWidget {
  const SplashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF2E7D32), // Xanh lá đậm
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.store,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'KL10 - Quản Lý Sân',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Dành cho Chủ Sân',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================
// MAIN APP - Theme xanh
// =============================================
class ChuSanApp extends StatelessWidget {
  const ChuSanApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2E7D32); // Xanh lá đậm
    const secondaryColor = Color(0xFF66BB6A); // Xanh lá nhạt

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: AppNavigator.key,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: secondaryColor,
          background: const Color(0xFFF5F5F5),
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 3,
          iconTheme: IconThemeData(color: Color(0xFF2E7D32)),
          titleTextStyle: TextStyle(
            color: Color(0xFF2E7D32),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF2E7D32),
          unselectedItemColor: Color(0xFF757575),
        ),
      ),
      home: const AuthChecker(),
      routes: {
        '/login': (_) => const LoginPage(),
      },
    );
  }
}

// =============================================
// AUTH CHECKER - Kiểm tra đăng nhập & quyền chủ sân
// =============================================
class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  bool _isChecking = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthAndPermission();
  }

  Future<void> _checkAuthAndPermission() async {
    try {
      // Đợi auth state đầu tiên
      final user = await FirebaseAuth.instance.authStateChanges().first;

      if (user == null) {
        // Chưa đăng nhập -> chuyển login
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      // Đã đăng nhập -> kiểm tra quyền chủ sân
      final isOwner = await _checkIsOwner(user.uid);

      if (!isOwner) {
        // Không phải chủ sân
        setState(() {
          _errorMessage = 'Tài khoản này không có quyền truy cập.\nVui lòng liên hệ quản trị viên.';
          _isChecking = false;
        });

        // Đăng xuất sau 3 giây
        await Future.delayed(Duration(seconds: 3));
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      // Kiểm tra dữ liệu cơ sở
      final hasCoSo = await _checkCoSoData(user.uid);

      if (mounted) {
        setState(() => _isChecking = false);

        if (hasCoSo) {
          // Có cơ sở -> vào app chính
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const Shell()),
          );
        } else {
          // Chưa có cơ sở -> vào trang tạo cơ sở
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const CreateCoSoPage()),
          );
        }
      }

    } catch (e) {
      debugPrint('❌ Lỗi kiểm tra auth: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Có lỗi xảy ra. Vui lòng thử lại.';
          _isChecking = false;
        });
      }
    }
  }

  // Kiểm tra tài khoản có trong check_chu_san không
  Future<bool> _checkIsOwner(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('check_chu_san')
          .doc(uid)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('❌ Lỗi kiểm tra quyền: $e');
      return false;
    }
  }

  // Kiểm tra có dữ liệu trong co_so chưa
  Future<bool> _checkCoSoData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('co_so')
          .doc(uid)
          .get();
      return doc.exists && doc.data() != null;
    } catch (e) {
      debugPrint('❌ Lỗi kiểm tra cơ sở: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _errorMessage != null ? Icons.error_outline : Icons.store,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 24),
            if (_isChecking) ...[
              Text(
                'Đang kiểm tra...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ] else if (_errorMessage != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================
// SHELL - Main navigation
// =============================================
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  TabItem _current = TabItem.doanhThu;

  final _navKeys = <TabItem, GlobalKey<NavigatorState>>{
    TabItem.doanhThu: GlobalKey<NavigatorState>(),
    TabItem.donDat: GlobalKey<NavigatorState>(),
    TabItem.thongTin: GlobalKey<NavigatorState>(),
    TabItem.datSan: GlobalKey<NavigatorState>(),
    TabItem.hoanTien: GlobalKey<NavigatorState>(),
    TabItem.danhGia: GlobalKey<NavigatorState>(),
  };

  StreamSubscription<bool>? _netSub;

  @override
  void initState() {
    super.initState();
    NetworkService.instance.ensureStarted();
    _netSub = NetworkService.instance.onChanged.listen((ok) {
      debugPrint(ok ? 'Đã kết nối mạng' : 'Mất kết nối mạng');
    });
  }

  @override
  void dispose() {
    _netSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = TabItem.values.indexOf(_current);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        final nav = _navKeys[_current]?.currentState;

        if (nav != null && nav.canPop()) {
          nav.pop();
          return;
        }

        if (_current != TabItem.doanhThu) {
          setState(() => _current = TabItem.doanhThu);
          return;
        }

        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Thoát ứng dụng?'),
            content: const Text('Bạn có chắc muốn thoát không?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Không'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Thoát'),
              ),
            ],
          ),
        );

        if (shouldExit == true) {
          Future.delayed(const Duration(milliseconds: 100), () {
            SystemNavigator.pop();
          });
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            const HeaderSection(),
            Expanded(
              child: IndexedStack(
                index: index,
                children: [
                  _TabNav(navKey: _navKeys[TabItem.doanhThu]!, builder: (_) => const DoanhThuPage()),
                  _TabNav(navKey: _navKeys[TabItem.donDat]!, builder: (_) => const DonDatPage()),
                  _TabNav(navKey: _navKeys[TabItem.thongTin]!, builder: (_) => const CoSoPage()),
                  _TabNav(navKey: _navKeys[TabItem.datSan]!, builder: (_) => const KhoaSanPage()),
                  _TabNav(navKey: _navKeys[TabItem.hoanTien]!, builder: (_) => const HoanTienPage()),
                  _TabNav(navKey: _navKeys[TabItem.danhGia]!, builder: (_) => const DanhGiaPage()),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavBar(context),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: TabItem.values.indexOf(_current),
        onTap: (i) => setState(() => _current = TabItem.values[i]),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: const Color(0xFF757575),
        selectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1.5,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
        items: [
          _buildNavItem(Icons.analytics_outlined, Icons.analytics, 'Doanh thu', context),
          _buildNavItem(Icons.receipt_long_outlined, Icons.receipt_long, 'Đơn đặt', context),
          _buildNavItem(Icons.info_outline, Icons.info, 'Thông tin', context),
          _buildNavItem(Icons.calendar_today_outlined, Icons.calendar_today, 'Khóa slot', context),
          _buildNavItem(Icons.payment_outlined, Icons.payment, 'Hoàn tiền', context),
          _buildNavItem(Icons.star_outline, Icons.star, 'Đánh giá', context),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
      IconData outlineIcon,
      IconData filledIcon,
      String label,
      BuildContext context,
      ) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: EdgeInsets.all(6),
        child: Icon(outlineIcon, size: 22),
      ),
      activeIcon: Container(
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(filledIcon, size: 22, color: Theme.of(context).colorScheme.primary),
      ),
      label: label,
    );
  }
}

class _TabNav extends StatelessWidget {
  final WidgetBuilder builder;
  final GlobalKey<NavigatorState> navKey;
  const _TabNav({required this.builder, required this.navKey});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navKey,
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: builder,
        settings: settings,
      ),
    );
  }
}

// =============================================
// HEADER SECTION
// =============================================
class HeaderSection extends StatefulWidget {
  const HeaderSection({super.key});

  @override
  State<HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<HeaderSection> {
  Map<String, dynamic>? _coSoData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCoSoData();
  }

  Future<void> _loadCoSoData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('co_so')
          .doc(user.uid)
          .get();

      if (mounted) {
        setState(() {
          _coSoData = doc.data();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Lỗi load cơ sở: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2E7D32),
            Color(0xFF388E3C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
      child: Row(
        children: [
          _buildAvatar(),
          SizedBox(width: 16),
          Expanded(child: _buildInfo()),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (_isLoading) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.3),
        ),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    final avatarUrl = (_coSoData?['anh_dai_dien'] as String?) ?? '';

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: avatarUrl.isNotEmpty
          ? CircleAvatar(backgroundImage: NetworkImage(avatarUrl))
          : CircleAvatar(
        backgroundColor: Colors.white.withOpacity(0.2),
        child: Icon(Icons.store, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildInfo() {
    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: 6),
          Container(
            width: 150,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      );
    }

    final tenCoSo = (_coSoData?['ten_co_so'] as String?) ?? 'Cơ sở của bạn';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quản lý cơ sở',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          tenCoSo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return InkWell(
      onTap: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Đăng xuất'),
            content: const Text('Bạn có chắc muốn đăng xuất?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Không'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Đăng xuất'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await AuthService().signOut();
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Icon(Icons.logout, color: Colors.white, size: 20),
      ),
    );
  }
}