import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import '../../Utils/app_color.dart';
import '../../Utils/value_build_listener.dart';
import 'button.dart';
import '../../custom_widget/snack_bar.dart';
import '../../custom_widget/textfield.dart';
import 'text_labels.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Controllers
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final TextEditingController otpController;

  // State variables
  String _verificationId = "";

  // ValueNotifiers
  late final ValueNotifier<bool> isLoading;
  late final ValueNotifier<bool> isFormValid;
  late final ValueNotifier<bool> isOtpSent;
  late final ValueNotifier<bool> isOtpComplete;

  // Firebase instances (cached)
  late final FirebaseAuth _auth;

  // Pin themes
  late final PinTheme _defaultPinTheme;
  late final PinTheme _disabledPinTheme;
  late final TextStyle _textStyle;
  @override
  void initState() {
    super.initState();

    // Initialize controllers
    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    otpController = TextEditingController();

    // Initialize ValueNotifiers
    isLoading = ValueNotifier(false);
    isFormValid = ValueNotifier(false);
    isOtpSent = ValueNotifier(false);
    isOtpComplete = ValueNotifier(false);

    // Cache Firebase instances
    _auth = FirebaseAuth.instance;

    // Setup listeners
    otpController.addListener(_onOtpChanged);
    _textStyle = GoogleFonts.poppins(fontSize: 14, color: Colors.white);
    // Initialize pin themes
    _initializePinThemes();
  }

  void _initializePinThemes() {
    _defaultPinTheme = PinTheme(
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

    _disabledPinTheme = PinTheme(
      width: 50,
      height: 50,
      textStyle: const TextStyle(
        fontSize: 18,
        color: Colors.white,
        fontFamily: 'Poppins',
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        color: Colors.black12,
      ),
    );
  }

  void _onOtpChanged() {
    isOtpComplete.value = otpController.text.length == 6;
  }

  Future<void> _sendOtp() async {
    isLoading.value = true;
    if (!_isFormValid()) {
      isLoading.value = false;
      return;
    }
    final dbRef = FirebaseDatabase.instance.ref("users");
    final snapshot = await dbRef
        .orderByChild('profile/phone')
        .equalTo(phoneController.text.toString())
        .get();
    if (snapshot.exists) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: "Phone number is already registered",
          type: SnackBarType.error,
        );
      }
      isLoading.value = false;
      return;
    }
    if (phoneController.text.length != 10) {
      _showSnackBar(
        "Enter a valid 10-digit phone number",
        SnackBarType.warning,
      );
      return;
    }

    isLoading.value = true;

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: '+91${phoneController.text.trim()}',
        timeout: const Duration(seconds: 60),
        verificationCompleted: _onVerificationCompleted,
        verificationFailed: _onVerificationFailed,
        codeSent: _onCodeSent,
        codeAutoRetrievalTimeout: _onCodeAutoRetrievalTimeout,
      );
    } catch (e) {
      isLoading.value = false;
      _showSnackBar("Failed to send OTP: ${e.toString()}", SnackBarType.error);
    }
  }

  Future<void> _onVerificationCompleted(PhoneAuthCredential credential) async {
    try {
      await _auth.signInWithCredential(credential);
      isLoading.value = false;
      isOtpSent.value = true;
      _showSnackBar("Phone verified automatically", SnackBarType.success);
    } catch (e) {
      isLoading.value = false;
      _showSnackBar("Auto verification failed", SnackBarType.error);
    }
  }

  void _onVerificationFailed(FirebaseAuthException e) {
    isLoading.value = false;
    String errorMessage = "Verification failed";

    switch (e.code) {
      case 'invalid-phone-number':
        errorMessage = "Invalid phone number format";
        break;
      case 'too-many-requests':
        errorMessage = "Too many requests. Try again later";
        break;
      case 'quota-exceeded':
        errorMessage = "SMS quota exceeded";
        break;
      default:
        errorMessage = e.message ?? "Verification failed";
    }

    _showSnackBar(errorMessage, SnackBarType.error);
  }

  void _onCodeSent(String verificationId, int? resendToken) {
    _verificationId = verificationId;
    isLoading.value = false;
    isOtpSent.value = true;
    _showSnackBar("OTP sent successfully", SnackBarType.success);
  }

  void _onCodeAutoRetrievalTimeout(String verificationId) {
    _verificationId = verificationId;
    isLoading.value = false;
  }

  Future<void> _handleSignUp() async {
    isLoading.value = true;
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otpController.text,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final uid = userCredential.user?.uid;
      if (uid == null) {
        throw Exception("Failed to get user ID");
      }

      final DatabaseReference enrollDb = FirebaseDatabase.instance.ref().child(
        "users/$uid/profile",
      );
      final userData = {
        "email": emailController.text.trim(),
        "name": nameController.text.trim(),
        "phone": phoneController.text.trim(),
      };
      await enrollDb.set(userData);
      isLoading.value = false;
      _showSnackBar("Sign up successful!", SnackBarType.success);
      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      String errorMessage = "Sign up failed";

      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = "Invalid OTP. Please try again";
          break;
        case 'session-expired':
          errorMessage = "OTP expired. Please request a new one";
          break;
        default:
          errorMessage = e.message ?? "Sign up failed";
      }
      _showSnackBar(errorMessage, SnackBarType.error);
    } catch (e) {
      isLoading.value = false;
      _showSnackBar("Failed to sign up: ${e.toString()}", SnackBarType.error);
    }
  }

  void _showSnackBar(String message, SnackBarType type) {
    if (mounted) {
      CustomSnackBar.show(context, message: message, type: type);
    }
  }

  @override
  void dispose() {
    // Dispose controllers
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    otpController.dispose();

    // Dispose ValueNotifiers
    isOtpComplete.dispose();
    isFormValid.dispose();
    isLoading.dispose();
    isOtpSent.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 15),
                      const TitleText(text: 'Create Account'),
                      const SizedBox(height: 8),
                      const SubTitleText(text: 'Sign up to continue'),
                      const SizedBox(height: 32),
                      _buildNameField(),
                      const SizedBox(height: 16),
                      _buildEmailField(),
                      const SizedBox(height: 16),
                      _buildPhoneFieldWithOtpButton(),
                      const SizedBox(height: 16),
                      PinPutField(
                        controller: otpController,
                        defaultPinTheme: _defaultPinTheme,
                        disabledPinTheme: _disabledPinTheme,
                        isOtpSent: isOtpSent,
                      ),
                    ],
                  ),
                ),
              ),
              _buildSignUpButton(),
              const SizedBox(height: 4),
              const BuildSignInLink(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return CustomTextField(
      hintText: "Full Name",
      controller: nameController,
      prefixIcon: CupertinoIcons.person,
      keyboardType: TextInputType.name,
    );
  }

  Widget _buildEmailField() {
    return CustomTextField(
      hintText: "Email Address",
      controller: emailController,
      prefixIcon: CupertinoIcons.envelope,
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildPhoneFieldWithOtpButton() {
    return Row(
      children: [
        Expanded(
          child: CustomTextField(
            hintText: "Phone Number",
            controller: phoneController,
            prefixIcon: CupertinoIcons.phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ValueListenableBuilder<bool>(
          valueListenable: isLoading,
          builder: (context, loading, _) => SizedBox(
            width: 100,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.green700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onPressed: !loading ? _sendOtp : null,
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text("Send OTP", style: _textStyle),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return ValueListenableBuilder2<bool, bool>(
      first: isLoading,
      second: isOtpComplete,
      builder: (context, loading, otpComplete, _) => CustomButton(
        text: "Sign Up",
        onTap: otpComplete && !loading ? _handleSignUp : null,
        isLoading: loading,
        isEnabled: otpComplete,
      ),
    );
  }

  bool _isFormValid() {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty || name.length < 3) {
      _showSnackBar(
        "Enter a valid name (min 3 characters)",
        SnackBarType.warning,
      );
      return false;
    }

    if (email.isEmpty ||
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showSnackBar("Enter a valid email address", SnackBarType.warning);
      return false;
    }

    if (phone.isEmpty || !RegExp(r'^\d{10}$').hasMatch(phone)) {
      _showSnackBar(
        "Enter a valid 10-digit phone number",
        SnackBarType.warning,
      );
      return false;
    }

    return true;
  }
}

class BuildHeader extends StatelessWidget {
  const BuildHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Create Account",
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: AppColor.green900,
          ),
        ),
      ],
    );
  }
}

class BuildSignInLink extends StatelessWidget {
  const BuildSignInLink({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
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
        onPressed: () => Navigator.pop(context),
        child: Text(
          "Already have an account? Sign In",
          style: GoogleFonts.poppins(
              fontSize: 14, color: AppColor.green900,
            decoration: TextDecoration.underline
          ),
        ),
      ),
    );
  }
}

class PinPutField extends StatelessWidget {
  final TextEditingController controller;
  final PinTheme defaultPinTheme;
  final PinTheme? disabledPinTheme;
  final ValueNotifier<bool> isOtpSent;

  const PinPutField({
    super.key,
    required this.controller,
    required this.defaultPinTheme,
    required this.isOtpSent,
    this.disabledPinTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: RepaintBoundary(
        child: ValueListenableBuilder<bool>(
          valueListenable: isOtpSent,
          builder: (context, otpSent, _) => Pinput(
            controller: controller,
            length: 6,
            defaultPinTheme: defaultPinTheme,
            disabledPinTheme: disabledPinTheme,
            enabled: otpSent,
            showCursor: true,
            separatorBuilder: (_) => const SizedBox(width: 8),
            hapticFeedbackType: HapticFeedbackType.lightImpact,
            cursor: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 9),
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
      ),
    );
  }
}
