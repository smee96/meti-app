// public_card_screen.dart — 공개 명함 뷰어
// API: GET /cards/public/:id (인증 불필요)
//      POST /cards/:id/save (명함첩 저장, 인증 필요)
// v1.7 스펙: 이력 태그(career·education·skill·keyword), SNS 링크, 아바타 표시

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../models/card_model.dart';
import '../widgets/card_template_styles.dart';

class PublicCardScreen extends StatefulWidget {
  final int cardId;

  const PublicCardScreen({super.key, required this.cardId});

  @override
  State<PublicCardScreen> createState() => _PublicCardScreenState();
}

class _PublicCardScreenState extends State<PublicCardScreen> {
  final ApiClient _api = ApiClient();

  CardModel? _card;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _saved = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCard();
  }

  Future<void> _loadCard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _api.get('/cards/public/${widget.cardId}', auth: false);
      if (res['success'] == true) {
        setState(() {
          _card = CardModel.fromJson(res['data'] as Map<String, dynamic>);
        });
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = '명함을 불러오지 못했습니다.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCard() async {
    if (_saved || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      final res = await _api.post('/cards/${widget.cardId}/save');
      if (res['success'] == true && mounted) {
        setState(() => _saved = true);
        showSuccessSnackBar(context, '명함첩에 저장되었습니다.');
      }
    } on ApiException catch (e) {
      if (mounted) showErrorSnackBar(context, e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    showSuccessSnackBar(context, '$label이(가) 복사되었습니다.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('명함 보기'),
        actions: [
          if (_card != null)
            _isSaving
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      _saved ? Icons.bookmark : Icons.bookmark_border_outlined,
                      color: _saved ? AppColors.primary : null,
                    ),
                    tooltip: '명함첩에 저장',
                    onPressed: _saveCard,
                  ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(_error!,
                  style: AppTextStyles.body1, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadCard,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }
    if (_card == null) return const SizedBox.shrink();

    final card = _card!;

    // 태그 분류
    final careers = card.tags.where((t) => t.tagType == 'career').toList();
    final education = card.tags.where((t) => t.tagType == 'education').toList();
    final skills = card.tags.where((t) => t.tagType == 'skill').toList();
    final keywords = card.tags.where((t) => t.tagType == 'keyword').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 헤더 배너 (아바타 + 이름 + 직책) ──────────────────
          _buildHeader(card),

          // ── 연락처 정보 ────────────────────────────────────────
          if (card.email != null || card.phone != null || card.website != null)
            _buildContactSection(card),

          // ── 소개 ───────────────────────────────────────────────
          if (card.bio != null && card.bio!.isNotEmpty)
            _buildSection(
              title: '소개',
              child: Text(card.bio!, style: AppTextStyles.body1),
            ),

          // ── 상세 이력 (2뎁스 진입) ─────────────────────────────
          // 1뎁스는 기본 명함만 보여주고, 경력·학력·스킬·키워드는 상세 화면으로 분리
          if (careers.isNotEmpty ||
              education.isNotEmpty ||
              skills.isNotEmpty ||
              keywords.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.history_edu_outlined,
                        color: AppColors.primary),
                  ),
                  title: const Text('상세 이력', style: AppTextStyles.body1),
                  subtitle: Text(
                    [
                      if (careers.isNotEmpty) '경력 ${careers.length}',
                      if (education.isNotEmpty) '학력 ${education.length}',
                      if (skills.isNotEmpty) '스킬 ${skills.length}',
                      if (keywords.isNotEmpty) '키워드 ${keywords.length}',
                    ].join(' · '),
                    style: AppTextStyles.caption,
                  ),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.textTertiary),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CardResumeScreen(card: card),
                    ),
                  ),
                ),
              ),
            ),

          // ── SNS 링크 ───────────────────────────────────────────
          if (card.snsLinks.isNotEmpty)
            _buildSection(
              title: 'SNS / 링크',
              child: Column(
                children: card.snsLinks.map((s) => _buildSnsRow(s)).toList(),
              ),
            ),

          const SizedBox(height: 24),

          // ── 명함첩 저장 버튼 ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ElevatedButton.icon(
              onPressed: _saved ? null : _saveCard,
              icon: Icon(_saved ? Icons.check : Icons.bookmark_add_outlined),
              label: Text(_saved ? '저장됨' : '명함첩에 저장'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 헤더 ─────────────────────────────────────────────────────
  // 명함의 템플릿 컬러(2컬러 그라데이션 + 악센트)를 그대로 사용
  Widget _buildHeader(CardModel card) {
    final style = cardTemplateStyle(card.templateId);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
      decoration: BoxDecoration(gradient: style.gradient),
      child: Column(
        children: [
          // 아바타
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: style.accent.withValues(alpha: 0.6), width: 3),
              color:
                  style.accent.withValues(alpha: style.isLight ? 0.10 : 0.18),
            ),
            child: card.avatarUrl != null && card.avatarUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      card.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _avatarInitial(card.name, style),
                    ),
                  )
                : _avatarInitial(card.name, style),
          ),
          const SizedBox(height: 16),

          // 이름
          Text(
            card.name,
            style: TextStyle(
              color: style.textColor,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),

          // 직책 / 소속
          if (card.title != null || card.company != null) ...[
            const SizedBox(height: 6),
            Text(
              [card.title, card.company].whereType<String>().join(' · '),
              style: TextStyle(
                color: style.subColor,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _avatarInitial(String name, CardTemplateStyle style) {
    final initial = name.isNotEmpty ? name[0] : '?';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: style.isLight ? style.accent : style.textColor,
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ── 연락처 섹션 ───────────────────────────────────────────────
  Widget _buildContactSection(CardModel card) {
    return _buildSection(
      title: '연락처',
      child: Column(
        children: [
          if (card.email != null)
            _buildContactRow(
              Icons.email_outlined,
              card.email!,
              onTap: () => _launchUrl('mailto:${card.email}'),
              onLongPress: () => _copyToClipboard(card.email!, '이메일'),
            ),
          if (card.phone != null)
            _buildContactRow(
              Icons.phone_outlined,
              card.phone!,
              onTap: () => _launchUrl('tel:${card.phone}'),
              onLongPress: () => _copyToClipboard(card.phone!, '전화번호'),
            ),
          if (card.website != null)
            _buildContactRow(
              Icons.language_outlined,
              card.website!,
              onTap: () => _launchUrl(card.website!),
              onLongPress: () => _copyToClipboard(card.website!, '웹사이트'),
            ),
        ],
      ),
    );
  }

  Widget _buildContactRow(
    IconData icon,
    String value, {
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: AppTextStyles.body1.copyWith(color: AppColors.primary),
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 16, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildSnsRow(SnsLink sns) {
    final info = _snsInfo(sns.platform);
    return InkWell(
      onTap: () => _launchUrl(sns.url),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: info.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(info.icon, size: 18, color: info.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(info.label, style: AppTextStyles.caption),
                  Text(
                    sns.url,
                    style:
                        AppTextStyles.body2.copyWith(color: AppColors.primary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new,
                size: 14, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  // BUG-AOS-001: 생성 화면은 'Instagram'처럼 첫 글자 대문자로 저장하므로
  // 소문자로 정규화해 매칭 (card_detail의 _SnsDetailIcon과 동일 정책)
  _SnsInfo _snsInfo(String platform) {
    switch (platform.toLowerCase()) {
      case 'linkedin':
        return _SnsInfo('LinkedIn', Icons.business_center_outlined,
            const Color(0xFF0077B5));
      case 'github':
        return _SnsInfo('GitHub', Icons.code, const Color(0xFF333333));
      case 'instagram':
        return _SnsInfo(
            'Instagram', Icons.photo_camera_outlined, const Color(0xFFE1306C));
      case 'twitter':
      case 'twitter/x':
        return _SnsInfo(
            'Twitter / X', Icons.alternate_email, const Color(0xFF1DA1F2));
      case 'facebook':
        return _SnsInfo(
            'Facebook', Icons.facebook_outlined, const Color(0xFF1877F2));
      case 'youtube':
        return _SnsInfo(
            'YouTube', Icons.play_circle_outline, const Color(0xFFFF0000));
      case 'tiktok':
        return _SnsInfo(
            'TikTok', Icons.music_video_outlined, const Color(0xFF333333));
      case 'kakao':
        return _SnsInfo(
            '카카오', Icons.chat_bubble_outline, const Color(0xFFC9A800));
      case 'blog':
        return _SnsInfo('블로그', Icons.article_outlined, AppColors.accent);
      case 'website':
        return _SnsInfo('웹사이트', Icons.language_outlined, AppColors.accent);
      default:
        return _SnsInfo(platform, Icons.link, AppColors.textSecondary);
    }
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SnsInfo {
  final String label;
  final IconData icon;
  final Color color;
  const _SnsInfo(this.label, this.icon, this.color);
}

// ════════════════════════════════════════════════════════════
// 상세 이력 화면 (공개 명함 2뎁스)
// 경력 · 학력 · 스킬 · 키워드를 섹션별로 표시
// ════════════════════════════════════════════════════════════
class CardResumeScreen extends StatelessWidget {
  final CardModel card;

  const CardResumeScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final style = cardTemplateStyle(card.templateId);
    final careers = card.tags.where((t) => t.tagType == 'career').toList();
    final education = card.tags.where((t) => t.tagType == 'education').toList();
    final skills = card.tags.where((t) => t.tagType == 'skill').toList();
    final keywords = card.tags.where((t) => t.tagType == 'keyword').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('상세 이력')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 미니 헤더 (이름 + 직책)
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              decoration: BoxDecoration(gradient: style.gradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name,
                    style: TextStyle(
                      color: style.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (card.title != null || card.company != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      [card.title, card.company]
                          .whereType<String>()
                          .join(' · '),
                      style: TextStyle(color: style.subColor, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),

            if (careers.isNotEmpty)
              _section(
                title: '경력',
                child: Column(
                  children: careers
                      .map((t) => _listItem(Icons.work_outline, t.tagValue,
                          period: t.tagPeriod))
                      .toList(),
                ),
              ),

            if (education.isNotEmpty)
              _section(
                title: '학력',
                child: Column(
                  children: education
                      .map((t) => _listItem(Icons.school_outlined, t.tagValue,
                          period: t.tagPeriod))
                      .toList(),
                ),
              ),

            if (skills.isNotEmpty)
              _section(
                title: '스킬',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills
                      .map((t) => _chip(t.tagValue, AppColors.primary))
                      .toList(),
                ),
              ),

            if (keywords.isNotEmpty)
              _section(
                title: '키워드',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: keywords
                      .map((t) => _chip(t.tagValue, AppColors.accent))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // 기간(tag_period)은 웹 공유 페이지와 동일하게 오른쪽에 분리 표시
  Widget _listItem(IconData icon, String value, {String? period}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(child: Text(value, style: AppTextStyles.body1)),
          if (period != null && period.isNotEmpty) ...[
            const SizedBox(width: 10),
            Text(period, style: AppTextStyles.caption),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
