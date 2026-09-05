import 'meal_modal.dart';

class Diet {
  final String goal;
  final String targetWeight;
  final String timeBound;
  final List<Meal> meals;
  final List<String> weeklyAddons;
  final List<String> importantNotes;

  Diet({
    required this.goal,
    required this.targetWeight,
    required this.timeBound,
    required this.meals,
    required this.weeklyAddons,
    required this.importantNotes,
  });

  factory Diet.fromSnapshot(Map<dynamic, dynamic> data) {
    List<Meal> mealsList = [];

    if (data['meals'] != null) {
      final mealsData = data['meals'];

      if (mealsData is Map) {
        mealsData.forEach((key, value) {
          mealsList.add(
              Meal.fromSnapshot(Map<dynamic, dynamic>.from(value)));
        });
      } else if (mealsData is List) {
        for (var value in mealsData) {
          if (value != null) {
            mealsList.add(
                Meal.fromSnapshot(Map<dynamic, dynamic>.from(value)));
          }
        }
      }
    }

    return Diet(
      goal: data['goal'] ?? '',
      targetWeight: data['target_weight'] ?? '',
      timeBound: data['time_bound'] ?? '',
      meals: mealsList,
      weeklyAddons: List<String>.from(data['weekly_addons'] ?? []),
      importantNotes:
      List<String>.from(data['important_notes'] ?? []),
    );
  }
}