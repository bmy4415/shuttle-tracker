import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/seed_data_service.dart';
import '../config/env_config.dart';

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

      // Check if user already exists
      final existingUser = await authService.getCurrentUser();
      UserModel user;

      if (existingUser != null) {
        // User already exists, check if role matches
        if (existingUser.role != role) {
          // Role mismatch - user tried to change role
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이미 다른 역할로 등록되어 있습니다.\n설정에서 계정을 초기화해주세요.'),
              duration: Duration(seconds: 3),
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
        user = existingUser;
      } else {
        // No user exists, create new one
        user = await authService.createUser(role);
      }

      if (!mounted) return;

      // Navigate based on role
      if (role == UserRole.driver) {
        // Driver goes to groups list
        context.go('/driver-groups');
      } else {
        // Parent goes to group setup
        context.push('/group-setup', extra: user);
      }
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
      body: Column(
        children: [
          // Test info banner (local only)
          if (EnvConfig.isLocal)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.amber.shade100,
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.science, size: 16, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        '로컬 개발 환경',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '테스트 그룹 코드: ${SeedDataService.testGroupCode}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    '학부모로 로그인 후 위 코드로 참여하세요',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Center(
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
          ),
        ],
      ),
    );
  }
}
