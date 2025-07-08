import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:trabalho_bd/db/db_helper.dart';
import 'package:trabalho_bd/db/models/grupo_model.dart';
import 'package:trabalho_bd/db/models/usuario_model.dart';
import 'package:trabalho_bd/db/models/tarefa_model.dart';
import 'package:trabalho_bd/pages/forget_password_page.dart';
import 'package:trabalho_bd/pages/group_create_page.dart';
import 'package:trabalho_bd/pages/group_page.dart';
import 'package:trabalho_bd/pages/group_data_page.dart';
import 'package:trabalho_bd/pages/group_list_page.dart';
import 'package:trabalho_bd/pages/group_members_page.dart';
import 'package:trabalho_bd/pages/group_settings_page.dart';
import 'package:trabalho_bd/pages/home_page.dart';
import 'package:trabalho_bd/pages/main_layout.dart';
import 'package:trabalho_bd/pages/label_management_page.dart';
import 'package:trabalho_bd/pages/profile_page.dart';
import 'package:trabalho_bd/pages/sign_in_page.dart';
import 'package:trabalho_bd/pages/sign_up_page.dart';
import 'package:trabalho_bd/pages/task_page.dart';
import 'package:trabalho_bd/pages/task_create_page.dart';
import 'package:trabalho_bd/pages/task_edit_page.dart';

void main() async {
  await DatabaseHelper().mainConnection();

  runApp(const MyApp());
}

final lightScheme = ColorScheme.fromSeed(seedColor: Colors.green);

final darkScheme = ColorScheme.fromSeed(
  seedColor: Colors.green,
  brightness: Brightness.dark,
);

final theme = ThemeData(
  colorScheme: lightScheme,
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: lightScheme.surface,
    selectedItemColor: lightScheme.primary,
    unselectedItemColor: lightScheme.onSurface.withOpacity(0.6),
    selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
    type: BottomNavigationBarType.fixed,
  ),
);

final darkTheme = ThemeData(
  colorScheme: darkScheme,
  brightness: Brightness.dark,
  listTileTheme: ListTileThemeData(),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: darkScheme.surface,
    selectedItemColor: darkScheme.primary,
    unselectedItemColor: darkScheme.onSurface.withOpacity(0.6),
    selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
    type: BottomNavigationBarType.fixed,
  ),
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // English
        Locale('pt', 'BR'), // Portuguese (Brazil)
      ],
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
                return MainLayout(usuario: settings.arguments as Usuario);
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
          case "/groups":
            return MaterialPageRoute(
              settings: settings,
              builder: (context) {
                return GroupListPage(usuario: settings.arguments as Usuario);
              },
            );
          case "/group":
            return MaterialPageRoute(
              settings: settings,
              builder: (context) {
                final args = settings.arguments as Map<String, dynamic>;
                return GroupPage(
                  grupo: args['grupo'] as Grupo,
                  usuario: args['usuario'] as Usuario,
                );
              },
            );
          case "/group-members":
            return MaterialPageRoute(
              settings: settings,
              builder: (context) {
                final args = settings.arguments as Map<String, dynamic>;
                return GroupMembersPage(
                  grupo: args['grupo'] as Grupo,
                  usuarioLogado: args['usuario'] as Usuario,
                );
              },
            );
          case "/group-settings":
            return MaterialPageRoute(
              settings: settings,
              builder: (context) {
                final args = settings.arguments as Map<String, dynamic>;
                return GroupSettingsPage(
                  grupo: args['grupo'] as Grupo,
                  usuario: args['usuario'] as Usuario,
                );
              },
            );
          case "/label-management":
            return MaterialPageRoute(
              settings: settings,
              builder: (context) {
                final args = settings.arguments as Map<String, dynamic>;
                return LabelManagementPage(
                  grupoId: args['grupoId'] as String,
                  usuarioId: args['usuarioId'] as String,
                );
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
              builder: (context) => TaskDetailPage(),
            );
          case "/task-create":
            return MaterialPageRoute(
              settings: settings,
              builder: (context) {
                final args = settings.arguments as Map<String, dynamic>;
                return TaskCreate(
                  grupo: args['grupo'] as Grupo,
                  criador: args['criador'] as Usuario,
                );
              },
            );
          case "/task-edit":
            return MaterialPageRoute(
              settings: settings,
              builder: (context) {
                final args = settings.arguments as Map<String, dynamic>;
                return TaskEdit(
                  tarefa: args['tarefa'] as Tarefa,
                  grupo: args['grupo'] as Grupo,
                  usuario: args['usuario'] as Usuario,
                );
              },
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
