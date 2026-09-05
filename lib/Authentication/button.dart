import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Utils/app_color.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool isEnabled, isLoading;
  const CustomButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isEnabled = true,
    this.isLoading = false
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: !isLoading&&isEnabled ? onTap: null,
      splashColor: AppColor.green400,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
          decoration: BoxDecoration(
            color: isEnabled ? AppColor.green800: Colors.black12,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: !isLoading ? Text(
              text,
              style: GoogleFonts.poppins(
                color: isEnabled? Colors.white : Colors.black,
                fontSize: 18,
                letterSpacing: 1.2
              ),
            ) :
                SizedBox(
                  height: 26,
                  width: 26,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
          )
      ),
    );
  }
}
