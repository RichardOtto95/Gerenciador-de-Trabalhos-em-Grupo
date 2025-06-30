import 'package:flutter/material.dart';

class Button extends StatelessWidget {
  const Button({super.key, required this.label, required this.onTap});
  final String label;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      child: Text(label),
      style: ButtonStyle(
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 60, vertical: 20),
        ),
      ),
    );
  }
}
