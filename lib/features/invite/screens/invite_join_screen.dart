import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../routes/app_router.dart';

/// 초대링크 딥링크 진입 화면
/// - 비로그인: 로그인/회원가입 안내 → 토큰 임시 저장
/// - 로그인: 그룹 정보 미리보기 → 가입 확인 모달
class InviteJoinScreen extends StatefulWidget {
  final String token;
  const InviteJoinScreen({super.key, required this.token});

  @override
  State<InviteJoinScreen> createState() => _InviteJoinScreenState();
}

class _InviteJoinScreenState extends State<InviteJoinScreen> {
  final _api = ApiClient();

  bool _isLoading = true;
  bool _isJoining = false;
  String? _errorMessage;
  Map<String, dynamic>? _previewData;

  // birth_date 입력 컨트롤러 (가입 시 선택적 제출)
  final _birthDateCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  @override
  void dispose() {
    _birthDateCtrl.dispose();
    super.dispose();
  }

  // ── 그룹 미리보기 로드 (인증 불필요) ──────────────────────
  Future<void> _loadPreview() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final res = await _api.get(
        '/groups/invite/${widget.token}',  // v2.8
        auth: false,
      );
      if (res['success'] == true) {
        setState(() => _previewData = res['data'] as Map<String, dynamic>?);
      } else {
        setState(() => _errorMessage = '초대 링크 정보를 불러올 수 없습니다.');
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = '네트워크 오류가 발생했습니다.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── 가입 처리 (인증 필요) ─────────────────────────────────
  Future<void> _handleJoin() async {
    final auth = context.read<AuthProvider>();

    // 비로그인 상태 → 토큰 저장 후 로그인 화면으로
    if (!auth.isAuthenticated) {
      await _savePendingToken(widget.token);
      if (!mounted) return;
      _showLoginRequiredDialog();
      return;
    }

    setState(() => _isJoining = true);
    try {
      final body = <String, dynamic>{};
      if (_birthDateCtrl.text.isNotEmpty) {
        body['birth_date'] = _birthDateCtrl.text.trim();
      }
      // v2.8: 토큰은 path param으로 전달 (body에서 제거)
      final res = await _api.post('/auth/invite/${widget.token}/join', body: body);
      if (!mounted) return;
      if (res['success'] == true) {
        // 가입 성공 → pending 토큰 삭제 후 메인으로
        await _clearPendingToken();
        if (!mounted) return;
        showSuccessSnackBar(context, res['message'] ?? '그룹에 가입되었습니다.');
        Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.main, (route) => false,
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e.message);
    } catch (_) {
      if (!mounted) return;
      showErrorSnackBar(context, '가입 처리 중 오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  // ── SharedPreferences 헬퍼 ────────────────────────────────
  static const _pendingKey = 'pending_invite_token';

  Future<void> _savePendingToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingKey, token);
  }

  Future<void> _clearPendingToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingKey);
  }

  // ── 로그인 필요 다이얼로그 ────────────────────────────────
  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('로그인이 필요합니다', style: AppTextStyles.h3),
        content: const Text(
          '그룹 가입을 위해 로그인 또는 회원가입이 필요합니다.\n로그인 후 초대 링크가 자동으로 처리됩니다.',
          style: AppTextStyles.body2,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamedAndRemoveUntil(
                context, AppRoutes.login, (r) => false,
              );
            },
            child: const Text('로그인'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamedAndRemoveUntil(
                context, AppRoutes.register, (r) => false,
              );
            },
            child: const Text('회원가입'),
          ),
        ],
      ),
    );
  }

  // ── birth_date 입력 바텀시트 ──────────────────────────────
  void _showBirthDateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('생년월일 입력 (선택)', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            const Text(
              '일부 그룹은 생년월일 확인이 필요합니다.',
              style: AppTextStyles.body2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _birthDateCtrl,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: '생년월일',
                hintText: 'YYYY-MM-DD',
                prefixIcon: Icon(Icons.cake_outlined),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _handleJoin();
              },
              child: const Text('가입하기'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, AppRoutes.main);
            }
          },
        ),
        title: const Text('초대 링크', style: AppTextStyles.h3),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildError()
                : _buildPreview(),
      ),
    );
  }

  // ── 에러 뷰 ──────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link_off_rounded, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: AppTextStyles.body1.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _loadPreview,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  // ── 미리보기 뷰 ───────────────────────────────────────────
  Widget _buildPreview() {
    // v2.8: flat 구조 (group 중첩 없음)
    final groupName = _previewData?['group_name'] as String? ?? '알 수 없는 그룹';
    final description = '';   // v2.8 응답에 미포함
    final memberCount = 0;    // v2.8 응답에 미포함
    final purpose = '';       // v2.8 응답에 미포함
    final expiresAt = _previewData?['expires_at'] as String?;
    final maxUses = _previewData?['max_uses'] as int?;
    final useCount = _previewData?['used_count'] as int? ?? 0;  // use_count → used_count
    final label = _previewData?['label'] as String? ?? '초대';

    final auth = context.watch<AuthProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 초대 배너
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.primary.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.group_add_rounded,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$label로 초대받으셨습니다',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  groupName,
                  style: AppTextStyles.h2,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 그룹 정보 카드
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('그룹 정보', style: AppTextStyles.caption),
                const SizedBox(height: 12),
                if (description.isNotEmpty) ...[
                  _InfoRow(
                    icon: Icons.info_outline_rounded,
                    label: '설명',
                    value: description,
                  ),
                  const SizedBox(height: 8),
                ],
                if (purpose.isNotEmpty) ...[
                  _InfoRow(
                    icon: Icons.category_outlined,
                    label: '목적',
                    value: _purposeLabel(purpose),
                  ),
                  const SizedBox(height: 8),
                ],
                _InfoRow(
                  icon: Icons.people_outline_rounded,
                  label: '멤버 수',
                  value: '$memberCount명',
                ),
                if (maxUses != null) ...[
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.confirmation_num_outlined,
                    label: '초대 사용',
                    value: '$useCount / $maxUses회',
                  ),
                ],
                if (expiresAt != null) ...[
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.schedule_rounded,
                    label: '만료일',
                    value: _formatDate(expiresAt),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 로그인 상태 안내
          if (!auth.isAuthenticated)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_rounded,
                      size: 18, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '로그인 후 그룹에 가입할 수 있습니다.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // 가입 버튼
          LoadingButton(
            isLoading: _isJoining,
            onPressed: () {
              if (!auth.isAuthenticated) {
                // 비로그인 → 토큰 저장 후 즉시 로그인 다이얼로그
                _savePendingToken(widget.token).then((_) {
                  if (mounted) _showLoginRequiredDialog();
                });
              } else {
                // 로그인 상태 → birth_date 바텀시트
                _showBirthDateSheet();
              }
            },
            child: Text(
              auth.isAuthenticated ? '그룹 가입하기' : '로그인하고 가입하기',
            ),
          ),

          const SizedBox(height: 12),

          // 취소 버튼
          TextButton(
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, AppRoutes.main);
              }
            },
            child: const Text('나중에 하기'),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _purposeLabel(String purpose) {
    const labels = {
      'study': '스터디',
      'business': '비즈니스',
      'hobby': '취미',
      'networking': '네트워킹',
      'social': '친목',
    };
    return labels[purpose] ?? purpose;
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

// ── 정보 행 위젯 ──────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(value, style: AppTextStyles.caption),
        ),
      ],
    );
  }
}

// ── 로딩 버튼 위젯 ────────────────────────────────────────────
class LoadingButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final Widget child;
  const LoadingButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : child,
    );
  }
}
