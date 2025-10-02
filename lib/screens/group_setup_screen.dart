import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart';

/// Group setup screen (Create or Join)
/// 기사: 그룹 생성
/// 학부모/선생님: 그룹 참여
class GroupSetupScreen extends StatefulWidget {
  final UserModel user;

  const GroupSetupScreen({
    super.key,
    required this.user,
  });

  @override
  State<GroupSetupScreen> createState() => _GroupSetupScreenState();
}

class _GroupSetupScreenState extends State<GroupSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _groupCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupCodeController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final groupService = await GroupServiceFactory.getInstance();
      final authService = await AuthServiceFactory.getInstance();

      final group = await groupService.createGroup(
        widget.user,
        _groupNameController.text.trim(),
      );

      // Update user with group ID
      final updatedUser = widget.user.copyWith(groupId: group.id);
      await authService.updateUser(updatedUser);

      if (!mounted) return;

      // Show success dialog with group code
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('✅ 그룹 생성 완료'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('그룹이 생성되었습니다!'),
              const SizedBox(height: 16),
              const Text(
                '그룹 코드:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: group.code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ 그룹 코드가 복사되었습니다!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        group.code,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.copy, size: 20, color: Colors.blue),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '👆 탭하여 복사',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                '학부모에게 이 코드를 공유하세요!',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Navigate to appropriate home screen
                if (widget.user.role == UserRole.driver) {
                  context.push('/driver-home', extra: {'user': widget.user, 'group': group});
                } else {
                  context.push('/parent-home', extra: {'user': widget.user, 'group': group});
                }
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('그룹 생성 실패: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _joinGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final groupService = await GroupServiceFactory.getInstance();
      final authService = await AuthServiceFactory.getInstance();

      final code = _groupCodeController.text.trim().toUpperCase();

      // Check if group exists
      final group = await groupService.getGroupByCode(code);
      if (group == null) {
        throw Exception('존재하지 않는 그룹 코드입니다.');
      }

      // Join group
      await groupService.joinGroup(code, widget.user);

      // Update user with group ID
      final updatedUser = widget.user.copyWith(groupId: group.id);
      await authService.updateUser(updatedUser);

      if (!mounted) return;

      // Show success and navigate to home screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 그룹에 참여했습니다!')),
      );

      // Navigate to appropriate home screen
      if (widget.user.role == UserRole.driver) {
        context.go('/driver-home', extra: {'user': widget.user, 'group': group});
      } else {
        context.go('/parent-home', extra: {'user': widget.user, 'group': group});
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('그룹 참여 실패: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDriver = widget.user.role == UserRole.driver;

    return Scaffold(
      appBar: AppBar(
        title: Text(isDriver ? '그룹 생성' : '그룹 참여'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // User info card
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              isDriver ? Icons.directions_bus : Icons.person,
                              size: 48,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.user.nickname,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.user.roleDisplayName,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Driver: Create group form
                    if (isDriver) ...[
                      const Text(
                        '새 그룹 만들기',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _groupNameController,
                        decoration: const InputDecoration(
                          labelText: '그룹 이름',
                          hintText: '예: 오전 셔틀버스',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.group),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '그룹 이름을 입력하세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '그룹을 생성하면 고유한 코드가 발급됩니다.\n학부모에게 이 코드를 공유하세요!',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _createGroup,
                        icon: const Icon(Icons.add),
                        label: const Text('그룹 생성'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                      ),
                    ],

                    // Parent/Teacher: Join group form
                    if (!isDriver) ...[
                      const Text(
                        '그룹 코드 입력',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _groupCodeController,
                        decoration: const InputDecoration(
                          labelText: '그룹 코드',
                          hintText: '예: LION3A',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.vpn_key),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '그룹 코드를 입력하세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '기사님에게 받은 그룹 코드를 입력하세요.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _joinGroup,
                        icon: const Icon(Icons.login),
                        label: const Text('그룹 참여'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}