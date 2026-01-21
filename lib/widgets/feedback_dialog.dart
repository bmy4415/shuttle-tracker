import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/feedback_service.dart';

/// Dialog for submitting feedback
class FeedbackDialog extends StatefulWidget {
  final UserModel user;
  final String? groupId;
  final String screenName;

  const FeedbackDialog({
    super.key,
    required this.user,
    this.groupId,
    required this.screenName,
  });

  /// Show the feedback dialog
  static Future<bool?> show({
    required BuildContext context,
    required UserModel user,
    String? groupId,
    required String screenName,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => FeedbackDialog(
        user: user,
        groupId: groupId,
        screenName: screenName,
      ),
    );
  }

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Auto-focus the text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _controller.text.trim();

    if (message.isEmpty) {
      setState(() {
        _errorMessage = '피드백 내용을 입력해주세요';
      });
      return;
    }

    if (message.length < 5) {
      setState(() {
        _errorMessage = '피드백은 최소 5자 이상 입력해주세요';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final feedbackService = FeedbackServiceFactory.getInstance() as FirestoreFeedbackService;
      final feedback = feedbackService.createFeedback(
        user: widget.user,
        message: message,
        screenName: widget.screenName,
        groupId: widget.groupId,
      );

      await feedbackService.submitFeedback(feedback);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('피드백이 제출되었습니다. 감사합니다!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = '피드백 제출 실패: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.feedback_outlined, color: Colors.blue),
          SizedBox(width: 8),
          Text('피드백 보내기'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '베타 테스트에 참여해 주셔서 감사합니다!\n버그 신고, 개선 제안, 의견 등을 자유롭게 남겨주세요.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLines: 5,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: '피드백 내용을 입력하세요...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                errorText: _errorMessage,
              ),
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 8),
            // Context info (for debugging)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '자동 첨부 정보',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '화면: ${widget.screenName}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  Text(
                    '사용자: ${widget.user.nickname} (${widget.user.roleDisplayName})',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  if (widget.groupId != null)
                    Text(
                      '그룹: ${widget.groupId}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('제출'),
        ),
      ],
    );
  }
}
