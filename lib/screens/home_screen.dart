import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/screens/class_screens/activities_screen.dart';
import 'package:scilense_ar_mobile/screens/class_screens/announcement_screen.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';
import 'package:scilense_ar_mobile/services/supabase_service.dart';

class HomeScreen extends StatefulWidget {
  final String classId;
  /// 0 = Stream, 1 = Activities
  final int initialTab;
  HomeScreen({super.key, required this.classId, this.initialTab = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String classID = '';
  String subject = '';
  String section = '';
  String level = '';
  String teachUid = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    classID = widget.classId;
    _getClassInfo();
  }

  Future<void> _getClassInfo() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final row = await SupabaseService.client
          .from('classes')
          .select('id, section_name, grade_level, subject, teacher_id')
          .eq('id', classID)
          .maybeSingle();

      if (!mounted) return;

      if (row == null) {
        setState(() {
          _loading = false;
          _error = 'Class not found.';
        });
        return;
      }

      setState(() {
        subject = row['subject'] as String? ?? '';
        section = row['section_name'] as String? ?? '';
        level = row['grade_level'] as String? ?? '';
        teachUid = row['teacher_id'] as String? ?? '';
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final title = [
      if (subject.isNotEmpty) subject,
      if (section.isNotEmpty) section,
      if (level.isNotEmpty) level,
    ].join(' · ');

    return DefaultTabController(
      initialIndex: widget.initialTab.clamp(0, 1),
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(title.isEmpty ? 'Classroom' : title),
          centerTitle: true,
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            dividerColor: Colors.transparent,
            dividerHeight: 0,
            tabs: <Widget>[
              Tab(text: 'Stream'),
              Tab(text: 'Activities'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            AnnouncementSection(
              classID: classID,
              teachUid: teachUid,
            ),
            ActivitiesSection(classId: classID),
          ],
        ),
      ),
    );
  }
}
