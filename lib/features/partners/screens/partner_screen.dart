import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// 제휴 탭
/// 해피트리 등 파트너 서비스가 들어갈 영역. 현재는 준비중 placeholder.
class PartnerScreen extends StatelessWidget {
  const PartnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('제휴')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.handshake_outlined,
                  size: 44,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text('제휴 서비스 준비중', style: AppTextStyles.h2),
              const SizedBox(height: 12),
              Text(
                '해피트리 등 다양한 파트너 혜택을\n곧 만나보실 수 있어요.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
