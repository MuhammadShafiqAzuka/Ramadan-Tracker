import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ramadan_cal_model.dart';

class RamadhanCalendarService {
  final FirebaseFirestore _db;
  RamadhanCalendarService(this._db);

  DocumentReference<Map<String, dynamic>> _doc(int year) =>
      _db.collection('ramadhan_calendar').doc('$year');

  Stream<RamadhanCalendarConfig?> watchYear(int year) {
    return _doc(year).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return RamadhanCalendarConfig.fromMap(data);
    });
  }

  Future<RamadhanCalendarConfig?> getYear(int year) async {
    final snap = await _doc(year).get();
    final data = snap.data();
    if (data == null) return null;
    return RamadhanCalendarConfig.fromMap(data);
  }
}