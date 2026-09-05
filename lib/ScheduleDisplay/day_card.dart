import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:schedula/Utils/app_color.dart';

class DayCard extends StatelessWidget {
  final String day;
  final Map<dynamic, dynamic> times;

  const DayCard({
    super.key,
    required this.day,
    required this.times,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // --- HEADER SECTION ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColor.green100,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color:AppColor.green700,
                ),
                const SizedBox(width: 10),
                Text(
                  day.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2, // Adds a polished look to uppercase text
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // --- BODY SECTION ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: times.entries.map((entry) {
                final isLast = entry.key == times.entries.last.key;

                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),

                      // Value (e.g., "09:00 AM - 01:00 PM")
                      Expanded(
                        child: Text(
                          entry.value.toString(),
                          textAlign: TextAlign.right,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),

                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}