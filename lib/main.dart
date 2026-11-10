import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/components/auth_gate.dart';
import 'package:scilense_ar_mobile/components/app_onboarding_host.dart';
import 'package:scilense_ar_mobile/services/auth_service.dart';
import 'package:scilense_ar_mobile/services/supabase_service.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Supabase client ready for later steps (Auth, classes, labs).
  await SupabaseService.initialize();
  await AuthService().initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScilenseAR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const AppOnboardingHost(child: AuthGate()),
    );
  }
}
