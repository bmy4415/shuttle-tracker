import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart';

/// Parent's group list screen
/// Shows all groups the parent has joined
class ParentGroupsScreen extends StatefulWidget {
  const ParentGroupsScreen({super.key});

  @override
  State<ParentGroupsScreen> createState() => _ParentGroupsScreenState();
}

class _ParentGroupsScreenState extends State<ParentGroupsScreen> {
  AuthService? _authService;
  GroupService? _groupService;
  UserModel? _currentUser;
  List<GroupModel> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Parallelize service initialization for faster loading
    final results = await Future.wait([
      AuthServiceFactory.getInstance(),
      GroupServiceFactory.getInstance(),
    ]);
    _authService = results[0] as AuthService;
    _groupService = results[1] as GroupService;
    _currentUser = await _authService!.getCurrentUser();
    await _loadGroups();
  }

  Future<void> _loadGroups() async {
    if (_currentUser == null || _groupService == null) return;

    setState(() => _isLoading = true);
    try {
      final groups = await _groupService!.getGroupsByMember(_currentUser!.id);
      // Filter out groups where user is the driver (they should use driver screen)
      final parentGroups = groups
          .where((g) => g.driverId != _currentUser!.id)
          .toList();
      setState(() {
        _groups = parentGroups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('그룹 목록을 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  void _joinGroup() {
    if (_currentUser == null) return;
    context.push('/group-setup', extra: _currentUser);
  }

  void _openGroup(GroupModel group) {
    context.push('/parent-home', extra: {
      'user': _currentUser,
      'group': group,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('참가한 그룹'),
        backgroundColor: Colors.blue.shade100,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGroups,
            tooltip: '새로고침',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
            tooltip: '설정',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? _buildEmptyState()
              : _buildGroupList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _joinGroup,
        icon: const Icon(Icons.group_add),
        label: const Text('그룹 참가'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '참가한 그룹이 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '아래 버튼을 눌러 그룹에 참가해보세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _joinGroup,
            icon: const Icon(Icons.group_add),
            label: const Text('그룹 참가하기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupList() {
    return RefreshIndicator(
      onRefresh: _loadGroups,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          return _buildGroupCard(group);
        },
      ),
    );
  }

  Widget _buildGroupCard(GroupModel group) {
    final schedule = group.sharingSchedule;
    final scheduleText = schedule.timeSlotsString;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openGroup(group),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.directions_bus,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '기사: ${group.driverName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      scheduleText,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${group.memberCount}명',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
