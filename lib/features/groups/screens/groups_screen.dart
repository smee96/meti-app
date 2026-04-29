import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _api = ApiClient();

  List<dynamic> _groups = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedCategory;

  final _categories = [
    {'value': null, 'label': '전체'},
    {'value': 'association', 'label': '협회'},
    {'value': 'company', 'label': '회사'},
    {'value': 'club', 'label': '클럽'},
    {'value': 'other', 'label': '기타'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGroups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    try {
      final params = <String, dynamic>{'page': 1, 'limit': 20};
      if (_searchQuery.isNotEmpty) params['q'] = _searchQuery;
      if (_selectedCategory != null) params['category'] = _selectedCategory!;

      final response = await _api.get('/groups', queryParams: params, auth: false);
      if (response['success'] == true) {
        setState(() => _groups = response['data'] as List);
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('그룹'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: '그룹 탐색'),
            Tab(text: '내 그룹'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '그룹 만들기',
            onPressed: _showCreateGroupDialog,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExploreTab(),
          _buildMyGroupsTab(),
        ],
      ),
    );
  }

  Widget _buildExploreTab() {
    return Column(
      children: [
        // 검색 + 필터
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: '그룹 검색',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) {
                  _searchQuery = v;
                  _loadGroups();
                },
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat = _categories[i];
                    final isSelected = _selectedCategory == cat['value'];
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedCategory = cat['value'] as String?);
                        _loadGroups();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            cat['label'] as String,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _groups.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.group_outlined,
                      title: '그룹이 없어요',
                      subtitle: '새로운 그룹을 만들어보세요!',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadGroups,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _groups.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _GroupCard(group: _groups[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildMyGroupsTab() {
    return const EmptyStateWidget(
      icon: Icons.group_outlined,
      title: '가입된 그룹이 없어요',
      subtitle: '\'그룹 탐색\'에서 관심 있는 그룹에 참여해보세요.',
    );
  }

  void _showCreateGroupDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'club';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('그룹 개설 신청', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            const Text(
              '슈퍼어드민 승인 후 활성화됩니다.',
              style: AppTextStyles.body2,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: '그룹명 *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '설명'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                try {
                  final resp = await _api.post('/groups', body: {
                    'name': nameCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'category': category,
                  });
                  if (!context.mounted) return;
                  Navigator.pop(ctx);
                  if (resp['success'] == true) {
                    showSuccessSnackBar(context, '그룹 개설 신청이 완료되었습니다!');
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  showErrorSnackBar(context, e.toString());
                }
              },
              child: const Text('신청하기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final dynamic group;
  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.group, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group['name'] ?? '', style: AppTextStyles.h4),
                if (group['description'] != null)
                  Text(
                    group['description'],
                    style: AppTextStyles.body2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 13, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      '${group['member_count'] ?? 0}명',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        group['category'] ?? 'other',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}
