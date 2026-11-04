import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scilense_ar_mobile/services/supabase_config.dart';

/// Thin access to the shared [SupabaseClient] after [initialize].
class SupabaseService {
  SupabaseService._();

  static bool _ready = false;

  static bool get isReady => _ready;

  static SupabaseClient get client {
    if (!_ready) {
      throw StateError(
        'SupabaseService.initialize() was not called (or failed).',
      );
    }
    return Supabase.instance.client;
  }

  /// Call once from main() after WidgetsFlutterBinding.ensureInitialized().
  /// Does not replace Firebase — both run during the migration.
  static Future<void> initialize() async {
    if (_ready) return;
    if (!SupabaseConfig.isConfigured) {
      throw StateError(
        'Supabase URL/anon key missing. Set SupabaseConfig or --dart-define.',
      );
    }
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    _ready = true;
  }
}
