import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../models/location_sharing_schedule_model.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart';

/// Driver's group list screen
/// Shows all groups created by the driver
class DriverGroupsScreen extends StatefulWidget {
  const DriverGroupsScreen({super.key});

  @override
  State<DriverGroupsScreen> createState() => _DriverGroupsScreenState();
}

class _DriverGroupsScreenState extends State<DriverGroupsScreen> {
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
    _authService = await AuthServiceFactory.getInstance();
    _groupService = await GroupServiceFactory.getInstance();
    _currentUser = await _authService!.getCurrentUser();
    await _loadGroups();
  }

  Future<void> _loadGroups() async {
    if (_currentUser == null || _groupService == null) return;

    setState(() => _isLoading = true);
    try {
      final groups = await _groupService!.getGroupsByDriver(_currentUser!.id);
      setState(() {
        _groups = groups;
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

  Future<void> _createGroup() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _CreateGroupDialog(),
    );

    if (result == null || _currentUser == null) return;

    try {
      final schedule = result['schedule'] as LocationSharingScheduleModel;
      final group = await _groupService!.createGroup(
        _currentUser!,
        result['name'] as String,
        schedule: schedule,
      );

      await _loadGroups();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('그룹이 생성되었습니다. 코드: ${group.code}'),
            action: SnackBarAction(
              label: '복사',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: group.code));
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('그룹 생성 실패: $e')),
        );
      }
    }
  }

  void _openGroup(GroupModel group) {
    context.push('/driver-home/${group.id}', extra: _currentUser);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 그룹 목록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGroups,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? _buildEmptyState()
              : _buildGroupList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createGroup,
        icon: const Icon(Icons.add),
        label: const Text('그룹 생성'),
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
            '생성한 그룹이 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '아래 버튼을 눌러 새 그룹을 만들어보세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
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
    // Show all time slots summary
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
                  Expanded(
                    child: Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      group.code,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: group.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('코드가 복사되었습니다')),
                      );
                    },
                    tooltip: '코드 복사',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    scheduleText,
                    style: TextStyle(color: Colors.grey.shade600),
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
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
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

/// Dialog for creating a new group
class _CreateGroupDialog extends StatefulWidget {
  const _CreateGroupDialog();

  @override
  State<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<_CreateGroupDialog> {
  final _nameController = TextEditingController();
  final List<TimeSlot> _timeSlots = [
    const TimeSlot(
      startTime: TimeOfDay(hour: 8, minute: 0),
      endTime: TimeOfDay(hour: 9, minute: 30),
    ),
  ];
  final List<int> _selectedWeekdays = [1, 2, 3, 4, 5]; // Mon-Fri only
  bool _excludeHolidays = true;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(int slotIndex, bool isStart) async {
    final slot = _timeSlots[slotIndex];
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? slot.startTime : slot.endTime,
    );
    if (picked != null) {
      setState(() {
        _timeSlots[slotIndex] = slot.copyWith(
          startTime: isStart ? picked : null,
          endTime: isStart ? null : picked,
        );
      });
    }
  }

  void _addTimeSlot() {
    setState(() {
      _timeSlots.add(const TimeSlot(
        startTime: TimeOfDay(hour: 14, minute: 0),
        endTime: TimeOfDay(hour: 15, minute: 30),
      ));
    });
  }

  void _removeTimeSlot(int index) {
    if (_timeSlots.length > 1) {
      setState(() {
        _timeSlots.removeAt(index);
      });
    }
  }

  void _toggleWeekday(int day) {
    setState(() {
      if (_selectedWeekdays.contains(day)) {
        _selectedWeekdays.remove(day);
      } else {
        _selectedWeekdays.add(day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('새 그룹 만들기'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '그룹 이름',
                hintText: '예: 오전 셔틀버스',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 20),
            const Text(
              '위치 공유 시간',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._buildTimeSlotWidgets(),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _addTimeSlot,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('시간대 추가'),
              ),
            ),
            const SizedBox(height: 16),
            const Text('요일 선택:', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: [
                _buildWeekdayChip(1, '월'),
                _buildWeekdayChip(2, '화'),
                _buildWeekdayChip(3, '수'),
                _buildWeekdayChip(4, '목'),
                _buildWeekdayChip(5, '금'),
              ],
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text('공휴일 제외'),
              subtitle: const Text('한국 공휴일에는 위치 공유 안함'),
              value: _excludeHolidays,
              onChanged: (value) =>
                  setState(() => _excludeHolidays = value ?? true),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('그룹 이름을 입력해주세요')),
              );
              return;
            }
            if (_selectedWeekdays.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('최소 하나의 요일을 선택해주세요')),
              );
              return;
            }
            Navigator.pop(context, {
              'name': _nameController.text.trim(),
              'schedule': LocationSharingScheduleModel(
                timeSlots: List.from(_timeSlots),
                weekdays: List.from(_selectedWeekdays)..sort(),
                excludeHolidays: _excludeHolidays,
              ),
            });
          },
          child: const Text('생성'),
        ),
      ],
    );
  }

  List<Widget> _buildTimeSlotWidgets() {
    return List.generate(_timeSlots.length, (index) {
      final slot = _timeSlots[index];
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _selectTime(index, true),
                child: Text(
                  '${slot.startTime.hour.toString().padLeft(2, '0')}:${slot.startTime.minute.toString().padLeft(2, '0')}',
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('~'),
            ),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _selectTime(index, false),
                child: Text(
                  '${slot.endTime.hour.toString().padLeft(2, '0')}:${slot.endTime.minute.toString().padLeft(2, '0')}',
                ),
              ),
            ),
            if (_timeSlots.length > 1)
              IconButton(
                onPressed: () => _removeTimeSlot(index),
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                color: Colors.red,
                visualDensity: VisualDensity.compact,
              )
            else
              const SizedBox(width: 40),
          ],
        ),
      );
    });
  }

  Widget _buildWeekdayChip(int day, String label) {
    final selected = _selectedWeekdays.contains(day);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _toggleWeekday(day),
      visualDensity: VisualDensity.compact,
    );
  }
}
