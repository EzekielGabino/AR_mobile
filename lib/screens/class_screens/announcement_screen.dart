import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scilense_ar_mobile/services/supabase_service.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';

// Design-system palette (file-private so it cannot clash with AppColors in app_theme.dart)
const Color _navy = Color(0xFF091540);
const Color _royalBlue = Color(0xFF1B2CC1);
const Color _periwinkle = Color(0xFF7692FF);
const Color _lightBlue = Color(0xFFABD2FA);

class AnnouncementSection extends StatefulWidget {
  const AnnouncementSection({
    super.key,
    required this.classID,
    required this.teachUid,
  });

  final String classID;
  final String teachUid;

  @override
  State<AnnouncementSection> createState() => _AnnouncementSectionState();
}

class _AnnouncementSectionState extends State<AnnouncementSection> {
  String teachName = '';
  String teachPhoto = '';
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.teachUid.isNotEmpty) {
        final teacher = await SupabaseService.client
            .from('profiles')
            .select('display_name, photo_url')
            .eq('id', widget.teachUid)
            .maybeSingle();
        if (teacher != null) {
          teachName = teacher['display_name'] as String? ?? '';
          teachPhoto = teacher['photo_url'] as String? ?? '';
        }
      }

      await _fetchOnce();

      await _sub?.cancel();
      _sub = SupabaseService.client
          .from('announcements')
          .stream(primaryKey: ['id'])
          .eq('class_id', widget.classID)
          .order('created_at', ascending: false)
          .listen(
            (rows) {
              if (!mounted) return;
              setState(() {
                _items = rows.map((e) => Map<String, dynamic>.from(e)).toList();
                _loading = false;
                _error = null;
              });
            },
            onError: (e) {
              debugPrint('announcements stream error: $e');
            },
          );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _fetchOnce() async {
    final rows = await SupabaseService.client
        .from('announcements')
        .select('id, body, created_at, attachments')
        .eq('class_id', widget.classID)
        .order('created_at', ascending: false);

    if (!mounted) return;
    setState(() {
      _items = List<Map<String, dynamic>>.from(
        (rows as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
      _loading = false;
    });
  }

  Future<void> _openFile(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _formatWhen(dynamic iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso.toString()).toLocal();
      return DateFormat('MMM d · h:mm a').format(d);
    } catch (_) {
      return iso.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _royalBlue),
      );
    }
    if (_error != null) {
      return Center(
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
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _bootstrap,
                // Visual only: royal blue button, 12 px radius, easy to tap
                style: FilledButton.styleFrom(
                  backgroundColor: _royalBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(120, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchOnce,
        color: _royalBlue,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            // Icon inside a soft light-blue circle (decorative)
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: _lightBlue.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.campaign_outlined,
                  size: 48,
                  color: _periwinkle,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No announcements yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'When your teacher posts to the class stream, it will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchOnce,
      color: _royalBlue,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, index) {
          final data = _items[index];
          final body = data['body'] as String? ?? '';
          final created = data['created_at'];
          final attachments = data['attachments'];
          final files = attachments is List
              ? List<Map<String, dynamic>>.from(
                  attachments.map((e) => Map<String, dynamic>.from(e as Map)),
                )
              : <Map<String, dynamic>>[];

          return Material(
            color: AppColors.cardBackground,
            elevation: 4,
            shadowColor: _periwinkle.withValues(alpha: 0.30),
            // shape replaces borderRadius so a thin light-blue border can be added
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: _lightBlue.withValues(alpha: 0.7)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Gradient ring around the avatar (decorative)
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_royalBlue, _periwinkle],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: _lightBlue.withValues(alpha: 0.35),
                          backgroundImage: teachPhoto.isNotEmpty
                              ? NetworkImage(teachPhoto)
                              : null,
                          child: teachPhoto.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  color: _royalBlue,
                                  size: 22,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              teachName.isEmpty ? 'Teacher' : teachName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (created != null)
                              Text(
                                _formatWhen(created),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Decorative announcement icon
                      const Icon(
                        Icons.campaign_rounded,
                        size: 24,
                        color: _periwinkle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (files.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ...files.map((f) {
                      final name =
                          f['name']?.toString() ??
                          f['fileName']?.toString() ??
                          'Attachment';
                      final url =
                          f['url']?.toString() ??
                          f['publicUrl']?.toString() ??
                          '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: _navy,
                          // shape replaces borderRadius so a thin border can be added
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: _periwinkle.withValues(alpha: 0.5),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: url.isEmpty ? null : () => _openFile(url),
                            splashColor: _periwinkle.withValues(alpha: 0.25),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.attach_file,
                                    size: 18,
                                    color: AppColors.accentSoft,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.accentSoft,
                                      ),
                                    ),
                                  ),
                                  if (url.isNotEmpty)
                                    const Icon(
                                      Icons.open_in_new,
                                      size: 16,
                                      color: AppColors.accentSoft,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}