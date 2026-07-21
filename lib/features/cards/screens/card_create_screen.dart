import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/cards_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../routes/app_router.dart';
import '../widgets/business_card_widget.dart';
import '../widgets/card_template_styles.dart';
import '../models/card_model.dart';

// ── 이력 태그 유형 (v1.7 스펙: career·education — 공개 명함 뷰어에서 섹션으로 표시) ──
const Map<String, String> _resumeTypes = {
  'career': '경력',
  'education': '학력',
};

// ── SNS 플랫폼 목록 ─────────────────────────────────────
const _snsPlatforms = [
  'Instagram',
  'LinkedIn',
  'GitHub',
  'Twitter/X',
  'Facebook',
  'YouTube',
  'TikTok',
  'Blog',
  'Kakao',
  'Other',
];

class CardCreateScreen extends StatefulWidget {
  final CardModel? existingCard;
  const CardCreateScreen({super.key, this.existingCard});

  @override
  State<CardCreateScreen> createState() => _CardCreateScreenState();
}

class _CardCreateScreenState extends State<CardCreateScreen>
    with SingleTickerProviderStateMixin {
  // ── 탭 ──────────────────────────────────────────────────
  late final TabController _tabCtrl;

  // ── 기본 정보 폼 컨트롤러 ────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _titleCtrl   = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _bioCtrl     = TextEditingController();

  String _selectedTemplate = 'default'; // 브랜드 기본: 엘리드(네이비×골드)
  String _selectedDesign   = 'classic'; // 레이아웃 디자인 (classic/center/leftbar)
  bool   _isPublic         = true; // 공개 명함이 기본 (QR/링크 공유 가능)

  // ── 명함 사진 (avatar) ──────────────────────────────────
  String? _pendingAvatarPath; // 로컬 선택 경로 (미업로드)

  // ── 태그 목록 — tags[] ──────────────────────────────────
  final List<CardTag> _tags = [];

  // ── SNS 링크 목록 — sns_links[] ─────────────────────────
  final List<SnsLink> _snsLinks = [];

  bool get _isEditing => widget.existingCard != null;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);

    if (_isEditing) {
      final c = widget.existingCard!;
      _nameCtrl.text    = c.name;
      _titleCtrl.text   = c.title    ?? '';
      _companyCtrl.text = c.company  ?? '';
      _emailCtrl.text   = c.email    ?? '';
      _phoneCtrl.text   = c.phone    ?? '';
      _websiteCtrl.text = c.website  ?? '';
      _bioCtrl.text     = c.bio      ?? '';
      _selectedTemplate = cardPaletteIdOf(c.templateId);
      _selectedDesign   = cardDesignIdOf(c.templateId);
      _isPublic         = c.isPublic == 1;
      _tags.addAll(c.tags);
      _snsLinks.addAll(c.snsLinks);
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _titleCtrl.dispose();
    _companyCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _websiteCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  // ── 미리보기용 CardModel ────────────────────────────────
  CardModel get _previewCard => CardModel(
        id: 0,
        userId: 0,
        name: _nameCtrl.text.isEmpty ? '홍길동' : _nameCtrl.text,
        title: _titleCtrl.text.isEmpty ? null : _titleCtrl.text,
        company: _companyCtrl.text.isEmpty ? null : _companyCtrl.text,
        email: _emailCtrl.text.isEmpty ? null : _emailCtrl.text,
        phone: _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text,
        bio: _bioCtrl.text.isEmpty ? null : _bioCtrl.text,
        cardType: 'personal',
        templateId: composeTemplateId(_selectedTemplate, _selectedDesign),
        isPrimary: 0,
        isPublic: _isPublic ? 1 : 0,
        isActive: 1,
        snsLinks: List.from(_snsLinks),
        tags: List.from(_tags),
      );

  // ── 저장 ────────────────────────────────────────────────
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      // 유효성 오류가 탭 1에 있으면 탭 1로 이동
      _tabCtrl.animateTo(0);
      return;
    }

    final provider = context.read<CardsProvider>();
    final data = <String, dynamic>{
      'name':        _nameCtrl.text.trim(),
      if (_titleCtrl.text.isNotEmpty)   'title':   _titleCtrl.text.trim(),
      if (_companyCtrl.text.isNotEmpty) 'company': _companyCtrl.text.trim(),
      if (_emailCtrl.text.isNotEmpty)   'email':   _emailCtrl.text.trim(),
      if (_phoneCtrl.text.isNotEmpty)   'phone':   _phoneCtrl.text.trim(),
      if (_websiteCtrl.text.isNotEmpty) 'website': _websiteCtrl.text.trim(),
      if (_bioCtrl.text.isNotEmpty)     'bio':     _bioCtrl.text.trim(),
      'template_id': composeTemplateId(_selectedTemplate, _selectedDesign),
      'is_public':   _isPublic ? 1 : 0,
      // v2.9: full-replace 방식
      'tags':      _tags.map((t) => t.toJson()).toList(),
      'sns_links': _snsLinks.map((s) => s.toJson()).toList(),
    };

    bool success;
    int? createdCardId;

    if (_isEditing) {
      success = await provider.updateCard(widget.existingCard!.id, data);
      createdCardId = widget.existingCard!.id;
    } else {
      final result = await provider.createCard(data);
      success = result != null;
      createdCardId = result?.id;
    }

    if (!mounted) return;

    if (success) {
      // 명함 사진 업로드 (선택한 경우)
      if (_pendingAvatarPath != null && createdCardId != null) {
        await provider.uploadCardAvatar(createdCardId, _pendingAvatarPath!);
      }
      if (!mounted) return;
      final msg = _isEditing ? '명함이 수정되었습니다.' : '명함이 생성되었습니다.';
      showSuccessSnackBar(context, msg);
      Navigator.pop(context, true);
    } else {
      if (provider.upgradeRequired &&
          provider.errorCode == 'card_limit_exceeded') {
        _showCardLimitDialog(provider.errorMessage ?? '명함 생성 한도를 초과했습니다.');
      } else {
        showErrorSnackBar(context, provider.errorMessage ?? '저장에 실패했습니다.');
      }
    }
  }

  // ── 명함 한도 초과 다이얼로그 ────────────────────────────
  void _showCardLimitDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Text('📋', style: TextStyle(fontSize: 20)),
          SizedBox(width: 8),
          Text('명함 한도 초과'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('플랜 업그레이드 혜택',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  SizedBox(height: 6),
                  Text('• Free → Pro: 최대 10개 명함',
                      style: TextStyle(fontSize: 12)),
                  Text('• Pro → Business: 무제한 명함',
                      style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('나중에'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, AppRoutes.upgrade, arguments: {
                'fromContext':
                    'Free 플랜은 명함을 최대 3장까지 만들 수 있습니다. 더 많은 명함을 원하시면 업그레이드하세요.',
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('플랜 업그레이드'),
          ),
        ],
      ),
    );
  }

  // ── 명함 사진 선택 ───────────────────────────────────────
  Future<void> _pickCardAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _pendingAvatarPath = picked.path);
    }
  }

  // ── 이력 추가 다이얼로그 ─────────────────────────────────
  // 이력 = tag_type이 career/education인 태그
  // 기간은 tag_period 필드로 분리 전송 (서버 마이그레이션 0026)
  void _showAddCareerDialog({int? editIndex}) {
    final existing = editIndex != null ? _tags[editIndex] : null;
    final valueCtrl = TextEditingController(text: existing?.tagValue ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CareerInputSheet(
        initialType: existing?.tagType ?? 'career',
        initialPeriod: existing?.tagPeriod ?? '',
        valueCtrl: valueCtrl,
        isEdit: editIndex != null,
        onSave: (type, value, period) {
          setState(() {
            final tag = CardTag(
              tagType: type,
              tagValue: value,
              tagPeriod: period.isEmpty ? null : period,
            );
            if (editIndex != null) {
              _tags[editIndex] = tag;
            } else {
              _tags.add(tag);
            }
          });
        },
      ),
    );
  }

  // ── 태그 추가 다이얼로그 ─────────────────────────────────
  void _showAddTagDialog({int? editIndex}) {
    final typeCtrl = TextEditingController(
      text: editIndex != null ? _tags[editIndex].tagType : '',
    );
    final valueCtrl = TextEditingController(
      text: editIndex != null ? _tags[editIndex].tagValue : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TagInputSheet(
        typeCtrl: typeCtrl,
        valueCtrl: valueCtrl,
        isEdit: editIndex != null,
        onSave: (type, value) {
          setState(() {
            final tag = CardTag(tagType: type, tagValue: value);
            if (editIndex != null) {
              _tags[editIndex] = tag;
            } else {
              _tags.add(tag);
            }
          });
        },
      ),
    );
  }

  // ── SNS 링크 추가 다이얼로그 ─────────────────────────────
  void _showAddSnsDialog({int? editIndex}) {
    String selectedPlatform =
        editIndex != null ? _snsLinks[editIndex].platform : _snsPlatforms[0];
    final urlCtrl = TextEditingController(
      text: editIndex != null ? _snsLinks[editIndex].url : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SnsInputSheet(
        initialPlatform: selectedPlatform,
        urlCtrl: urlCtrl,
        isEdit: editIndex != null,
        onSave: (platform, url) {
          setState(() {
            final link = SnsLink(
              platform: platform,
              url: url,
              sortOrder: editIndex ?? _snsLinks.length,
            );
            if (editIndex != null) {
              _snsLinks[editIndex] = link;
            } else {
              _snsLinks.add(link);
            }
          });
        },
      ),
    );
  }

  // ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '명함 수정' : '명함 만들기'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: '기본 정보'),
            Tab(text: '이력 · 태그 · SNS'),
          ],
        ),
        actions: [
          TextButton(
            onPressed:
                context.watch<CardsProvider>().isLoading ? null : _handleSave,
            child: Text(
              '저장',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Consumer<CardsProvider>(
        builder: (context, provider, _) => LoadingOverlay(
          isLoading: provider.isLoading,
          child: Form(
            key: _formKey,
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildTab1(),
                _buildTab2(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // 탭 1: 기본 정보
  // ════════════════════════════════════════════════════════
  Widget _buildTab1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 명함 미리보기
          const Text('미리보기', style: AppTextStyles.label),
          const SizedBox(height: 8),
          BusinessCardWidget(card: _previewCard),
          const SizedBox(height: 24),

          // ── 명함 사진 (avatar)
          const Text('명함 사진', style: AppTextStyles.label),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickCardAvatar,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _pendingAvatarPath != null
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _pendingAvatarPath != null
                        ? Icons.check_circle_outline
                        : Icons.add_photo_alternate_outlined,
                    color: _pendingAvatarPath != null
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _pendingAvatarPath != null ? '사진 선택됨 (저장 시 업로드)' : '사진 추가',
                    style: TextStyle(
                      color: _pendingAvatarPath != null
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── 템플릿 선택
          const Text('템플릿', style: AppTextStyles.label),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kCardTemplateStyles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final tmpl = kCardTemplateStyles[i];
                final isSelected = _selectedTemplate == tmpl.id;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedTemplate = tmpl.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        // 2컬러 스와치 (그라데이션 + 악센트 도트)
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            gradient: tmpl.gradient,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 1.5,
                            ),
                          ),
                          child: Align(
                            alignment: const Alignment(0.5, 0.5),
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: tmpl.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          tmpl.name,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // ── 디자인(레이아웃) 선택
          const Text('디자인', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Row(
            children: kCardDesigns.map((d) {
              final isSelected = _selectedDesign == d.id;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDesign = d.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(
                        right: d.id == kCardDesigns.last.id ? 0 : 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          d.icon,
                          size: 22,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          d.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // ── 기본 정보
          const Text('기본 정보', style: AppTextStyles.h4),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameCtrl,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '이름 *',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? '이름을 입력해주세요' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _titleCtrl,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '직책',
              prefixIcon: Icon(Icons.work_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _companyCtrl,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '회사명',
              prefixIcon: Icon(Icons.business_outlined),
            ),
          ),
          const SizedBox(height: 28),

          // ── 연락처
          const Text('연락처', style: AppTextStyles.h4),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailCtrl,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '이메일',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneCtrl,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '전화번호',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _websiteCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '웹사이트',
              prefixIcon: Icon(Icons.language_outlined),
              hintText: 'https://',
            ),
          ),
          const SizedBox(height: 28),

          // ── 자기소개
          const Text('자기소개', style: AppTextStyles.h4),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bioCtrl,
            onChanged: (_) => setState(() {}),
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: '자기소개',
              hintText: '간단한 자기소개를 작성해보세요.',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),

          // ── 공개 설정
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.public,
                        size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('공개 명함', style: AppTextStyles.body1),
                        Text(
                          _isPublic ? 'QR 코드로 공유 가능' : '비공개 상태',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),
                Switch(
                  value: _isPublic,
                  onChanged: (v) => setState(() => _isPublic = v),
                  activeThumbColor: AppColors.primary,
                  activeTrackColor:
                      AppColors.primary.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 이력·태그·SNS 입력으로 이동
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _tabCtrl.animateTo(1),
              icon: const Icon(Icons.history_edu_outlined, size: 18),
              label: const Text('이력 · 태그 · SNS 추가'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.4)),
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: context.read<CardsProvider>().isLoading
                  ? null
                  : _handleSave,
              child: Text(_isEditing ? '수정 완료' : '명함 생성'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // 탭 2: 이력 · 태그 · SNS
  // ════════════════════════════════════════════════════════
  Widget _buildTab2() {
    // 이력(경력/학력) 태그와 일반 태그 분리 — 원본 _tags 인덱스 유지
    final resumeEntries = _tags
        .asMap()
        .entries
        .where((e) => _resumeTypes.containsKey(e.value.tagType))
        .toList();
    final plainTagEntries = _tags
        .asMap()
        .entries
        .where((e) => !_resumeTypes.containsKey(e.value.tagType))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 이력 섹션 (경력/학력 — 개수 제한 없음)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('이력', style: AppTextStyles.h4),
              TextButton.icon(
                onPressed: () => _showAddCareerDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('추가'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
          Text(
            '경력·학력을 추가하세요. 공유된 명함의 상세 이력에 표시됩니다.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 12),

          if (resumeEntries.isEmpty)
            _EmptyHint(
              icon: Icons.history_edu_outlined,
              text: '아직 이력이 없습니다.\n+ 추가 버튼을 눌러 경력·학력을 추가하세요.',
            )
          else
            Column(
              children: resumeEntries.map((entry) {
                final i = entry.key;
                final tag = entry.value;
                final isCareer = tag.tagType == 'career';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 2),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isCareer
                            ? Icons.work_outline
                            : Icons.school_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(tag.tagValue, style: AppTextStyles.body1),
                    subtitle: Text(
                      [
                        _resumeTypes[tag.tagType]!,
                        if (tag.tagPeriod != null && tag.tagPeriod!.isNotEmpty)
                          tag.tagPeriod!,
                      ].join(' · '),
                      style: AppTextStyles.caption,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              size: 18, color: AppColors.textSecondary),
                          onPressed: () =>
                              _showAddCareerDialog(editIndex: i),
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Colors.red),
                          onPressed: () =>
                              setState(() => _tags.removeAt(i)),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 28),

          // ── 태그 섹션
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('태그', style: AppTextStyles.h4),
              TextButton.icon(
                onPressed: () => _showAddTagDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('추가'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
          Text(
            '전문 분야, 관심사, 키워드 등을 태그로 추가하세요.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 12),

          if (plainTagEntries.isEmpty)
            _EmptyHint(
              icon: Icons.label_outline,
              text: '아직 태그가 없습니다.\n+ 추가 버튼을 눌러 태그를 추가하세요.',
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: plainTagEntries.map((entry) {
                final i = entry.key;
                final tag = entry.value;
                return Chip(
                  label: Text(
                    tag.tagValue.isNotEmpty
                        ? tag.tagValue
                        : tag.tagType,
                    style: const TextStyle(fontSize: 13),
                  ),
                  avatar: tag.tagType.isNotEmpty && tag.tagValue.isNotEmpty
                      ? Text(
                          tag.tagType[0].toUpperCase(),
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700),
                        )
                      : null,
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => setState(() => _tags.removeAt(i)),
                  backgroundColor:
                      AppColors.primary.withValues(alpha: 0.08),
                  side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.25)),
                  labelStyle: TextStyle(color: AppColors.primary),
                );
              }).toList(),
            ),
          const SizedBox(height: 28),

          // ── SNS 링크 섹션
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('SNS 링크', style: AppTextStyles.h4),
              TextButton.icon(
                onPressed: () => _showAddSnsDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('추가'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
          Text(
            'SNS, 포트폴리오, 블로그 등의 링크를 추가하세요.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 12),

          if (_snsLinks.isEmpty)
            _EmptyHint(
              icon: Icons.link_outlined,
              text: '아직 SNS 링크가 없습니다.\n+ 추가 버튼을 눌러 링크를 추가하세요.',
            )
          else
            Column(
              children: _snsLinks.asMap().entries.map((entry) {
                final i = entry.key;
                final sns = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    leading: _SnsIcon(platform: sns.platform),
                    title: Text(sns.platform, style: AppTextStyles.body1),
                    subtitle: Text(
                      sns.url,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              size: 18, color: AppColors.textSecondary),
                          onPressed: () => _showAddSnsDialog(editIndex: i),
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Colors.red),
                          onPressed: () =>
                              setState(() => _snsLinks.removeAt(i)),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 이력 입력 바텀시트 (경력/학력)
// ════════════════════════════════════════════════════════════
class _CareerInputSheet extends StatefulWidget {
  final String initialType;
  final String initialPeriod;
  final TextEditingController valueCtrl;
  final bool isEdit;
  final void Function(String type, String value, String period) onSave;

  const _CareerInputSheet({
    required this.initialType,
    required this.initialPeriod,
    required this.valueCtrl,
    required this.isEdit,
    required this.onSave,
  });

  @override
  State<_CareerInputSheet> createState() => _CareerInputSheetState();
}

class _CareerInputSheetState extends State<_CareerInputSheet> {
  late String _type;
  late final TextEditingController _periodCtrl;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _periodCtrl = TextEditingController(text: widget.initialPeriod);
  }

  @override
  void dispose() {
    _periodCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final v = widget.valueCtrl.text.trim();
    if (v.isEmpty) return;
    // 기간은 tag_value에 병합하지 않고 tag_period로 분리 전송
    widget.onSave(_type, v, _periodCtrl.text.trim());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isCareer = _type == 'career';
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 핸들
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(widget.isEdit ? '이력 수정' : '이력 추가', style: AppTextStyles.h3),
          const SizedBox(height: 6),
          Text(
            '경력·학력을 입력하세요. 개수 제한이 없습니다.',
            style: AppTextStyles.body2,
          ),
          const SizedBox(height: 20),

          // 유형 선택
          Row(
            children: _resumeTypes.entries.map((e) {
              final selected = _type == e.key;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(e.value),
                  selected: selected,
                  onSelected: (_) => setState(() => _type = e.key),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: widget.valueCtrl,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: '내용 *',
              hintText: isCareer
                  ? '예) ELID Corp · 시니어 개발자'
                  : '예) 서울대학교 경영학과 졸업',
              prefixIcon: Icon(
                isCareer ? Icons.work_outline : Icons.school_outlined,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _periodCtrl,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: '기간 (선택)',
              hintText: '예) 2024 ~ 현재',
              prefixIcon: Icon(Icons.calendar_today_outlined),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submit,
            child: Text(widget.isEdit ? '수정 완료' : '추가하기'),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 태그 입력 바텀시트
// ════════════════════════════════════════════════════════════
class _TagInputSheet extends StatelessWidget {
  final TextEditingController typeCtrl;
  final TextEditingController valueCtrl;
  final bool isEdit;
  final void Function(String type, String value) onSave;

  const _TagInputSheet({
    required this.typeCtrl,
    required this.valueCtrl,
    required this.isEdit,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 핸들
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(isEdit ? '태그 수정' : '태그 추가', style: AppTextStyles.h3),
          const SizedBox(height: 6),
          Text(
            '유형(예: 전문분야)과 값(예: UX디자인)을 입력하세요.',
            style: AppTextStyles.body2,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: typeCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '태그 유형',
              hintText: '예) 전문분야, 관심사, 자격증',
              prefixIcon: Icon(Icons.category_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: valueCtrl,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: '태그 값 *',
              hintText: '예) UX디자인, Flutter, AWS',
              prefixIcon: Icon(Icons.label_outline),
            ),
            onSubmitted: (_) {
              final v = valueCtrl.text.trim();
              if (v.isEmpty) return;
              onSave(typeCtrl.text.trim(), v);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final v = valueCtrl.text.trim();
              if (v.isEmpty) return;
              onSave(typeCtrl.text.trim(), v);
              Navigator.pop(context);
            },
            child: Text(isEdit ? '수정 완료' : '추가'),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// SNS 입력 바텀시트
// ════════════════════════════════════════════════════════════
class _SnsInputSheet extends StatefulWidget {
  final String initialPlatform;
  final TextEditingController urlCtrl;
  final bool isEdit;
  final void Function(String platform, String url) onSave;

  const _SnsInputSheet({
    required this.initialPlatform,
    required this.urlCtrl,
    required this.isEdit,
    required this.onSave,
  });

  @override
  State<_SnsInputSheet> createState() => _SnsInputSheetState();
}

class _SnsInputSheetState extends State<_SnsInputSheet> {
  late String _platform;

  @override
  void initState() {
    super.initState();
    _platform = widget.initialPlatform;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 핸들
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(widget.isEdit ? 'SNS 수정' : 'SNS 추가', style: AppTextStyles.h3),
          const SizedBox(height: 20),

          // 플랫폼 선택
          const Text('플랫폼', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _snsPlatforms.map((p) {
              final selected = p == _platform;
              return GestureDetector(
                onTap: () => setState(() => _platform = p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    p,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // URL 입력
          TextField(
            controller: widget.urlCtrl,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: '$_platform URL',
              hintText: 'https://',
              prefixIcon: const Icon(Icons.link),
            ),
            onSubmitted: (_) {
              final url = widget.urlCtrl.text.trim();
              if (url.isEmpty) return;
              widget.onSave(_platform, url);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: () {
              final url = widget.urlCtrl.text.trim();
              if (url.isEmpty) return;
              widget.onSave(_platform, url);
              Navigator.pop(context);
            },
            child: Text(widget.isEdit ? '수정 완료' : '추가'),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// SNS 아이콘 위젯
// ════════════════════════════════════════════════════════════
class _SnsIcon extends StatelessWidget {
  final String platform;
  const _SnsIcon({required this.platform});

  @override
  Widget build(BuildContext context) {
    final icon = _iconFor(platform);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: AppColors.primary),
    );
  }

  IconData _iconFor(String p) {
    switch (p.toLowerCase()) {
      case 'instagram':   return Icons.camera_alt_outlined;
      case 'linkedin':    return Icons.business_center_outlined;
      case 'github':      return Icons.code_outlined;
      case 'twitter/x':  return Icons.flutter_dash;
      case 'facebook':    return Icons.facebook_outlined;
      case 'youtube':     return Icons.play_circle_outline;
      case 'tiktok':      return Icons.music_video_outlined;
      case 'blog':        return Icons.article_outlined;
      case 'kakao':       return Icons.chat_bubble_outline;
      default:            return Icons.link;
    }
  }
}

// ════════════════════════════════════════════════════════════
// 빈 힌트 위젯
// ════════════════════════════════════════════════════════════
class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyHint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: AppTextStyles.body2),
          ),
        ],
      ),
    );
  }
}
