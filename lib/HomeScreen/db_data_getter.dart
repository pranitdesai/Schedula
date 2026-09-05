import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DataGetter {
  static Future<String> getName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "Guest";
    final ref = FirebaseDatabase.instance.ref("users/${user.uid}/profile/name");
    final snapshot = await ref.get();
    return snapshot.value?.toString() ?? "No Name";
  }
  static Future<Map<String, dynamic>> getWeeklySchedule() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    DatabaseReference ref = FirebaseDatabase.instance
        .ref("schedules")
        .child(user.uid)
        .child("weeklySchedule");

    DataSnapshot snapshot = await ref.get();

    if (!snapshot.exists) return {};

    return Map<String, dynamic>.from(snapshot.value as Map);
  }
  static Future<Map<String, dynamic>> getDailySchedule() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    DatabaseReference ref = FirebaseDatabase.instance
        .ref("schedules")
        .child(user.uid)
        .child("dailyStudySchedule");

    DataSnapshot snapshot = await ref.get();

    if (!snapshot.exists) return {};

    return Map<String, dynamic>.from(snapshot.value as Map);
  }

  static Future<void> setWeeklySchedule(Map<String, dynamic> schedule) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DatabaseReference ref = FirebaseDatabase.instance
        .ref("schedules")
        .child(user.uid)
        .child("weeklySchedule");

    await ref.set(schedule);
  }

  static Future<void> setDailySchedule(Map<String, dynamic> schedule) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DatabaseReference ref = FirebaseDatabase.instance
        .ref("schedules")
        .child(user.uid)
        .child("dailyStudySchedule");

    await ref.set(schedule);
  }
}