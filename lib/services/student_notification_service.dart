import 'package:scilense_ar_mobile/services/supabase_service.dart';

class StudentNotificationService {
  final _client = SupabaseService.client;

  Future<List<Map<String, dynamic>>> listMine({int limit = 50}) async {
    final rows = await _client
        .from('student_notifications')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(
      (rows as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  Future<void> markRead(String id) async {
    await _client.from('student_notifications').update({
      'read_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  /// Mark every unread notification for the current user as read.
  Future<void> markAllRead() async {
    await _client.from('student_notifications').update({
      'read_at': DateTime.now().toUtc().toIso8601String(),
    }).isFilter('read_at', null);
  }

  Future<int> unreadCount() async {
    final rows = await _client
        .from('student_notifications')
        .select('id')
        .isFilter('read_at', null);
    return (rows as List).length;
  }
}
