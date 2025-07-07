import 'package:flutter/material.dart';
import 'package:trabalho_bd/pages/forget_password_page.dart';
import 'package:trabalho_bd/pages/group_page.dart';
import 'package:trabalho_bd/pages/group_data_page.dart';
import 'package:trabalho_bd/pages/home_page.dart';
import 'package:trabalho_bd/pages/profile_page.dart';
import 'package:trabalho_bd/pages/sign_in_page.dart';
import 'package:trabalho_bd/pages/sign_up_page.dart';
import 'package:trabalho_bd/pages/task_page.dart';

void main() {
  runApp(const MyApp());
}

final lightScheme = ColorScheme.fromSeed(seedColor: Colors.green);

final darkScheme = ColorScheme.fromSeed(
  seedColor: Colors.green,
  brightness: Brightness.dark,
);

final theme = ThemeData(colorScheme: lightScheme);

final darkTheme = ThemeData(
  colorScheme: darkScheme,
  brightness: Brightness.dark,
  listTileTheme: ListTileThemeData(),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Class Work',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: darkTheme,
      routes: {
        "/": (ctx) => SignIn(),
        "/home": (ctx) => Home(),
        "/signin": (ctx) => SignIn(),
        "/signup": (ctx) => SignUp(),
        "/forget-password": (ctx) => ForgetPassword(),
        "/profile": (ctx) => Profile(),
        "/group": (ctx) => GroupPage(),
        "/group-data": (ctx) => GroupData(),
        "/task": (ctx) => Task(),
      },
    );
  }
}
