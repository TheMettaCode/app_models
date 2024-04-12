import 'package:flutter/material.dart';

SnackBar snackbar(Color? color, BuildContext context, String message) {
  return SnackBar(
    elevation: 0,
    backgroundColor: color ?? Theme.of(context).colorScheme.error,
    content: Padding(
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
      child: Container(
        padding: const EdgeInsets.all(5),
        child: Text(message.toUpperCase(),
            style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.normal),
            textAlign: TextAlign.center),
      ),
    ),
  );
}
