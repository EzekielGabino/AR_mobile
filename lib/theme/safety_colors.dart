import 'package:flutter/material.dart';

/// Color tokens for the Laboratory Safety & Hazard module.
/// Keep these in one place so palette changes never require touching widgets.
class SafetyColors {
  SafetyColors._();

  static const ink = Color(0xFF10151A);
  static const paper = Color(0xFFE7ECEE);
  static const paperSoft = Color(0xFFF2F5F6);
  static const paperLine = Color(0xFFC7D1D5);

  static const yellow = Color(0xFFF4B400);
  static const orange = Color(0xFFE2572B);
  static const blue = Color(0xFF1D4E89);
  static const red = Color(0xFFB23A2E);
  static const green = Color(0xFF3C7A5C);
  static const purple = Color(0xFF5B4E9C);
  static const black = Color(0xFF1B1D22);

  /// Convenience map so data files can just reference a category tag.
  static const Map<String, Color> byCategory = {
    'do': green,
    'dont': red,
    'flammable': orange,
    'corrosive': blue,
    'toxic': black,
    'oxidizer': yellow,
    'explosive': black,
    'health': purple,
    'gas': blue,
    'eco': green,
    'prohibition': red,
    'warning': yellow,
    'mandatory': blue,
    'emergency': green,
  };
}