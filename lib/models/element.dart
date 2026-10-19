class ElementData {
  final int atomicNumber;
  final String symbol;
  final String name;
  final int period;
  final int group;
  final String category;
  final double atomicMass;

  ElementData({
    required this.atomicNumber,
    required this.symbol,
    required this.name,
    required this.period,
    required this.group,
    required this.category,
    required this.atomicMass,
  });

  factory ElementData.fromJson(Map<String, dynamic> json) {
    return ElementData(
      atomicNumber: json['number'],
      symbol: json['symbol'],
      name: json['name'],
      period: json['ypos'],
      group: json['xpos'],
      category: json['category'],
      atomicMass: (json['atomic_mass'] as num).toDouble(),
    );
  }
}
