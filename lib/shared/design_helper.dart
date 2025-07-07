import 'package:flutter/material.dart';

TextTheme texts(BuildContext context) => Theme.of(context).textTheme;

ColorScheme colors(BuildContext context) => Theme.of(context).colorScheme;

double width(BuildContext context) => MediaQuery.of(context).size.width;

double height(BuildContext context) => MediaQuery.of(context).size.height;

double perWidth(BuildContext context, double percent) =>
    width(context) * percent / 100;

double perHeight(BuildContext context, double percent) =>
    height(context) * percent / 100;
