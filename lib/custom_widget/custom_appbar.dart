import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Utils/app_color.dart';

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/logo.svg',
            height: 56,
            width: 56,
          ),
          const SizedBox(width: 18),
          Text(
            'Desai Farms',
            style: GoogleFonts.poppins(
              fontSize: 27,
              color: AppColor.green900,
            ),
          ),
        ],
      ),
    );
  }

}