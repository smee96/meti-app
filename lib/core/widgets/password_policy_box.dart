import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 비밀번호 정책 판정 — 회원가입·비밀번호 변경이 같은 기준을 쓴다.
///
/// 서버 최소 요건은 8자(`auth.ts`)지만, 앱은 대/소문자·숫자까지를 필수로 본다.
/// 특수문자는 선택 항목이라 [allMet]에 포함하지 않는다.
class PasswordPolicy {
  final String password;
  const PasswordPolicy(this.password);

  bool get hasMinLength => password.length >= 8;
  bool get hasUppercase => password.contains(RegExp(r'[A-Z]'));
  bool get hasLowercase => password.contains(RegExp(r'[a-z]'));
  bool get hasDigit => password.contains(RegExp(r'[0-9]'));
  bool get hasSpecial =>
      password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]'));

  bool get allMet => hasMinLength && hasUppercase && hasLowercase && hasDigit;
}

/// 입력 중인 비밀번호가 정책을 얼마나 충족했는지 보여주는 체크리스트.
class PasswordPolicyBox extends StatelessWidget {
  final PasswordPolicy policy;

  const PasswordPolicyBox({super.key, required this.policy});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '비밀번호 조건',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          _PolicyRow(met: policy.hasMinLength, label: '8자 이상'),
          _PolicyRow(met: policy.hasUppercase, label: '영문 대문자 포함 (A-Z)'),
          _PolicyRow(met: policy.hasLowercase, label: '영문 소문자 포함 (a-z)'),
          _PolicyRow(met: policy.hasDigit, label: '숫자 포함 (0-9)'),
          _PolicyRow(
            met: policy.hasSpecial,
            label: '특수문자 포함 (선택)',
            optional: true,
          ),
        ],
      ),
    );
  }
}

class _PolicyRow extends StatelessWidget {
  final bool met;
  final String label;
  final bool optional;

  const _PolicyRow({
    required this.met,
    required this.label,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = met
        ? AppColors.success
        : optional
            ? AppColors.textTertiary
            : AppColors.warning;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              met ? Icons.check_circle : Icons.radio_button_unchecked,
              key: ValueKey(met),
              size: 15,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: met ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
