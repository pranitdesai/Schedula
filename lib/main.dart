import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:schedula/Diet/calories_history.dart';
import 'package:schedula/Diet/diet_plan_screen.dart';
import 'package:schedula/Utils/app_color.dart';
import 'Wrapper/login_wrapper.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const Schedula());
}

class Schedula extends StatelessWidget{
  const Schedula({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColor.green700)
      ),
      routes: {
        '/diet_plan':(context)=>DietScreen(),
        '/cal_history':(context)=>CalorieHistoryScreen(),
      },
      debugShowCheckedModeBanner: false,
      home: LoginWrapper(),
    );
  }
}
