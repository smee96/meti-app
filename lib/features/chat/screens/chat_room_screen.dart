import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class ChatRoomScreen extends StatefulWidget {
  final int roomId;
  final String roomName;

  const ChatRoomScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ApiClient _api = ApiClient();
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<dynamic> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  int? _myUserId;

  @override
  void initState() {
    super.initState();
    _loadMyId();
    _loadMessages();
  }

  Future<void> _loadMyId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _myUserId = prefs.getInt(AppConstants.keyUserId));
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/chat/${widget.roomId}/messages',
          queryParams: {'limit': 30});
      if (response['success'] == true) {
        final msgs = List.from(response['data'] as List);
        setState(() => _messages = msgs.reversed.toList());
        _scrollToBottom();
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    _messageCtrl.clear();
    setState(() => _isSending = true);

    try {
      final response = await _api.post('/chat/${widget.roomId}/messages',
          body: {'content': text, 'message_type': 'text'});
      if (response['success'] == true) {
        final msg = response['data'] as Map<String, dynamic>;
        setState(() => _messages.add(msg));
        _scrollToBottom();
      }
    } catch (_) {}
    setState(() => _isSending = false);
  }

  /// 첸부 메뉴 표시
  void _showAttachBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.image_outlined, color: Colors.white),
                ),
                title: const Text('이미지 첨부'),
                subtitle: const Text('사진 또는 이미지 파일 선택'),
                onTap: () {
                  Navigator.pop(ctx);
                  _sendAttachment(type: 'image', label: '이미지');
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.textTertiary,
                  child: Icon(Icons.close, color: Colors.white, size: 18),
                ),
                title: const Text('취소'),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mock 파일 첨부 전송 (Web 호환 — 실제 파일 선택 없이 더미 메시지 전송)
  Future<void> _sendAttachment(
      {required String type, required String label}) async {
    if (_isSending) return;
    setState(() => _isSending = true);
    try {
      // Mock: 직접 첨부파일명 생성
      final now = DateTime.now();
      final fakeFileName =
          '${label}_${now.millisecondsSinceEpoch}.${type == 'image' ? 'jpg' : type == 'video' ? 'mp4' : 'pdf'}';
      final response = await _api.post('/chat/${widget.roomId}/messages', body: {
        'content': fakeFileName,
        'message_type': type,
        'file_name': fakeFileName,
        'file_size': 1024 * (type == 'image' ? 256 : 512),
      });
      if (response['success'] == true) {
        final msg = response['data'] as Map<String, dynamic>;
        setState(() => _messages.add(msg));
        _scrollToBottom();
      }
    } catch (_) {}
    setState(() => _isSending = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          // 메시지 목록
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _messages.isEmpty
                    ? const Center(
                        child: Text('메시지가 없습니다.', style: AppTextStyles.body2))
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final msg = _messages[i];
                          final isMe = msg['sender_id'] == _myUserId;
                          return _MessageBubble(
                            content: msg['content'] as String? ?? '',
                            isMe: isMe,
                            time: _formatTime(msg['created_at'] as String?),
                            senderName: msg['sender_name'] as String?,
                            messageType:
                                msg['message_type'] as String? ?? 'text',
                          );
                        },
                      ),
          ),

          // 입력창
          Container(
            padding: EdgeInsets.only(
              left: 8,
              right: 8,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 첨부 버튼
                  Tooltip(
                    message: '파일 첨부',
                    child: InkWell(
                      onTap: _showAttachBottomSheet,
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: AppColors.textSecondary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _messageCtrl,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: '메시지 입력...',
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _isSending ? null : _sendMessage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _isSending
                            ? AppColors.textTertiary
                            : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
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

class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isMe;
  final String time;
  final String? senderName;
  final String messageType;

  const _MessageBubble({
    required this.content,
    required this.isMe,
    required this.time,
    this.senderName,
    this.messageType = 'text',
  });

  /// 첨부 타입에 따른 아이콘
  IconData get _attachIcon {
    switch (messageType) {
      case 'image':
        return Icons.image_outlined;
      case 'video':
        return Icons.videocam_outlined;
      case 'file':
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  /// 첨부 타입 레이블
  String get _attachLabel {
    switch (messageType) {
      case 'image':
        return '이미지';
      case 'video':
        return '동영상';
      case 'file':
      default:
        return '파일';
    }
  }

  bool get _isAttachment =>
      messageType == 'image' || messageType == 'file' || messageType == 'video';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(
                senderName?.isNotEmpty == true ? senderName![0].toUpperCase() : '?',
                style: const TextStyle(
                    color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
          ],

          Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe && senderName != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2, left: 4),
                  child: Text(senderName!,
                      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500)),
                ),
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.65,
                ),
                padding: _isAttachment
                    ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
                    : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  border: isMe
                      ? null
                      : Border.all(color: AppColors.border),
                ),
                child: _isAttachment
                    ? _AttachmentPreview(
                        fileName: content,
                        icon: _attachIcon,
                        label: _attachLabel,
                        isMe: isMe,
                      )
                    : Text(
                        content,
                        style: TextStyle(
                          color: isMe ? Colors.white : AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(time, style: AppTextStyles.caption),
              ),
            ],
          ),

          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

/// 첨부파일 미리보기 위젯
class _AttachmentPreview extends StatelessWidget {
  final String fileName;
  final IconData icon;
  final String label;
  final bool isMe;

  const _AttachmentPreview({
    required this.fileName,
    required this.icon,
    required this.label,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isMe ? Colors.white : AppColors.textPrimary;
    final subColor = isMe
        ? Colors.white.withValues(alpha: 0.7)
        : AppColors.textSecondary;
    final iconBg = isMe
        ? Colors.white.withValues(alpha: 0.2)
        : AppColors.primary.withValues(alpha: 0.1);
    final iconColor = isMe ? Colors.white : AppColors.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(color: subColor, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
