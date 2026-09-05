import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'signup_screen.dart';
import '../Utils/app_color.dart';
import '../Utils/value_build_listener.dart';
import 'button.dart';
import '../custom_widget/snack_bar.dart';
import 'text_labels.dart';
import '../custom_widget/textfield.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final ValueNotifier<bool> _isPhoneValid = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
  }

  void _onPhoneChanged() {
    _isPhoneValid.value = _phoneController.text.trim().length == 10;
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _phoneController.dispose();
    _isPhoneValid.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    HapticFeedback.lightImpact();
    _isLoading.value = true;
    FirebaseAuth auth = FirebaseAuth.instance;
    final dbRef = FirebaseDatabase.instance.ref("users");
    final snapshot = await dbRef
        .orderByChild('profile/phone')
        .equalTo(_phoneController.text.toString())
        .get();
    if (!snapshot.exists) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: "Phone number not registered",
          type: SnackBarType.error,
        );
      }
      _isLoading.value = false;
      return;
    }
    await auth.verifyPhoneNumber(
      phoneNumber: '+91${_phoneController.text}',
      verificationCompleted: (PhoneAuthCredential credential) async {
        await auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        _isLoading.value = false;
      },
      codeSent: (String verificationId, int? resendToken) {
        CustomSnackBar.show(
          context,
          message: "OTP sent successfully",
          type: SnackBarType.success,
        );
        _isLoading.value = false;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpScreen(
              phoneNumber: _phoneController.text,
              verificationId: verificationId,
              resendToken: resendToken,
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (_) {},
    );
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
                    const SizedBox(height: 15),
                    const TitleText(text: 'Sign In'),
                    const SizedBox(height: 8),
                    const SubTitleText(text: 'Please sign in to continue'),
                    const SizedBox(height: 32),
                    CustomTextField(
                      hintText: 'Mobile Number',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: CupertinoIcons.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                    ),
                  ],
                ),
              ),
              ValueListenableBuilder2<bool, bool>(
                first: _isPhoneValid,
                second: _isLoading,
                builder: (context, valid, loading, _) {
                  return SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: "Send OTP",
                      onTap: _sendOtp,
                      isEnabled: valid,
                      isLoading: loading,
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              const SignUpButton(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class SignUpButton extends StatelessWidget {
  const SignUpButton({super.key});
  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SignUpScreen()),
          );
        },
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.resolveWith<Color?>((
              Set<WidgetState> states,
              ) {
            if (states.contains(WidgetState.pressed)) {
              return AppColor.green200.withOpacity(0.3);
            }
            return null;
          }),
        ),
        child: Text(
            "Don't have account? Sign Up",
            style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColor.green900,
              decoration: TextDecoration.underline,
            ),
        )
    );
  }
}
