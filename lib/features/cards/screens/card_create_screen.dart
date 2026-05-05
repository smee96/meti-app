import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cards_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/constants/app_constants.dart';
import '../widgets/business_card_widget.dart';
import '../models/card_model.dart';

class CardCreateScreen extends StatefulWidget {
  final CardModel? existingCard;
  const CardCreateScreen({super.key, this.existingCard});

  @override
  State<CardCreateScreen> createState() => _CardCreateScreenState();
}

class _CardCreateScreenState extends State<CardCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  String _selectedTemplate = 'modern_blue';
  bool _isPublic = false; // v2.2: 기본값 비공개(0)

  // 경력/약력 목록 (최대 10개)
  final List<CareerItem> _careers = [];
  static const int _maxCareers = 10;

  bool get _isEditing => widget.existingCard != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final c = widget.existingCard!;
      _nameCtrl.text = c.name;
      _titleCtrl.text = c.title ?? '';
      _companyCtrl.text = c.company ?? '';
      _emailCtrl.text = c.email ?? '';
      _phoneCtrl.text = c.phone ?? '';
      _websiteCtrl.text = c.website ?? '';
      _bioCtrl.text = c.bio ?? '';
      _selectedTemplate = c.templateId;
      _isPublic = c.isPublic == 1;
      _careers.addAll(c.careers);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _titleCtrl.dispose();
    _companyCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _websiteCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

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
        templateId: _selectedTemplate,
        isPrimary: 0,
        isPublic: _isPublic ? 1 : 0,
        isActive: 1,
        careers: List.from(_careers),
      );

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<CardsProvider>();
    final data = {
      'name': _nameCtrl.text.trim(),
      if (_titleCtrl.text.isNotEmpty) 'title': _titleCtrl.text.trim(),
      if (_companyCtrl.text.isNotEmpty) 'company': _companyCtrl.text.trim(),
      if (_emailCtrl.text.isNotEmpty) 'email': _emailCtrl.text.trim(),
      if (_phoneCtrl.text.isNotEmpty) 'phone': _phoneCtrl.text.trim(),
      if (_websiteCtrl.text.isNotEmpty) 'website': _websiteCtrl.text.trim(),
      if (_bioCtrl.text.isNotEmpty) 'bio': _bioCtrl.text.trim(),
      'template_id': _selectedTemplate,
      'is_public': _isPublic ? 1 : 0,
      if (_careers.isNotEmpty)
        'careers': _careers.map((c) => c.toJson()).toList(),
    };

    bool success;
    if (_isEditing) {
      success = await provider.updateCard(widget.existingCard!.id, data);
    } else {
      final result = await provider.createCard(data);
      success = result != null;
    }

    if (!mounted) return;
    if (success) {
      showSuccessSnackBar(
          context, _isEditing ? '명함이 수정되었습니다.' : '명함이 생성되었습니다.');
      Navigator.pop(context, true);
    } else {
      showErrorSnackBar(context, provider.errorMessage ?? '저장에 실패했습니다.');
    }
  }

  // 경력 항목 추가 다이얼로그
  void _showAddCareerDialog({int? editIndex}) {
    final titleCtrl = TextEditingController(
      text: editIndex != null ? _careers[editIndex].title : '',
    );
    final periodCtrl = TextEditingController(
      text: editIndex != null ? (_careers[editIndex].period ?? '') : '',
    );
    final detailCtrl = TextEditingController(
      text: editIndex != null ? (_careers[editIndex].detail ?? '') : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
            Text(
              editIndex != null ? '약력 수정' : '약력 추가',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 6),
            Text(
              '학력, 경력, 자격증, 수상 등 자유롭게 입력하세요.',
              style: AppTextStyles.body2,
            ),
            const SizedBox(height: 20),

            // 타이틀 (필수)
            TextFormField(
              controller: titleCtrl,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '타이틀 *',
                hintText: '예) 서울대학교 경영학과, 삼성전자 부장',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 12),

            // 기간
            TextFormField(
              controller: periodCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '기간',
                hintText: '예) 2010 - 2014, 2015.03 ~ 현재',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
            ),
            const SizedBox(height: 12),

            // 상세
            TextFormField(
              controller: detailCtrl,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: '상세',
                hintText: '예) 졸업, 마케팅팀, 우수상',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              onFieldSubmitted: (_) {
                _saveCareer(ctx, editIndex, titleCtrl, periodCtrl, detailCtrl);
              },
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () {
                _saveCareer(ctx, editIndex, titleCtrl, periodCtrl, detailCtrl);
              },
              child: Text(editIndex != null ? '수정 완료' : '추가'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveCareer(
    BuildContext ctx,
    int? editIndex,
    TextEditingController titleCtrl,
    TextEditingController periodCtrl,
    TextEditingController detailCtrl,
  ) {
    if (titleCtrl.text.trim().isEmpty) return;
    final item = CareerItem(
      title: titleCtrl.text.trim(),
      period: periodCtrl.text.trim().isEmpty ? null : periodCtrl.text.trim(),
      detail: detailCtrl.text.trim().isEmpty ? null : detailCtrl.text.trim(),
    );
    setState(() {
      if (editIndex != null) {
        _careers[editIndex] = item;
      } else {
        _careers.add(item);
      }
    });
    Navigator.pop(ctx);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '명함 수정' : '명함 만들기'),
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
        builder: (context, provider, _) {
          return LoadingOverlay(
            isLoading: provider.isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 미리보기 ──────────────────────────
                    const Text('미리보기', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    BusinessCardWidget(card: _previewCard),
                    const SizedBox(height: 24),

                    // ── 템플릿 선택 ───────────────────────
                    const Text('템플릿', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: AppConstants.cardTemplates.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final tmpl = AppConstants.cardTemplates[i];
                          final isSelected = _selectedTemplate == tmpl['id'];
                          return GestureDetector(
                            onTap: () => setState(
                                () => _selectedTemplate = tmpl['id']!),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                              ),
                              child: Text(
                                tmpl['name']!,
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
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── 기본 정보 ─────────────────────────
                    const Text('기본 정보', style: AppTextStyles.h4),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameCtrl,
                      onChanged: (_) => setState(() {}),
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
                      decoration: const InputDecoration(
                        labelText: '직책',
                        prefixIcon: Icon(Icons.work_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _companyCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: '회사명',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── 연락처 ────────────────────────────
                    const Text('연락처', style: AppTextStyles.h4),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailCtrl,
                      onChanged: (_) => setState(() {}),
                      keyboardType: TextInputType.emailAddress,
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
                      decoration: const InputDecoration(
                        labelText: '전화번호',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _websiteCtrl,
                      decoration: const InputDecoration(
                        labelText: '웹사이트',
                        prefixIcon: Icon(Icons.language_outlined),
                        hintText: 'https://',
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── 약력/경력 ─────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('약력 / 경력', style: AppTextStyles.h4),
                        Row(
                          children: [
                            Text(
                              '${_careers.length}/$_maxCareers',
                              style: AppTextStyles.caption,
                            ),
                            const SizedBox(width: 8),
                            if (_careers.length < _maxCareers)
                              GestureDetector(
                                onTap: _showAddCareerDialog,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add,
                                          size: 14, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text(
                                        '추가',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '학력, 경력, 자격증, 수상 등 최대 $_maxCareers개',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 12),

                    // 경력 목록
                    if (_careers.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.border,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline,
                                color: AppColors.textSecondary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '+ 추가 버튼으로 약력을 입력하세요',
                              style: AppTextStyles.body2,
                            ),
                          ],
                        ),
                      )
                    else
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _careers.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex--;
                            final item = _careers.removeAt(oldIndex);
                            _careers.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          final career = _careers[index];
                          return _CareerListTile(
                            key: ValueKey('career_$index'),
                            career: career,
                            index: index,
                            onEdit: () =>
                                _showAddCareerDialog(editIndex: index),
                            onDelete: () =>
                                setState(() => _careers.removeAt(index)),
                          );
                        },
                      ),
                    const SizedBox(height: 28),

                    // ── 자기소개 ──────────────────────────
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

                    // ── 공개 설정 ─────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
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
                                  size: 20,
                                  color: AppColors.textSecondary),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('공개 명함',
                                      style: AppTextStyles.body1),
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
                            activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: provider.isLoading ? null : _handleSave,
                        child: Text(_isEditing ? '수정 완료' : '명함 생성'),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── 경력 항목 타일 ─────────────────────────────────────

class _CareerListTile extends StatelessWidget {
  final CareerItem career;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CareerListTile({
    super.key,
    required this.career,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        title: Text(
          career.title,
          style: AppTextStyles.body1,
        ),
        subtitle: (career.period != null || career.detail != null)
            ? Text(
                [career.period, career.detail]
                    .where((s) => s != null && s.isNotEmpty)
                    .map((s) => s as String)
                    .join(' \u00b7 '),
                style: AppTextStyles.caption,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 드래그 핸들
            const Icon(Icons.drag_handle,
                color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 4),
            // 수정
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: 18, color: AppColors.textSecondary),
              onPressed: onEdit,
              visualDensity: VisualDensity.compact,
            ),
            // 삭제
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: Colors.red),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
