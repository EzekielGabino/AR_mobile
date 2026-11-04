import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/components/profile_app_bar_button.dart';
import 'package:scilense_ar_mobile/services/supabase_service.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';

class PeopleScreen extends StatefulWidget {
  final String classUid;
  PeopleScreen({super.key, required this.classUid});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  String classID = '';
  String teachName = '';
  String teachPhoto = '';
  List<Map<String, dynamic>> students = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    classID = widget.classUid;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final classRow = await SupabaseService.client
          .from('classes')
          .select('id, teacher_id')
          .eq('id', classID)
          .maybeSingle();

      if (classRow == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Class not found';
        });
        return;
      }

      final teacherId = classRow['teacher_id'] as String? ?? '';
      if (teacherId.isNotEmpty) {
        final teacher = await SupabaseService.client
            .from('profiles')
            .select('display_name, photo_url')
            .eq('id', teacherId)
            .maybeSingle();
        if (teacher != null) {
          teachName = teacher['display_name'] as String? ?? '';
          teachPhoto = teacher['photo_url'] as String? ?? '';
        }
      }

      final members = await SupabaseService.client
          .from('class_members')
          .select('user_id, role, profiles(id, display_name, email, photo_url)')
          .eq('class_id', classID);

      final list = <Map<String, dynamic>>[];
      for (final m in (members as List)) {
        final map = Map<String, dynamic>.from(m as Map);
        if ((map['role'] as String?) == 'co_teacher') continue;
        final p = map['profiles'];
        if (p is Map) {
          list.add(Map<String, dynamic>.from(p));
        } else {
          list.add({'id': map['user_id'], 'display_name': 'Student'});
        }
      }
      list.sort((a, b) {
        final na = (a['display_name'] as String? ?? '').toLowerCase();
        final nb = (b['display_name'] as String? ?? '').toLowerCase();
        return na.compareTo(nb);
      });

      if (!mounted) return;
      setState(() {
        students = list;
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Class members'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: const [
          ProfileAppBarButton(),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    children: [
                      const _SectionHeader(
                        title: 'Teacher',
                        trailing: null,
                      ),
                      const SizedBox(height: 8),
                      _MemberCard(
                        name: teachName.isEmpty ? 'Teacher' : teachName,
                        photoUrl: teachPhoto,
                        subtitle: 'Class teacher',
                        emphasized: true,
                      ),
                      const SizedBox(height: 20),
                      _SectionHeader(
                        title: 'Students',
                        trailing: '${students.length}',
                      ),
                      const SizedBox(height: 8),
                      if (students.isEmpty)
                        Material(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          elevation: 1,
                          child: const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                'No students in this class yet.',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                        )
                      else
                        ...students.map((user) {
                          final name =
                              user['display_name'] as String? ?? 'Student';
                          final photo = user['photo_url'] as String?;
                          final email = user['email'] as String?;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _MemberCard(
                              name: name,
                              photoUrl: photo ?? '',
                              subtitle: email,
                              emphasized: false,
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accentSoft.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              trailing!,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.name,
    required this.photoUrl,
    this.subtitle,
    this.emphasized = false,
  });

  final String name;
  final String photoUrl;
  final String? subtitle;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl.isNotEmpty;

    return Material(
      color: AppColors.cardBackground,
      elevation: emphasized ? 3 : 1,
      shadowColor: AppColors.primaryDark.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: emphasized
            ? BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.primary, width: 4),
                ),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: emphasized ? 26 : 22,
                backgroundColor: AppColors.accentSoft,
                backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                child: hasPhoto
                    ? null
                    : Icon(
                        emphasized ? Icons.school_outlined : Icons.person_outline,
                        color: AppColors.primary,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: emphasized ? 17 : 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
