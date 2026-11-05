import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/services/student_notification_service.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';

// Design-system palette (file-private so it cannot clash with AppColors in app_theme.dart)
const Color _royalBlue = Color(0xFF1B2CC1);
const Color _periwinkle = Color(0xFF7692FF);
const Color _lightBlue = Color(0xFFABD2FA);
const Color _success = Color(0xFF2E9E5B);

/// Student in-app notifications: announcements, published activities, returns.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.classId,
    this.onOpenStream,
    this.onOpenActivities,
  });

  final String classId;
  final VoidCallback? onOpenStream;
  final VoidCallback? onOpenActivities;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = StudentNotificationService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.listMine();
      // Opening the alerts screen counts as reading all notifications
      final hasUnread = list.any((n) => n['read_at'] == null);
      if (hasUnread) {
        try {
          await _service.markAllRead();
          final now = DateTime.now().toUtc().toIso8601String();
          for (final n in list) {
            n['read_at'] ??= now;
          }
        } catch (_) {
          // Still show the list even if mark-all fails
        }
      }
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _formatWhen(dynamic iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso.toString()).toLocal();
      return '${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso.toString();
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'activity_published':
        return Icons.assignment;
      case 'activity_returned':
        return Icons.grading;
      case 'announcement_posted':
      default:
        return Icons.campaign;
    }
  }

  Future<void> _open(Map<String, dynamic> n) async {
    final id = n['id'] as String?;
    if (id != null && n['read_at'] == null) {
      try {
        await _service.markRead(id);
        n['read_at'] = DateTime.now().toUtc().toIso8601String();
        if (mounted) setState(() {});
      } catch (_) {}
    }

    final type = (n['type'] as String?) ?? '';
    if (!mounted) return;

    // Stay inside MainScreen shell (bottom tabs) via callbacks
    if (type == 'activity_published' || type == 'activity_returned') {
      widget.onOpenActivities?.call();
    } else {
      widget.onOpenStream?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // AppBar kept exactly as the ORIGINAL (uses the app theme's AppBar style)
      appBar: AppBar(title: const Text('Alerts'), centerTitle: true),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _royalBlue),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: AppColors.safetyRed,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              color: _royalBlue,
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 120),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Icon inside a soft light-blue circle (decorative)
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  color: _lightBlue.withValues(alpha: 0.35),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.notifications_none_rounded,
                                  size: 48,
                                  color: _periwinkle,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  'No notifications yet.\n'
                                  'Announcements, new activities, and returned work appear here.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final n = _items[i];
                        final unread = n['read_at'] == null;
                        final type = (n['type'] as String?) ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: 8,
                            left: 16,
                            right: 16,
                          ),
                          child: Card(
                            // Visual only: white card, glow, border, 16 px radius.
                            // Unread cards get a stronger royal-blue border + light-blue tint.
                            color: unread
                                ? Color.alphaBlend(
                                    _lightBlue.withValues(alpha: 0.18),
                                    Colors.white,
                                  )
                                : Colors.white,
                            elevation: 4,
                            shadowColor: _periwinkle.withValues(alpha: 0.30),
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: unread
                                    ? _periwinkle
                                    : _lightBlue.withValues(alpha: 0.7),
                                width: unread ? 1.5 : 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  // Gradient chip when unread, soft light-blue when read
                                  gradient: unread
                                      ? const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [_royalBlue, _periwinkle],
                                        )
                                      : null,
                                  color: unread
                                      ? null
                                      : _lightBlue.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _iconFor(type),
                                  size: 20,
                                  color: unread ? Colors.white : _royalBlue,
                                ),
                              ),
                              title: Text(
                                (n['title'] as String?) ?? 'Notification',
                                style: TextStyle(
                                  fontWeight: unread
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                [
                                  (n['body'] as String?) ?? '',
                                  _formatWhen(n['created_at']),
                                ].where((s) => s.isNotEmpty).join('\n'),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                              isThreeLine: true,
                              trailing: unread
                                  ? const Icon(
                                      Icons.circle,
                                      size: 10,
                                      color: _royalBlue,
                                    )
                                  : null,
                              onTap: () => _open(n),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}