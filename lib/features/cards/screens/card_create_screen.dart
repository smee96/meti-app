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
  bool _isPublic = true;

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
        cardType: 'personal',
        templateId: _selectedTemplate,
        isPrimary: 0,
        isPublic: _isPublic ? 1 : 0,
        isActive: 1,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '명함 수정' : '명함 만들기'),
        actions: [
          TextButton(
            onPressed: context.watch<CardsProvider>().isLoading ? null : _handleSave,
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
                    // 미리보기
                    const Text('미리보기', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    StatefulBuilder(
                      builder: (context, setPreviewState) {
                        return BusinessCardWidget(card: _previewCard);
                      },
                    ),
                    const SizedBox(height: 24),

                    // 템플릿 선택
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
                    const SizedBox(height: 24),

                    // 기본 정보
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
                    const SizedBox(height: 24),

                    // 연락처
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
                    const SizedBox(height: 24),

                    // 자기소개
                    const Text('자기소개', style: AppTextStyles.h4),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bioCtrl,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: '자기소개',
                        hintText: '간단한 자기소개를 작성해보세요.',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 공개 설정
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
                              const Icon(Icons.public, size: 20,
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
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    ElevatedButton(
                      onPressed:
                          provider.isLoading ? null : _handleSave,
                      child: Text(_isEditing ? '수정 완료' : '명함 생성'),
                    ),
                    const SizedBox(height: 32),
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
