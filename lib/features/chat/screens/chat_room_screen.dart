import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/server_date.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../cards/screens/public_card_screen.dart';

class ChatRoomScreen extends StatefulWidget {
  final int roomId;
  final String roomName;

  /// 상대 user_id — 신고/차단 대상 (없으면 신고/차단 메뉴 숨김)
  final int? otherUserId;

  const ChatRoomScreen({
    super.key,
    required this.roomId,
    required this.roomName,
    this.otherUserId,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen>
    with WidgetsBindingObserver {
  // 서버 폴링 가이드: 방 안은 5초 간격, 백그라운드 진입 시 중단
  static const _pollInterval = Duration(seconds: 5);

  final ApiClient _api = ApiClient();
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<dynamic> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  int? _myUserId;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMyId();
    _loadMessages(initial: true);
    _startPolling();
  }

  @override
  void dispose() {
    _stopPolling();
    WidgetsBinding.instance.removeObserver(this);
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  double _lastViewInset = 0;

  @override
  void didChangeMetrics() {
    // 키보드가 열리면(하단 인셋 증가) 최신 메시지가 보이도록 스크롤
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final inset = view.viewInsets.bottom;
    if (inset > _lastViewInset) _scrollToBottom();
    _lastViewInset = inset;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadMessages();
      _startPolling();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopPolling();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _loadMessages());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _loadMyId() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _myUserId = prefs.getInt(AppConstants.keyUserId));
    }
  }

  /// initial=true일 때만 로딩 표시. 폴링 갱신은 조용히 병합.
  Future<void> _loadMessages({bool initial = false}) async {
    if (initial) setState(() => _isLoading = true);
    try {
      final response = await _api.get('/chat/${widget.roomId}/messages',
          queryParams: {'page': 1, 'limit': 30});
      if (!mounted) return;
      if (response['success'] == true) {
        // 서버는 최신순(DESC) → 화면은 오래된순
        final msgs = List.from(response['data'] as List).reversed.toList();
        final changed = _hasChanged(msgs);
        if (changed) {
          final wasAtBottom = _isNearBottom();
          setState(() => _messages = msgs);
          if (initial || wasAtBottom) _scrollToBottom();
        }
      }
    } catch (_) {}
    if (initial && mounted) setState(() => _isLoading = false);
  }

  bool _hasChanged(List<dynamic> fresh) {
    if (fresh.length != _messages.length) return true;
    for (var i = 0; i < fresh.length; i++) {
      if (fresh[i]['id'] != _messages[i]['id'] ||
          fresh[i]['is_deleted'] != _messages[i]['is_deleted']) {
        return true;
      }
    }
    return false;
  }

  bool _isNearBottom() {
    if (!_scrollCtrl.hasClients) return true;
    return _scrollCtrl.position.maxScrollExtent - _scrollCtrl.offset < 120;
  }

