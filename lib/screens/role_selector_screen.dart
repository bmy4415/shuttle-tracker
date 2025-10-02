import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Role selector screen - Initial screen for selecting user role
class RoleSelectorScreen extends StatefulWidget {
  const RoleSelectorScreen({super.key});

  @override
  State<RoleSelectorScreen> createState() => _RoleSelectorScreenState();
}

class _RoleSelectorScreenState extends State<RoleSelectorScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // TODO: 배포시 삭제 - 개발용 앱 시작시간 팝업
    _showStartupTimestamp();
  }

  @override
  void didUpdateWidget(RoleSelectorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // TODO: 배포시 삭제 - Hot Reload 시에도 타임스탬프 팝업
    _showStartupTimestamp();
  }

  // TODO: 배포시 삭제 - 개발용 Hot Restart 확인 팝업
  void _showStartupTimestamp() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final startTime = DateTime.now();
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('✅ Hot Reload 성공!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('앱 시작시간:'),
                const SizedBox(height: 8),
                Text(
                  startTime.toString().substring(0, 19),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
    });
  }

  Future<void> _selectRole(UserRole role) async {
    setState(() => _isLoading = true);

    try {
      final authService = await AuthServiceFactory.getInstance();
      final user = await authService.createUser(role);

      if (!mounted) return;

      // Navigate to group setup
      context.push('/group-setup', extra: user);
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류: ${e.toString()}')));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('셔틀 트래커'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_bus, size: 100, color: Colors.blue),
            const SizedBox(height: 40),
            const Text(
              '사용자 유형을 선택하세요',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => _selectRole(UserRole.parent),
              icon: const Icon(Icons.person),
              label: const Text('학부모'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _selectRole(UserRole.driver),
              icon: const Icon(Icons.drive_eta),
              label: const Text('기사'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
            ),
          ],
        ),
      ),
    );
  }
}
