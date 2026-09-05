import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TaskCard extends StatelessWidget {
  final String title;
  final String category;
  final String date;

  const TaskCard({
    super.key,
    required this.title,
    required this.category,
    required this.date,
  });

  static const List<Color> cardColors = [
    Colors.pink,
    Colors.green,
    Colors.blue,
  ];

  @override
  Widget build(BuildContext context) {

    final Map<String, Color> categoryColors = {
      'pending': cardColors[0],
      'in progress': cardColors[2],
      'completed': cardColors[1],
    };

    final Color accentColor =
        categoryColors[category.toLowerCase()] ?? cardColors[0];

    return SizedBox(
      width: 170,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        clipBehavior: Clip.none,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Stack(
          children: [

            Positioned(
              left: 0,
              top: 1,
              bottom: 1,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    category,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: accentColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    date,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
