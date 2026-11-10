import 'package:scilense_ar_mobile/services/supabase_service.dart';

class StudentNotificationService {
  final _client = SupabaseService.client;

  Future<List<Map<String, dynamic>>> listMine({
    String? classId,
    int limit = 50,
  }) async {
    var query = _client.from('student_notifications').select();
    if (classId != null && classId.isNotEmpty) {
      query = query.eq('class_id', classId);
    }
    final rows = await query.order('created_at', ascending: false).limit(limit);
    return List<Map<String, dynamic>>.from(
      (rows as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  Future<void> markRead(String id) async {
    await _client.from('student_notifications').update({
      'read_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> markAllRead({String? classId}) async {
    var query = _client.from('student_notifications').update({
      'read_at': DateTime.now().toUtc().toIso8601String(),
    }).isFilter('read_at', null);
    if (classId != null && classId.isNotEmpty) {
      query = query.eq('class_id', classId);
    }
    await query;
  }

  Future<int> unreadCount({String? classId}) async {
    var query = _client
        .from('student_notifications')
        .select('id')
        .isFilter('read_at', null);
    if (classId != null && classId.isNotEmpty) {
      query = query.eq('class_id', classId);
    }
    final rows = await query;
    return (rows as List).length;
  }
}
