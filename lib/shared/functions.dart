import 'package:flutter/material.dart';
import 'package:trabalho_bd/shared/widgets/screen_load.dart';

TextTheme texts(BuildContext context) => Theme.of(context).textTheme;

ColorScheme colors(BuildContext context) => Theme.of(context).colorScheme;

double width(BuildContext context) => MediaQuery.of(context).size.width;

double height(BuildContext context) => MediaQuery.of(context).size.height;

double perWidth(BuildContext context, double percent) =>
    width(context) * percent / 100;

double perHeight(BuildContext context, double percent) =>
    height(context) * percent / 100;

Future<void> executeWithLoad(
  BuildContext context,
  Future<void> Function() futureCallback,
) async {
  final overlay = Overlay.of(context);
  if (!overlay.mounted) {
    debugPrint('Overlay not found in the current context.');
    await futureCallback();
    return;
  }

  final entry = getScreenLoad();
  overlay.insert(entry);

  try {
    await futureCallback();
  } catch (e, s) {
    debugPrint('Error in executeWithLoad: $e\n$s');
    rethrow; // ou remove se não quiser propagar
  } finally {
    if (entry.mounted) entry.remove();
  }
}

void mostrarSnackBar(BuildContext context, String mensagem) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(mensagem), duration: Duration(seconds: 3)),
  );
}
