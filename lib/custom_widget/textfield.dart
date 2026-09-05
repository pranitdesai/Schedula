import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final double fontSize;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final bool isEnabled;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    required this.hintText,
    required this.controller,
    this.prefixIcon,
    required this.keyboardType,
    this.validator,
    this.inputFormatters,
    this.fontSize=18,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      keyboardType: keyboardType,
      cursorColor: Colors.black87,
      validator: validator,
      inputFormatters: inputFormatters,
      style: GoogleFonts.poppins(
        fontSize: fontSize,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.black87) : null,
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(color: Colors.black87, fontSize: fontSize),
        filled: true,
        fillColor: Colors.black12,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
