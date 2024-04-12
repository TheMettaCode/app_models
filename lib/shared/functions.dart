import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

void launchLink({required BuildContext context, required String url}) async {
  if (await canLaunchUrl(Uri.parse(url))) {
    launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault);
  } else {
    if (context.mounted) {
      popMessage(
          context: context, message: "Could not launch link", isError: true);
    }
  }
}
