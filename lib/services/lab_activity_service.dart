import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scilense_ar_mobile/models/lab_activity_remote.dart';

/// Loads lab activities from Firestore collection [labActivities].
class LabActivityService {
  LabActivityService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String collectionName = 'practiceLabActivities';

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(collectionName);

  /// All activities (list screen).
  Future<List<LabActivityRemote>> fetchAll() async {
    final snap = await _col.get();
    return snap.docs.map(LabActivityRemote.fromFirestore).toList();
  }

  /// Stream for live list updates.
  Stream<List<LabActivityRemote>> watchAll() {
    return _col.snapshots().map(
      (snap) => snap.docs.map(LabActivityRemote.fromFirestore).toList(),
    );
  }

  /// Single activity by document id.
  Future<LabActivityRemote?> fetchById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return LabActivityRemote.fromFirestore(doc);
  }

  /// Stream a single activity.
  Stream<LabActivityRemote?> watchById(String id) {
    return _col.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return LabActivityRemote.fromFirestore(doc);
    });
  }
}
