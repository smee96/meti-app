import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── Loading Overlay ──────────────────────────────────
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({super.key, required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}

// ─── App Logo (ELID) ──────────────────────────────────
// 심볼: 네이비 그라데이션 타일 + 소문자 'e' + 골드 도트
class ElidSymbol extends StatelessWidget {
  final double size;

  const ElidSymbol({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(0.6, -1.2),
          radius: 1.3,
          colors: [
            AppColors.primaryLight,
            AppColors.primary,
            AppColors.primaryDark,
          ],
          stops: [0.0, 0.42, 1.0],
        ),
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.45),
          width: size >= 64 ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text.rich(
          TextSpan(
            text: 'e',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.58,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -size * 0.01,
            ),
            children: const [
              TextSpan(text: '.', style: TextStyle(color: AppColors.gold)),
            ],
          ),
        ),
      ),
    );
  }
}

// 워드마크: EL + 골드 I + D (Pretendard ExtraBold)
class ElidWordmark extends StatelessWidget {
  final double fontSize;
  final bool onDark;

  const ElidWordmark({super.key, this.fontSize = 24, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final base = onDark ? Colors.white : AppColors.primary;
    return Text.rich(
      TextSpan(
        text: 'EL',
        style: TextStyle(
          color: base,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: fontSize * -0.01,
          height: 1,
        ),
        children: const [
          TextSpan(text: 'I', style: TextStyle(color: AppColors.gold)),
          TextSpan(text: 'D'),
        ],
      ),
    );
  }
}

class ElidLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool lightMode; // true = 어두운 배경 위

  const ElidLogo({
    super.key,
    this.size = 48,
    this.showText = true,
    this.lightMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!showText) return ElidSymbol(size: size);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElidSymbol(size: size),
        const SizedBox(height: 8),
        ElidWordmark(fontSize: size * 0.38, onDark: lightMode),
      ],
    );
  }
}

// ─── Error Snackbar ───────────────────────────────────
void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ),
  );
}

void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ),
  );
}

/// 포인트 부족 오류 전용 스낵바
/// - insufficient_points 응답 시 호출
/// - 앱 내 충전 버튼 금지 (v2.5 정책)
/// - extra: {'current': int, 'required': int, 'short': int}
void showInsufficientPointsSnackBar(
  BuildContext context, {
  int? current,
  int? required,
  int? short,
}) {
  String fmt(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  final currentStr = current != null ? '${fmt(current)}P' : null;
  final shortStr   = short    != null ? '${fmt(short)}P'   : null;

  final detail = (currentStr != null && shortStr != null)
      ? '현재 $currentStr · $shortStr 부족'
      : null;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined,
              color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '포인트가 부족합니다',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                ),
                if (detail != null)
                  Text(
                    detail,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFB45309), // amber-700
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    ),
  );
}

// ─── Empty State ──────────────────────────────────────
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.h4, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, style: AppTextStyles.body2, textAlign: TextAlign.center),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(160, 44),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Avatar Widget ────────────────────────────────────
class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double size;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    required this.name,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(avatarUrl!),
        backgroundColor: AppColors.surfaceVariant,
      );
    }
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.primary,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.h4),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

// ─── Plan Badge ───────────────────────────────────────
class PlanBadge extends StatelessWidget {
  final String plan;

  const PlanBadge({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (plan.toLowerCase()) {
      case 'pro':
        color = AppColors.accent;
        label = 'PRO';
        break;
      case 'business':
        color = const Color(0xFF8b5cf6);
        label = 'BUSINESS';
        break;
      default:
        color = AppColors.textTertiary;
        label = 'FREE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
