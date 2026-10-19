
class LabEquipment {
  final String id;
  final String name;
  final String imagePath;
  final bool isNetworkImage;
  final String description;
  final String purpose;
  final String whenToUse;
  final String safetyTip;
  final String category;

  const LabEquipment({
    required this.id,
    required this.name,
    required this.imagePath,
    this.isNetworkImage = false,
    required this.description,
    required this.purpose,
    required this.whenToUse,
    required this.safetyTip,
    this.category = 'General',
  });
}