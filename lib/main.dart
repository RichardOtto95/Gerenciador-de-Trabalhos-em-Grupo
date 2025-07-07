import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:trabalho_bd/db/db_helper.dart';
import 'package:trabalho_bd/db/models/grupo_model.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';
import 'package:trabalho_bd/pages/forget_password_page.dart';
import 'package:trabalho_bd/pages/group_create_page.dart';
import 'package:trabalho_bd/pages/group_page.dart';
import 'package:trabalho_bd/pages/group_data_page.dart';
import 'package:trabalho_bd/pages/home_page.dart';
import 'package:trabalho_bd/pages/profile_page.dart';
import 'package:trabalho_bd/pages/sign_in_page.dart';
import 'package:trabalho_bd/pages/sign_up_page.dart';
import 'package:trabalho_bd/pages/task_page.dart';

void main() async {
  await DatabaseHelper().mainConnection();

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
      scrollBehavior: CustomScrollBehavior(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case "/":
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => SignIn(),
            );
          case "/home":
            return MaterialPageRoute(
              settings: settings,

              builder: (context) {
                return Home(usuario: settings.arguments as Usuario);
              },
            );
          case "/signin":
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => SignIn(),
            );
          case "/signup":
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => SignUp(),
            );
          case "/forget-password":
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => ForgetPassword(),
            );
          case "/profile":
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => Profile(),
            );
          case "/group-create":
            return MaterialPageRoute(
              settings: settings,
              builder: (context) {
                return GroupCreate(criador: settings.arguments as Usuario);
              },
            );
          case "/group":
            return MaterialPageRoute(
              settings: settings,
              builder: (context) {
                return GroupPage(grupo: settings.arguments as Grupo);
              },
            );
          case "/group-data":
            return MaterialPageRoute(
              settings: settings,
              builder: (context) {
                return GroupData(grupo: settings.arguments as Grupo);
              },
            );
          case "/task":
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => Task(),
            );
          default:
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => SignIn(),
            );
        }
      },
    );
  }
}

class CustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.mouse,
    PointerDeviceKind.touch,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}
