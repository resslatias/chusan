import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CauHinhThanhToanPage extends StatefulWidget {
  const CauHinhThanhToanPage({super.key});

  @override
  State<CauHinhThanhToanPage> createState() => _CauHinhThanhToanPageState();
}

class _CauHinhThanhToanPageState extends State<CauHinhThanhToanPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  String? _coSoKey;
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers
  final _clientIdController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _checksumKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _clientIdController.dispose();
    _apiKeyController.dispose();
    _checksumKeyController.dispose();
    super.dispose();
  }

  // ==================== LOAD DATA ====================
  Future<void> _loadData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng đăng nhập')),
          );
          Navigator.pop(context);
        }
        return;
      }

      _coSoKey = user.uid;
      final doc = await _firestore.collection('co_so').doc(_coSoKey).get();

      if (doc.exists) {
        final data = doc.data() ?? {};

        _clientIdController.text = data['client_Id'] ?? '';
        _apiKeyController.text = data['api_Key'] ?? '';
        _checksumKeyController.text = data['checksum_Key'] ?? '';
      }
    } catch (e) {
      debugPrint('Lỗi load payment config: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==================== SHOW CONFIRM DIALOG ====================
  Future<void> _showConfirmDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận lưu'),
          content: const Text(
            'Đây là dữ liệu nhạy cảm, bạn có chắc chắn muốn lưu thay đổi không?',
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Đồng ý',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _saveData();
              },
            ),
          ],
        );
      },
    );
  }

  // ==================== SAVE DATA ====================
  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    if (_coSoKey == null) return;

    setState(() => _isSaving = true);

    try {
      final updateData = {
        'client_Id': _clientIdController.text.trim(),
        'api_Key': _apiKeyController.text.trim(),
        'checksum_Key': _checksumKeyController.text.trim(),
      };

      await _firestore.collection('co_so').doc(_coSoKey).update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu cấu hình thanh toán')),
        );
      }
    } catch (e) {
      debugPrint('Lỗi save payment config: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lưu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ==================== BUILD UI ====================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cấu Hình Thanh Toán PayOS"),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _showConfirmDialog, // Đổi thành hiển thị cảnh báo
            ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Thông tin tích hợp PayOS",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _clientIdController,
                decoration: const InputDecoration(
                  labelText: 'Client ID',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập Client ID'
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập API Key'
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _checksumKeyController,
                decoration: const InputDecoration(
                  labelText: 'Checksum Key',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập Checksum Key'
                    : null,
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}