import 'package:flutter/material.dart';

import 'constants.dart';
import 'widgets.dart';

void popMessage({
  required BuildContext context,
  required String message,
  required bool isError,
  Color? color,
}) {
  appLogger.d('[POP MESSAGE FUNCTION] GENERATING POP-UP MESSAGE *****');
  if (message.isNotEmpty) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context)
        .showSnackBar(snackbar(color, context, message));
  }
}
