import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:schedula/Utils/app_color.dart';

import '../HomeScreen/db_data_getter.dart';
import 'day_card.dart';
import 'custom_schedule_screen.dart';

class DailyScheduleScreen extends StatefulWidget {
  const DailyScheduleScreen({super.key});

  @override
  State<DailyScheduleScreen> createState() => _DailyScheduleScreenState();
}

class _DailyScheduleScreenState extends State<DailyScheduleScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.green50,
      body: SafeArea(
        child: Column(
          children: [
            Hero(
              tag: 'dailySchedule',
              transitionOnUserGestures: true,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  height: 65,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            "Daily schedule",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      /// Open the custom schedule editor.
                      InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CustomScheduleScreen(
                              isDailySchedule: true,
                            ),
                          ),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: const HugeIcon(
                            icon: HugeIcons.strokeRoundedBookOpen02,
                            color: AppColor.green700,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: DataGetter.getDailySchedule(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    );
                  }

                  final schedule = snapshot.data!;

                  // Desired day order
                  const List<String> dayOrder = [
                    "monday",
                    "tuesday",
                    "wednesday",
                    "thursday",
                    "friday",
                    "saturday",
                    "sunday",
                  ];

                  // Convert map entries to list
                  final entries = schedule.entries.toList();

                  // Sort according to dayOrder
                  entries.sort((a, b) {
                    return dayOrder
                        .indexOf(a.key)
                        .compareTo(dayOrder.indexOf(b.key));
                  });

                  return ListView(
                    padding: const EdgeInsets.all(0),
                    children: entries.map((dayEntry) {
                      String day = dayEntry.key;
                      Map times = dayEntry.value;

                      List<MapEntry> sortedTimes = times.entries.toList();

                      sortedTimes.sort((a, b) {
                        String startA = a.key.split(" - ")[0].trim();
                        String startB = b.key.split(" - ")[0].trim();

                        DateTime timeA = DateFormat("hh:mm a").parse(startA);
                        DateTime timeB = DateFormat("hh:mm a").parse(startB);

                        return timeA.compareTo(timeB);
                      });

                      Map sortedMap = Map.fromEntries(sortedTimes);

                      return DayCard(day: day, times: sortedMap);
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
