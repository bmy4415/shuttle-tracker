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
  bool _isLoading = true; // Start with loading to check existing user

  @override
  void initState() {
    super.initState();
    _checkExistingUser();
  }

  /// Check if user already exists and redirect to appropriate screen
  Future<void> _checkExistingUser() async {
    try {
      final authService = await AuthServiceFactory.getInstance();
      final existingUser = await authService.getCurrentUser();

      if (!mounted) return;

      if (existingUser != null) {
        // User already has a role, redirect to groups screen
        if (existingUser.role == UserRole.driver) {
          context.go('/driver-groups');
        } else {
          context.go('/parent-groups');
        }
      } else {
        // No existing user, show role selector
        setState(() => _isLoading = false);
      }
    } catch (e) {
      // Error checking user, show role selector anyway
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
        // Parent goes to groups list (like driver)
        context.go('/parent-groups');
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
