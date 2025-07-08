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

/// AppBar customizada com padding no topo para evitar sobreposição com botões do sistema
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final double topPadding;

  const CustomAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.topPadding = 24, // Padding padrão no topo
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      color: backgroundColor ?? theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: AppBar(
          title: title,
          actions: actions,
          leading: leading,
          automaticallyImplyLeading: automaticallyImplyLeading,
          backgroundColor: Colors.transparent,
          foregroundColor: foregroundColor ?? theme.appBarTheme.foregroundColor,
          elevation: elevation,
          scrolledUnderElevation: 0,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + topPadding);
}

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

Future<bool?> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = "Confirmar",
  String cancelText = "Cancelar",
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
}
