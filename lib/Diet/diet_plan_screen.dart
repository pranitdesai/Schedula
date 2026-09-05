import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../Utils/app_color.dart';
import 'diet_modal.dart';
import 'meal_modal.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({super.key});

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  late final DatabaseReference dietRef = FirebaseDatabase.instance.ref('diet/$uid');
  late final DatabaseReference trackingRef;

  final Map<int, bool> completedMeals = {};

  Diet? _diet;
  StreamSubscription<DatabaseEvent>? _dietSubscription;

  @override
  void initState() {
    super.initState();
    trackingRef = FirebaseDatabase.instance.ref('diet_tracking/$uid/${_today()}');
    _loadTracking();
    _dietSubscription = dietRef.onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final raw = event.snapshot.value;

        if (raw is Map) {
          setState(() {
            _diet = Diet.fromSnapshot(Map<dynamic, dynamic>.from(raw));
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _dietSubscription?.cancel();
    super.dispose();
  }

  String _today() {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }


  void _loadTracking() async {
    final snapshot = await trackingRef.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map;
      data.forEach((key, value) {
        int index = int.parse(key.split("_")[1]);
        completedMeals[index] = value;
      });
      if (mounted) setState(() {});
    }
  }

  void _toggleMeal(int index, bool isCurrentlyDone) async {
    setState(() {
      completedMeals[index] = !isCurrentlyDone;
    });
    await trackingRef.child("meal_$index").set(!isCurrentlyDone);
  }

  @override
  Widget build(BuildContext context) {
    if (_diet == null) {
      return const Scaffold(
        backgroundColor: Color(0xffF5F7FB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 🔥 OPTIMIZATION 2: Streamlined calculations
    int totalCalories = _diet!.meals.fold(0, (sum, m) => sum + m.calories);
    int consumedCalories = 0;
    int completedCount = 0;

    completedMeals.forEach((index, done) {
      if (done && index < _diet!.meals.length) {
        consumedCalories += _diet!.meals[index].calories;
        completedCount++;
      }
    });

    double progress = _diet!.meals.isEmpty ? 0 : completedCount / _diet!.meals.length;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 36, bottom: 20, left: 20, right: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColor.green400, AppColor.green700],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Diet Plan",
                        style: GoogleFonts.poppins(
                            fontSize: 22, color: Colors.white, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pushNamed(context, '/cal_history'),
                      icon: const HugeIcon(color: Colors.white, icon: HugeIcons.strokeRoundedTransactionHistory,),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(_diet!.goal, style: GoogleFonts.poppins(color: Colors.white70)),
                const SizedBox(height: 5),
                Text("Target Weight • ${_diet!.targetWeight}",
                    style: GoogleFonts.poppins(color: Colors.white70)),
                const SizedBox(height: 20),

                Text("$consumedCalories / $totalCalories kcal",
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),

                // 🔥 OPTIMIZATION 3: Modern Flutter 3.10+ removes the need for expensive ClipRRect layers
                LinearProgressIndicator(
                  value: totalCalories == 0 ? 0 : consumedCalories / totalCalories,
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(10), // Safe if Flutter SDK >= 3.10
                ),
                const SizedBox(height: 10),

                Text("${(progress * 100).toInt()}% completed",
                    style: GoogleFonts.poppins(color: Colors.white)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SectionTitle(title: "Meals 🍽"),
                const SizedBox(height: 10),

                ..._diet!.meals.asMap().entries.map((entry) {
                  return MealCard(
                    meal: entry.value,
                    index: entry.key,
                    isDone: completedMeals[entry.key] ?? false,
                    onTap: () => _toggleMeal(entry.key, completedMeals[entry.key] ?? false),
                  );
                }),

                const SizedBox(height: 20),
                const SectionTitle(title: "Weekly Add-ons"),
                InfoListCard(items: _diet!.weeklyAddons),

                const SizedBox(height: 20),
                const SectionTitle(title: "Important Notes"),
                InfoListCard(items: _diet!.importantNotes),
              ],
            ),
          )
        ],
      ),
    );
  }

}

// 🔥 OPTIMIZATION 4: Extracted Stateless Widgets
// This prevents untouched list items from rebuilding when a single card is tapped.

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600));
  }
}

class MealCard extends StatelessWidget {
  final Meal meal;
  final int index;
  final bool isDone;
  final VoidCallback onTap;

  const MealCard({
    super.key,
    required this.meal,
    required this.index,
    required this.isDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      // 🔥 OPTIMIZATION 5: Swapped AnimatedContainer for standard Container.
      // Root decorations and shadows shouldn't be checked for animation loops unless they actually change.
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xF2FFFFFF), // Constant hex for Colors.white.withOpacity(0.95)
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000), // Constant hex for Colors.black.withOpacity(0.06)
              blurRadius: 14,
              offset: Offset(0, 8),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? Colors.green : Colors.grey.shade200,
                  ),
                  child: Icon(
                    isDone ? Icons.check : Icons.circle,
                    size: 18,
                    color: isDone ? Colors.white : Colors.grey,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meal.mealName,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      Text(meal.time,
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDone
                          ? const [Colors.green, Colors.greenAccent]
                          : [Colors.grey.shade300, Colors.grey.shade400],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${meal.calories} kcal",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDone ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...meal.items.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle,
                      size: 6, color: isDone ? Colors.green : Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(e,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.black87)),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                children: [
                  Icon(
                    isDone ? Icons.check_circle : Icons.pending_actions,
                    size: 16,
                    color: isDone ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isDone ? "Completed" : "Pending",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDone ? Colors.green : Colors.orange,
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class InfoListCard extends StatelessWidget {
  final List<String> items;
  const InfoListCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000), // Constant hex for Colors.black.withOpacity(0.05)
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        children: items
            .map((e) => Align(
          alignment: Alignment.centerLeft,
          child: Text("• $e", style: GoogleFonts.poppins()),
        ))
            .toList(),
      ),
    );
  }
}