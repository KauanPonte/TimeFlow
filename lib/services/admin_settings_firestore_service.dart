import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_appdeponto/models/saved_workplace.dart';
import 'package:geolocator/geolocator.dart';

class AdminSettingsFirestoreService {
  final FirebaseFirestore _firestore;

  AdminSettingsFirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<SavedWorkplace>> loadWorkplaces() async {
    final doc = await _firestore.collection('settings').doc('company').get();
    if (!doc.exists) return const [];

    final data = doc.data();
    if (data == null) return const [];

    return _parseWorkplaces(data);
  }

  SavedWorkplace? findNearbyWorkplace({
    required List<SavedWorkplace> workplaces,
    required double lat,
    required double lng,
    double withinMeters = 10,
  }) {
    SavedWorkplace? nearest;
    var nearestDistance = double.infinity;

    for (final workplace in workplaces) {
      final distance = Geolocator.distanceBetween(
        lat,
        lng,
        workplace.lat,
        workplace.lng,
      );
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = workplace;
      }
    }

    if (nearest == null || nearestDistance > withinMeters) {
      return null;
    }

    return nearest;
  }

  Future<List<SavedWorkplace>> addWorkplace({
    required List<SavedWorkplace> currentWorkplaces,
    required SavedWorkplace workplace,
  }) async {
    final updated = [...currentWorkplaces, workplace];
    await _saveWorkplaces(updated);
    return updated;
  }

  Future<List<SavedWorkplace>> removeWorkplaceAt({
    required List<SavedWorkplace> currentWorkplaces,
    required int index,
  }) async {
    final updated = List<SavedWorkplace>.from(currentWorkplaces)
      ..removeAt(index);
    await _saveWorkplaces(updated);
    return updated;
  }

  Future<void> _saveWorkplaces(List<SavedWorkplace> workplaces) async {
    final payload = <String, dynamic>{
      'workplaces': workplaces.map((w) => w.toFirestore()).toList(),
      'maxDistanceMeters': 100,
      'updatedAt': Timestamp.now(),
    };

    if (workplaces.isNotEmpty) {
      final last = workplaces.last;
      payload['workplaceLat'] = last.lat;
      payload['workplaceLng'] = last.lng;
      payload['workplaceName'] = last.name;
    } else {
      payload['workplaceLat'] = FieldValue.delete();
      payload['workplaceLng'] = FieldValue.delete();
      payload['workplaceName'] = FieldValue.delete();
    }

    await _firestore
        .collection('settings')
        .doc('company')
        .set(payload, SetOptions(merge: true));
  }

  List<SavedWorkplace> _parseWorkplaces(Map<String, dynamic> data) {
    final parsed = <SavedWorkplace>[];

    final rawList = data['workplaces'];
    if (rawList is List) {
      for (final item in rawList) {
        final workplace = SavedWorkplace.fromDynamicSafe(item);
        if (workplace != null) {
          parsed.add(workplace);
        }
      }
    }

    if (parsed.isNotEmpty) {
      return parsed;
    }

    final lat = (data['workplaceLat'] as num?)?.toDouble();
    final lng = (data['workplaceLng'] as num?)?.toDouble();
    if (lat == null || lng == null) {
      return parsed;
    }

    final name = (data['workplaceName'] ?? '').toString();
    return [
      SavedWorkplace(
        lat: lat,
        lng: lng,
        name: name,
      ),
    ];
  }
}
