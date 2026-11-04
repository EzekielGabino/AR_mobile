import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/services/student_notification_service.dart';

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
      appBar: AppBar(title: const Text('Alerts'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Text(
                            'No notifications yet.\n'
                            'Announcements, new activities, and returned work appear here.',
                            textAlign: TextAlign.center,
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
                            left: 8,
                            right: 8,
                          ),
                          child: Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: unread
                                    ? Colors.indigo.shade100
                                    : Colors.grey.shade200,
                                child: Icon(_iconFor(type), size: 20),
                              ),
                              title: Text(
                                (n['title'] as String?) ?? 'Notification',
                                style: TextStyle(
                                  fontWeight: unread
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                [
                                  (n['body'] as String?) ?? '',
                                  _formatWhen(n['created_at']),
                                ].where((s) => s.isNotEmpty).join('\n'),
                              ),
                              isThreeLine: true,
                              trailing: unread
                                  ? const Icon(
                                      Icons.circle,
                                      size: 10,
                                      color: Colors.indigo,
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
