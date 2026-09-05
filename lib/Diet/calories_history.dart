import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Utils/app_color.dart';
import 'diet_modal.dart';
import 'meal_modal.dart';

class CalorieHistoryScreen extends StatefulWidget {
  const CalorieHistoryScreen({super.key});

  @override
  State<CalorieHistoryScreen> createState() =>
      _CalorieHistoryScreenState();
}

class _CalorieHistoryScreenState
    extends State<CalorieHistoryScreen> {

  final uid = FirebaseAuth.instance.currentUser!.uid;

  final DatabaseReference trackingRef =
  FirebaseDatabase.instance.ref();

  final DatabaseReference dietRef =
  FirebaseDatabase.instance.ref();

  Diet? _diet;

  @override
  void initState() {
    super.initState();
    _loadDiet();
  }

  void _loadDiet() async {
    final snapshot =
    await dietRef.child("diet/$uid").get();

    if (snapshot.exists && snapshot.value != null) {
      final raw = snapshot.value;

      if (raw is Map) {
        setState(() {
          _diet = Diet.fromSnapshot(
              Map<dynamic, dynamic>.from(raw));
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_diet == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: Text("Calorie Analytics",
            style: GoogleFonts.poppins(
              color: Colors.black,
            )),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream:
        trackingRef.child("diet_tracking/$uid").onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData ||
              snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No data"));
          }

          int totalCalories = _diet!.meals
              .fold(0, (sum, m) => sum + m.calories);

          final raw = snapshot.data!.snapshot.value;

          if (raw is! Map) {
            return const Center(child: Text("Invalid data"));
          }

          final data = Map<String, dynamic>.from(raw);

          final List<Map<String, dynamic>> history = [];

          data.forEach((date, value) {
            if (value is Map) {
              int calories = 0;

              value.forEach((key, done) {
                if (done == true) {
                  final parts = key.split("_");
                  if (parts.length < 2) return;

                  final index = int.tryParse(parts[1]);
                  if (index == null ||
                      index >= _diet!.meals.length) return;

                  calories +=
                      _diet!.meals[index].calories;
                }
              });

              history.add({
                "date": date,
                "calories": calories,
                "raw": value // 🔥 store raw data
              });
            }
          });

          history.sort((a, b) =>
              b["date"].compareTo(a["date"]));

          int total = history.fold(
              0, (sum, e) => sum + (e["calories"] as int));

          int avg = history.isEmpty
              ? 0
              : (total ~/ history.length);

          Map<String, dynamic>? bestDay;

          for (var e in history) {
            int c = e["calories"];
            if (bestDay == null ||
                c > bestDay["calories"]) {
              bestDay = e;
            }
          }

          String aiSuggestion =
          _generateSuggestion(avg);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [

              _analyticsCard("Average Intake", "$avg kcal"),

              _analyticsCard(
                  "Best Day",
                  "${bestDay?["date"] ?? "-"} (${bestDay?["calories"] ?? 0} kcal)"),

              const SizedBox(height: 20),

              _aiCard(aiSuggestion),

              const SizedBox(height: 20),

              /// 🔥 UPDATED HISTORY LIST WITH TAP
              ...history.map((e) => _historyCard(
                e["date"],
                e["calories"],
                totalCalories,
                e["raw"],
              )),
            ],
          );
        },
      ),
    );
  }

  /// 🔥 SHOW MEALS (NO UI CHANGE IN MAIN SCREEN)
  void _showMealDetails(String date, dynamic rawDayData) {

    if (rawDayData == null || rawDayData is! Map) return;

    final dayData =
    Map<String, dynamic>.from(rawDayData);

    List<Meal> missedMeals = [];
    List<Meal> completedMeals = [];

    dayData.forEach((key, done) {
      final parts = key.split("_");
      if (parts.length < 2) return;

      final index = int.tryParse(parts[1]);
      if (index == null ||
          index >= _diet!.meals.length) return;

      if (done == true) {
        completedMeals.add(_diet!.meals[index]);
      } else {
        missedMeals.add(_diet!.meals[index]);
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Text("Meals on $date",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600)),

              const SizedBox(height: 10),

              ...missedMeals.map((m) =>
                  ListTile(
                    leading: const Icon(Icons.cancel,
                        color: Colors.red),
                    title: Text(m.mealName),
                    trailing:
                    Text("${m.calories} kcal"),
                  )),

              ...completedMeals.map((m) =>
                  ListTile(
                    leading: const Icon(Icons.check,
                        color: Colors.green),
                    title: Text(m.mealName),
                    trailing:
                    Text("${m.calories} kcal"),
                  )),
            ],
          ),
        );
      },
    );
  }

  /// 🔥 AI LOGIC
  String _generateSuggestion(int avg) {
    if (avg < 2000) {
      return "You are eating too little. Increase calorie intake for better weight gain.";
    } else if (avg < 3000) {
      return "Good progress, but slightly increase calories for faster gains.";
    } else {
      return "Excellent! You are on track for weight gain. Keep it consistent 💪";
    }
  }

  /// 🔥 ANALYTICS CARD
  Widget _analyticsCard(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColor.green400, AppColor.green700],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  /// 🧠 AI CARD
  Widget _aiCard(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome,
              color: Colors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                  color: Colors.white),
            ),
          )
        ],
      ),
    );
  }

  /// 🔥 UPDATED HISTORY CARD (ONLY ADDED TAP)
  Widget _historyCard(
      String date,
      int calories,
      int totalCalories,
      dynamic rawData) {

    return GestureDetector(
      onTap: () => _showMealDetails(date, rawData),

      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
            )
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                date,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColor.green400,
                    AppColor.green700
                  ],
                ),
                borderRadius:
                BorderRadius.circular(10),
              ),
              child: Text(
                "$calories / $totalCalories kcal",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}