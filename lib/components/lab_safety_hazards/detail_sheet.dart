import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/models/safety_item.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';

/// Opens a bottom sheet with the full safety brief for [item].
/// Works for Do's/Don'ts, Hazard Symbols, and Safety Signs alike.
Future<void> showSafetyDetailSheet(BuildContext context, SafetyItem item) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.zero,
          children: [
            _Header(item: item),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Section(
                    label: item.group == SafetyGroup.hazardSymbol
                        ? 'What it means'
                        : item.group == SafetyGroup.safetySign
                        ? 'What it means'
                        : 'Why it matters',
                    text: item.detail,
                  ),
                  if (item.examples != null) ...[
                    const SizedBox(height: 16),
                    _Section(label: 'Common examples', text: item.examples!),
                  ],
                  if (item.whereFound != null) ...[
                    const SizedBox(height: 16),
                    _Section(
                      label: "Where you'll see it",
                      text: item.whereFound!,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _NoteBox(
                    label: item.noteLabel,
                    text: item.note,
                    color: item.accentColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  final SafetyItem item;
  const _Header({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
      decoration: BoxDecoration(
        color: item.accentColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: -6,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.icon, color: Colors.white, size: 44),
              const SizedBox(height: 10),
              Text(
                item.title,
                style: SafetyTextStyles.heroTitle.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 4),
              Text(
                item.code.toUpperCase(),
                style: SafetyTextStyles.code.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  final String text;
  const _Section({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: SafetyTextStyles.eyebrow),
        const SizedBox(height: 6),
        Text(text, style: SafetyTextStyles.body),
      ],
    );
  }
}

class _NoteBox extends StatelessWidget {
  final String label;
  final String text;
  final Color color;
  const _NoteBox({
    required this.label,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SafetyColors.yellow.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: SafetyColors.yellow, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: SafetyTextStyles.tileTitle.copyWith(
              fontSize: 12,
              color: SafetyColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(text, style: SafetyTextStyles.body.copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}
