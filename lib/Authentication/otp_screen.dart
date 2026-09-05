import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';

import '../../Utils/app_color.dart';
import '../../Utils/value_build_listener.dart';
import '../HomeScreen/home_screen.dart';
import 'button.dart';
import '../../custom_widget/snack_bar.dart';
import 'text_labels.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final int? resendToken;


  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    required this.resendToken
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  late final TextEditingController controller ;
  late final ValueNotifier<bool> _isOtpComplete, _isLoading;
  late final PinTheme _defaultPinTheme = PinTheme(
    width: 50,
    height: 50,
    textStyle: const TextStyle(
      fontSize: 18,
      color: Colors.white,
      fontFamily: 'Poppins',
    ),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColor.green700),
    ),
  );
  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    _isOtpComplete = ValueNotifier(false);
    _isLoading = ValueNotifier(false);
    controller.addListener(() {
      _isOtpComplete.value = controller.text.length == 6;
    });
  }
  @override
  void dispose() {
    controller.dispose();
    _isOtpComplete.dispose();
    _isLoading.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      const TitleText(text: 'OTP Verification',),
                      const SizedBox(height: 6),
                      SubTitleText(text: 'Enter the code from sms we sent to +91${widget.phoneNumber}'),
                      const SizedBox(height: 24),
                      PinPutField(
                          controller: controller,
                          defaultPinTheme: _defaultPinTheme,
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
                ValueListenableBuilder2<bool, bool>(
                  first: _isOtpComplete,
                  second: _isLoading,
                  builder: (context, isComplete, isLoading, _) {
                    return CustomButton(
                      text: "Verify OTP",
                      onTap: isComplete && !isLoading ? _verifyOtp : null,
                      isEnabled: isComplete && !isLoading,
                      isLoading: isLoading,
                    );
                  },
                ),
                SizedBox(height: 16)
              ],
            ),
          )
      ),
    );
  }
  void _verifyOtp() async {
    HapticFeedback.lightImpact();
    _isLoading.value = true;
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: controller.text,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
        (route) => false,
      );
      _isLoading.value = false;
      CustomSnackBar.show(
          context,
          message: "Logged in successfully",
          fromTop: false,
          type: SnackBarType.success
      );
    } catch (e) {
      _isLoading.value = false;
      CustomSnackBar.show(
          context,
          message: "Wrong OTP entered",
          type: SnackBarType.error
      );
    }
  }
}
class PinPutField extends StatelessWidget {
  final TextEditingController controller;
  final PinTheme defaultPinTheme;

  const PinPutField({
    super.key,
    required this.controller,
    required this.defaultPinTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 20),
      child: RepaintBoundary(
        child: Pinput(
          controller: controller,
          length: 6,
          defaultPinTheme: defaultPinTheme,
          showCursor: true,
          separatorBuilder: (index) => SizedBox(width: 8),
          hapticFeedbackType: HapticFeedbackType.lightImpact,
          cursor: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                margin: EdgeInsets.only(bottom: 9),
                width: 22,
                height: 1,
                color: AppColor.green700,
              ),
            ],
          ),
          focusedPinTheme: defaultPinTheme.copyWith(
            decoration: defaultPinTheme.decoration!.copyWith(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColor.green700),
            ),
          ),
          submittedPinTheme: defaultPinTheme.copyWith(
            decoration: defaultPinTheme.decoration!.copyWith(
              color: AppColor.green700,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white),
            ),
          ),
          errorPinTheme: defaultPinTheme.copyBorderWith(
            border: Border.all(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }
}