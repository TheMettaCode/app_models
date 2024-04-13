import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

final BorderRadius defaultBorderRadius = BorderRadius.circular(5);
const List<Shadow> defaultFontDropShadow = [
  Shadow(offset: Offset(2, 2), blurRadius: 1)
];

Widget pageElement({
  required BuildContext context,
  String? titleText,
  required List<Widget> widgets,
  int? titleAnimationSeconds,
  bool showHeaderIcon = false,
  Color? titleColor,
  String? appIconAssetName,
  bool removeTopPadding = false,
  bool removeBottomPadding = false,
  double fontSize = 18,
  double maxContentWidth = maxContentWidth,
}) {
  var color = Theme.of(context).colorScheme;
  var primary = color.primary;
  var onPrimary = color.onPrimary;
  var tertiary = color.tertiary;
  var onTertiary = color.onTertiary;
  var secondary = color.secondary;
  var onSecondary = color.onSecondary;
  var error = color.error;
  var onError = color.onError;
  var surface = color.surface;
  var onSurface = color.onSurface;
  var background = color.background;
  var onBackground = color.onBackground;

  return FadeInUp(
    from: 10,
    child: Container(
      constraints: BoxConstraints(
        maxWidth: maxContentWidth,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
              !showHeaderIcon || appIconAssetName == null
                  ? const SizedBox.shrink()
                  : ElasticIn(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: SizedBox(
                          height: 100,
                          child: appIconStack(
                            appIconAssetName: appIconAssetName,
                            context: context,
                          ),
                        ),
                      ),
                    ),
              titleText == null
                  ? const SizedBox.shrink()
                  : Flash(
                      animate: titleAnimationSeconds != null,
                      duration: Duration(seconds: titleAnimationSeconds ?? 4),
                      child: Text(
                        titleText,
                        style: GoogleFonts.bangers(
                          letterSpacing: 1,
                          color: onPrimary,
                          fontSize: fontSize,
                          fontWeight: FontWeight.normal,
                          shadows: defaultFontDropShadow,
                        ),
                        // style: GoogleFonts.bangers(
                        //     letterSpacing: 0.5,
                        //     color: tColor,
                        //     fontSize: fontSize,
                        //     fontWeight: FontWeight.normal),
                        // style: wantedHeader.copyWith(
                        //     color: tColor, fontSize: fontSize),
                        textAlign: TextAlign.center,
                      ),
                    ),
            ] +
            [removeTopPadding ? const SizedBox.shrink() : spaceHeight10] +
            widgets +
            [removeBottomPadding ? const SizedBox.shrink() : spaceHeight10],
      ),
    ),
  );
}

Widget appIconStack({
  required BuildContext context,
  required String appIconAssetName,
  double? height,
  bool? infinite,
  bool? animate,
  int? durationSeconds,
}) {
  return Hero(
      tag: "app_icon_pulse",
      child: ElasticIn(
        // delay: const Duration(milliseconds: 500),
        child: SizedBox(
          height: height ?? 50,
          child: Stack(
            children: [
              Pulse(
                  duration: Duration(seconds: durationSeconds ?? 3),
                  child: Image.asset(appIconAssetName)),
            ],
          ),
        ),
      ));
}

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
