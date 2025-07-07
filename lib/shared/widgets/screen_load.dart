import 'package:flutter/material.dart';
import 'package:trabalho_bd/shared/functions.dart';

OverlayEntry getScreenLoad() => OverlayEntry(
  builder: (context) {
    return Container(
      height: height(context),
      width: width(context),
      color: Colors.black.withValues(alpha: .3),
      alignment: Alignment.center,
      child: CircularProgressIndicator(),
    );
  },
);
