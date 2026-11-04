import 'package:scilense_ar_mobile/models/lab_activity_remote.dart';
import 'package:scilense_ar_mobile/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Loads practice lab activities from Supabase [practice_lab_activities].
class LabActivityService {
  LabActivityService();

  SupabaseClient get _client => SupabaseService.client;

  static const String tableName = 'practice_lab_activities';

  /// All practice activities (list screen).
  Future<List<LabActivityRemote>> fetchAll() async {
    final rows = await _client
        .from(tableName)
        .select()
        .order('title', ascending: true);
    return (rows as List)
        .map(
          (e) => LabActivityRemote.fromSupabase(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  /// One-shot stream for widgets that still use StreamBuilder.
  /// Does not require Supabase Realtime on the table.
  Stream<List<LabActivityRemote>> watchAll() async* {
    yield await fetchAll();
  }

  /// Single activity by id (UUID string).
  Future<LabActivityRemote?> fetchById(String id) async {
    if (id.isEmpty) return null;
    final row = await _client
        .from(tableName)
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return LabActivityRemote.fromSupabase(
      Map<String, dynamic>.from(row),
    );
  }

  Stream<LabActivityRemote?> watchById(String id) async* {
    yield await fetchById(id);
  }
}
