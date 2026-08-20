import 'package:flutter/material.dart';
import '../models/notification_settings.dart';
import '../../../core/theme/app_theme.dart';

/// 알림 설정.
///
/// FCM 키가 아직 없어 실제 푸시는 전송되지 않는다. 화면과 저장 구조를 먼저
/// 세워 두고, 키가 도착하면 [NotificationSettings]를 서버로 동기화하는
/// 호출만 붙이면 되도록 했다. 사용자가 "켰는데 왜 안 오지"로 오해하지 않도록
/// 상단에 연결 상태를 명시한다.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  NotificationSettings? _settings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = await NotificationSettings.load();
    if (!mounted) return;
    setState(() => _settings = loaded);
  }

  Future<void> _update(NotificationSettings next) async {
    setState(() => _settings = next);
    await next.save();
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;

    return Scaffold(
      appBar: AppBar(title: const Text('알림 설정')),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const _PendingBanner(),

                // ── 전체 스위치 ────────────────────────────
                SwitchListTile(
                  value: settings.pushEnabled,
                  onChanged: (v) =>
                      _update(settings.copyWith(pushEnabled: v)),
                  title: const Text(
                    '푸시 알림 받기',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('끄면 아래 항목과 무관하게 알림이 오지 않습니다.'),
                  activeThumbColor: AppColors.primary,
                ),

                const Divider(
                    height: 8, thickness: 8, color: AppColors.background),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Text(
                    '알림 종류',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: settings.pushEnabled
                          ? AppColors.textSecondary
                          : AppColors.textTertiary,
                    ),
                  ),
                ),

                for (final channel in NotificationChannel.values)
                  SwitchListTile(
                    value: settings.channels[channel] ?? false,
                    // 전체 스위치가 꺼져 있으면 개별 항목을 만질 수 없다
                    onChanged: settings.pushEnabled
                        ? (v) => _update(settings.copyWith(channels: {
                              ...settings.channels,
                              channel: v,
                            }))
                        : null,
                    title: Text(channel.label),
                    subtitle: Text(
                      channel.description,
                      style: const TextStyle(fontSize: 12),
                    ),
                    activeThumbColor: AppColors.primary,
                  ),

                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '설정은 이 기기에 저장됩니다. 알림 연결이 완료되면 계정에 함께 저장됩니다.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}

/// 푸시 연결 대기 안내 — FCM 키 수령 후 제거한다.
class _PendingBanner extends StatelessWidget {
  const _PendingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '기기 알림 연결을 준비 중입니다. 지금 설정해 두시면 연결이 끝나는 즉시 그대로 적용됩니다.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
