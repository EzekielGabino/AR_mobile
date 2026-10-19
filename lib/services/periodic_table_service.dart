import 'dart:convert';

import 'package:flutter/services.dart';
import '../models/element.dart';

class PeriodicTableService {
  Future<List<ElementData>> loadElements() async {
    final jsonString = await rootBundle.loadString(
      'assets/element/periodic_table.json',
    );

    final jsonData = json.decode(jsonString);

    final List elements = jsonData["elements"];

    return elements.map((e) => ElementData.fromJson(e)).toList();
  }
}
