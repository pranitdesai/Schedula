class Meal {
  final String time;
  final String mealName;
  final List<String> items;
  final int calories;

  Meal({
    required this.time,
    required this.mealName,
    required this.items,
    required this.calories,
  });

  factory Meal.fromSnapshot(Map<dynamic, dynamic> data) {
    return Meal(
      time: data['time'] ?? '',
      mealName: data['meal_name'] ?? '',
      items: List<String>.from(data['items'] ?? []),
      calories: data['calories'] ?? 0,
    );
  }
}