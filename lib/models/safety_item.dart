import 'package:flutter/material.dart';

/// The three content groups inside this module.
enum SafetyGroup { doRule, dontRule, hazardSymbol, safetySign }

/// One card/tile of content, used by Do's & Don'ts, Hazard Symbols,
/// and Safety Signs alike so a single widget set can render all three.
class SafetyItem {
  final String id;
  final SafetyGroup group;

  /// Sub-category, only used by Safety Signs for chip filtering
  /// (e.g. "Prohibition", "Warning", "Mandatory", "Emergency").
  final String? subCategory;

  final String code; // e.g. "GHS05", "M-01"
  final String title;
  final String shortDescription; // shown on the tile/list row
  final String detail; // "why it matters" / "what it means"
  final String? examples; // hazard symbols only
  final String? whereFound; // safety signs only
  final String noteLabel; // "Safety Tip" | "Precaution" | "Safety Note"
  final String note;

  final IconData icon;
  final Color accentColor;

  const SafetyItem({
    required this.id,
    required this.group,
    this.subCategory,
    required this.code,
    required this.title,
    required this.shortDescription,
    required this.detail,
    this.examples,
    this.whereFound,
    required this.noteLabel,
    required this.note,
    required this.icon,
    required this.accentColor,
  });
}