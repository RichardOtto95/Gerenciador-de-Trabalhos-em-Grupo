import 'package:flutter/material.dart';
import 'package:trabalho_bd/pages/forget_password.dart';
import 'package:trabalho_bd/pages/home.dart';
import 'package:trabalho_bd/pages/sign_in.dart';
import 'package:trabalho_bd/pages/sign_up.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Class Work',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      routes: {
        "/": (ctx) => SignIn(),
        "/home": (ctx) => Home(),
        "/signin": (ctx) => SignIn(),
        "/signup": (ctx) => SignUp(),
        "/forget-password": (ctx) => ForgetPassword(),
      },
    );
  }
}
