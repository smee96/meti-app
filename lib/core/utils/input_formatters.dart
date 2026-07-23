// input_formatters.dart — 공용 TextInputFormatter 모음
// - PhoneNumberFormatter: 한국 전화번호 자동 하이픈 (010-0000-0000, 02-000-0000 등)
// - ThousandsFormatter:   금액 천단위 콤마 자동 (1,000,000)
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// 입력 도중 숫자만 남겨 한국 전화번호 형식으로 하이픈을 자동 삽입한다.
/// 지역번호(02·0XX)와 휴대폰(010 등)을 자릿수로 구분한다. 최대 11자리.
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 11) digits = digits.substring(0, 11);
    final formatted = _format(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _format(String d) {
    if (d.isEmpty) return '';
    // 서울 지역번호 02 (총 9~10자리)
    if (d.startsWith('02')) {
      if (d.length <= 2) return d;
      if (d.length <= 5) return '${d.substring(0, 2)}-${d.substring(2)}';
      if (d.length <= 9) {
        return '${d.substring(0, 2)}-${d.substring(2, d.length - 4)}-${d.substring(d.length - 4)}';
      }
      return '${d.substring(0, 2)}-${d.substring(2, 6)}-${d.substring(6)}';
    }
    // 휴대폰(010 등) / 3자리 지역번호 (총 10~11자리)
    if (d.length <= 3) return d;
    if (d.length <= 7) return '${d.substring(0, 3)}-${d.substring(3)}';
    if (d.length <= 10) {
      return '${d.substring(0, 3)}-${d.substring(3, d.length - 4)}-${d.substring(d.length - 4)}';
    }
    return '${d.substring(0, 3)}-${d.substring(3, 7)}-${d.substring(7)}';
  }
}

/// 입력 도중 숫자만 남겨 천단위 콤마를 자동 삽입한다. (금액·포인트 전용)
/// 저장/전송 시에는 [digitsOnly]로 콤마를 제거해 파싱한다.
class ThousandsFormatter extends TextInputFormatter {
  static final NumberFormat _fmt = NumberFormat('#,###');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final formatted = _fmt.format(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// 콤마·공백 등을 제거하고 숫자만 남긴다. (ThousandsFormatter가 적용된 값 파싱용)
String digitsOnly(String s) => s.replaceAll(RegExp(r'[^\d]'), '');