  // ─── 전송 ──────────────────────────────────────────────
  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || _isSending) return;
    _messageCtrl.clear();
    await _send({'content': text, 'message_type': 'text'});
  }

  Future<void> _send(Map<String, dynamic> body) async {
    setState(() => _isSending = true);
    try {
      final response =
          await _api.post('/chat/${widget.roomId}/messages', body: body);
      if (response['success'] == true) {
        // 전송 직후 1회 즉시 폴링 (서버 가이드 §3)
        await _loadMessages();
        _scrollToBottom();
      }
    } on ApiException catch (e) {
      if (mounted) showErrorSnackBar(context, e.message);
    } catch (_) {}
    if (mounted) setState(() => _isSending = false);
  }

  // ─── 첨부 ──────────────────────────────────────────────
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
                subtitle: const Text('갤러리에서 사진 선택'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendImage();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.success,
                  child: Icon(Icons.badge_outlined, color: Colors.white),
                ),
                title: const Text('명함 공유'),
                subtitle: const Text('내 명함을 상대에게 전달'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCardPicker();
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

  /// 이미지 선택 → POST /chat/:roomId/upload (multipart)
  /// 서버가 업로드와 동시에 메시지를 생성하므로 별도 send 없이 폴링만 하면 됨
  Future<void> _pickAndSendImage() async {
    if (_isSending) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _isSending = true);
    try {
      final response = await _api.uploadFile(
        '/chat/${widget.roomId}/upload',
        picked.path,
        fieldName: 'file',
        fields: {'file_type': 'image'},
      );
      if (response['success'] == true) {
        await _loadMessages();
        _scrollToBottom();
      }
    } on ApiException catch (e) {
      if (mounted) showErrorSnackBar(context, e.message);
    } catch (_) {
      if (mounted) showErrorSnackBar(context, '이미지 업로드에 실패했습니다.');
    }
    if (mounted) setState(() => _isSending = false);
  }

  /// 명함 공유 — 내 명함 선택 시트
  Future<void> _showCardPicker() async {
    List<dynamic> cards = [];
    try {
      final response = await _api.get('/cards');
      if (response['success'] == true) {
        cards = response['data'] as List;
      }
    } catch (_) {}
    if (!mounted) return;
    if (cards.isEmpty) {
      showErrorSnackBar(context, '공유할 명함이 없습니다.');
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('공유할 명함 선택', style: AppTextStyles.h4),
            ),
            ...cards.map((card) => ListTile(
                  leading: const Icon(Icons.badge_outlined,
                      color: AppColors.primary),
                  title: Text(card['name'] as String? ?? '명함'),
                  subtitle: Text(
                    [card['company'], card['title']]
                        .whereType<String>()
                        .join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _send({
                      'message_type': 'card',
                      'card_id': card['id'],
                      'content': '명함을 공유했습니다.',
                    });
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── 메시지 삭제 ───────────────────────────────────────
  void _onMessageLongPress(Map<String, dynamic> msg) {
    final isMe = msg['sender_id'] == _myUserId;
    if (!isMe || _deleted(msg)) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: ListTile(
          leading: const Icon(Icons.delete_outline, color: AppColors.error),
          title: const Text('메시지 삭제'),
          onTap: () {
            Navigator.pop(ctx);
            _deleteMessage(msg['id'] as int);
          },
        ),
      ),
    );
  }

  Future<void> _deleteMessage(int messageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('메시지 삭제'),
        content: const Text('이 메시지를 삭제할까요?\n상대방 화면에서도 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final response =
          await _api.delete('/chat/${widget.roomId}/messages/$messageId');
      if (response['success'] == true) {
        await _loadMessages();
      }
    } on ApiException catch (e) {
      if (mounted) showErrorSnackBar(context, e.message);
    } catch (_) {}
  }

  // ─── 신고 / 차단 (스토어 심사 필수 UGC 정책) ────────────
  void _showReportSheet() {
    const reasons = ['스팸/광고', '욕설/비방', '사기/사칭', '음란물', '기타'];
    String selected = reasons.first;
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('사용자 신고'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('신고 사유를 선택해주세요.', style: AppTextStyles.body2),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: reasons
                    .map((r) => ChoiceChip(
                          label: Text(r, style: const TextStyle(fontSize: 12)),
                          selected: selected == r,
                          onSelected: (_) =>
                              setDialogState(() => selected = r),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: '상세 내용 (선택)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _report(selected, descCtrl.text.trim());
              },
              child:
                  const Text('신고', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _report(String reason, String description) async {
    try {
      final response = await _api.post('/chat/report', body: {
        'target_type': 'user',
        'target_id': widget.otherUserId,
        'reason': reason,
        if (description.isNotEmpty) 'description': description,
      });
      if (!mounted) return;
      if (response['success'] == true) {
        showSuccessSnackBar(
            context, response['message'] as String? ?? '신고가 접수되었습니다.');
      }
    } on ApiException catch (e) {
      if (mounted) showErrorSnackBar(context, e.message);
    } catch (_) {}
  }

  Future<void> _blockUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${widget.roomName}님 차단'),
        content: const Text(
            '차단하면 이 상대와의 채팅방이 목록에서 사라지고\n더 이상 메시지를 주고받을 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('차단', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final response = await _api.post('/chat/block',
          body: {'blocked_user_id': widget.otherUserId});
      if (!mounted) return;
      if (response['success'] == true) {
        showSuccessSnackBar(
            context, response['message'] as String? ?? '사용자를 차단했습니다.');
        Navigator.pop(context); // 방에서 나가 목록으로
      }
    } on ApiException catch (e) {
      if (mounted) showErrorSnackBar(context, e.message);
    } catch (_) {}
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
    final dt = tryParseServerDate(isoDate);
    if (dt == null) return '';
    return DateFormat('HH:mm').format(dt);
  }

  /// 서버는 is_deleted를 0/1(int)로 내려줌 — bool과 겸용 처리
  static bool _deleted(Map<String, dynamic> msg) =>
      msg['is_deleted'] == true || msg['is_deleted'] == 1;

  void _openSharedCard(Map<String, dynamic> msg) {
    final cardId = msg['card_id'] as int?;
    if (cardId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PublicCardScreen(cardId: cardId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
        actions: [
          if (widget.otherUserId != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'report') _showReportSheet();
                if (value == 'block') _blockUser();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.flag_outlined,
                          size: 20, color: AppColors.textSecondary),
                      SizedBox(width: 8),
                      Text('신고하기'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(Icons.block, size: 20, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('차단하기'),
                    ],
                  ),
                ),
              ],
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
                          final msg =
                              Map<String, dynamic>.from(_messages[i] as Map);
                          final isMe = msg['sender_id'] == _myUserId;
                          return GestureDetector(
                            onLongPress: () => _onMessageLongPress(msg),
                            child: _MessageBubble(
                              content: msg['content'] as String? ?? '',
                              isMe: isMe,
                              time: _formatTime(msg['created_at'] as String?),
                              senderName: msg['sender_name'] as String?,
                              messageType:
                                  msg['message_type'] as String? ?? 'text',
                              isDeleted: _deleted(msg),
                              cardName: msg['card_name'] as String?,
                              fileUrl: msg['file_url'] as String?,
                              onCardTap: msg['message_type'] == 'card'
                                  ? () => _openSharedCard(msg)
                                  : null,
                            ),
                          );
                        },
                      ),
          ),

          // 입력창
          Container(
            // 키보드 회피는 Scaffold(resizeToAvoidBottomInset)가 처리 —
            // viewInsets를 여기서 또 더하면 이중 보정되어 목록이 짜부라진다
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
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
  final bool isDeleted;
  final String? cardName;
  final String? fileUrl;
  final VoidCallback? onCardTap;

  const _MessageBubble({
    required this.content,
    required this.isMe,
    required this.time,
    this.senderName,
    this.messageType = 'text',
    this.isDeleted = false,
    this.cardName,
    this.fileUrl,
    this.onCardTap,
  });

  /// 첨부 타입에 따른 아이콘
  IconData get _attachIcon {
    switch (messageType) {
      case 'image':
        return Icons.image_outlined;
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
      case 'file':
      default:
        return '파일';
    }
  }

  bool get _isAttachment => messageType == 'image' || messageType == 'file';

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                child: _buildContent(),
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

  Widget _buildContent() {
    if (isDeleted) {
      return Text(
        '삭제된 메시지입니다.',
        style: TextStyle(
          color: isMe
              ? Colors.white.withValues(alpha: 0.6)
              : AppColors.textTertiary,
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    if (messageType == 'card') {
      return _CardSharePreview(
        cardName: cardName ?? '명함',
        isMe: isMe,
        onTap: onCardTap,
      );
    }
    if (_isAttachment) {
      // 이미지는 URL이 있으면 미리보기, 로드 실패 시 파일 표시로 폴백
      if (messageType == 'image' && fileUrl != null && fileUrl!.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            fileUrl!,
            width: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _AttachmentPreview(
              fileName: content,
              icon: _attachIcon,
              label: _attachLabel,
              isMe: isMe,
            ),
          ),
        );
      }
      return _AttachmentPreview(
        fileName: content,
        icon: _attachIcon,
        label: _attachLabel,
        isMe: isMe,
      );
    }
    return Text(
      content,
      style: TextStyle(
        color: isMe ? Colors.white : AppColors.textPrimary,
        fontSize: 14,
      ),
    );
  }
}

/// 명함 공유 메시지 (message_type: card) — 탭하면 공개 명함 뷰어로
class _CardSharePreview extends StatelessWidget {
  final String cardName;
  final bool isMe;
  final VoidCallback? onTap;

  const _CardSharePreview({
    required this.cardName,
    required this.isMe,
    this.onTap,
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

    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.badge_outlined, color: iconColor, size: 22),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cardName,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text('명함 보기', style: TextStyle(color: subColor, fontSize: 11)),
            ],
          ),
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
