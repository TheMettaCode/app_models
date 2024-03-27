import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

/// FUNCTION CONSTANTS
const int appAlertsApiResponseTimeoutSeconds = 15;
final Logger logger = Logger();
const String appAlertsEndpoint = "mettacode-notifications.json";
const String appAlertsDataName = "mettacode_notifications";

/// DATA NOTIFIER
ValueNotifier<List<AppAlert>> appAlertsNotifier = ValueNotifier([]);

class AppAlertFunctions {
  static Future<List<AppAlert>> getApplicationAlerts(
      {required String appNameTag, bool isInit = false}) async {
    final DateTime now = DateTime.now();
    List<AppAlert> finalAlertsList = [];

    if (isInit) {
      try {
        final Map<String, String> headers = {"Accept": "application/json"};
        final response = await http
            .get(
                Uri.parse(
                    "https://themettacode.github.io/mettacode-app-data-api/$appAlertsEndpoint"),
                headers: headers)
            .timeout(
                const Duration(seconds: appAlertsApiResponseTimeoutSeconds));
        logger.d(
            '[APP ALERTS API] GITHUB MSG API RESPONSE CODE: ${response.statusCode} *****');
        if (response.statusCode == 200) {
          AppAlertData appAlertData = appAlertDataFromJson(response.body);

          if (appAlertData.status == "OK" &&
              appAlertData.name == appAlertsDataName) {
            logger.d('[APP ALERTS API] APP ALERTS DATA RETRIEVED');

            List<AppAlert> rawAppAlerts = appAlertData.alerts;

            /// PRUNE AND SORT
            List<AppAlert> activeAlerts = await pruneAndSortAppAlerts(
                list: rawAppAlerts, now: now, appNameTag: appNameTag);

            logger.d(
                '[APP ALERTS API] ${activeAlerts.length} ACTIVE NOTIFICATIONS RETRIEVED');

            finalAlertsList = activeAlerts;
          } else {
            logger.d(
                '[APP ALERTS API]  GITHUB DATA ERROR: DATA APP => ${appAlertData.name} | DATA STATUS => ${appAlertData.status}');
          }
        } else {
          logger.d(
              '[APP ALERTS API] GITHUB MSG API CALL ERROR WITH RESPONSE CODE: ${response.statusCode}');
        }
      } catch (e) {
        throw ('[APP ALERTS API] GITHUB MSG API ERROR');
      }
    } else {
      logger
          .d('[APP ALERTS API] APP IS NOT IN FIRST LOAD INITIALIZATION STATE.');
    }
    return finalAlertsList;
  }

  /// PRUNE AND SORT NOTIFICATIONS
  static Future<List<AppAlert>> pruneAndSortAppAlerts(
      {required List<AppAlert> list,
      required String appNameTag,
      required DateTime now}) async {
    logger.d(
        '[APP ALERTS API] [PRUNE & SORT] PRUNING ${list.length} GITHUB PROMO NOTIFICATIONS');

    list.retainWhere((element) =>
            element.isActive &&
            element.application.any((app) => app == appNameTag) &&
            element.startDate.isBefore(now) &&
            (element.expirationDate.toString().isEmpty ||
                element.expirationDate.isAfter(now))
        //     &&
        // element.userLevels.contains(githubApiUserLevel)
        );

    list.sort((a, b) => a.priority.compareTo(b.priority));

    logger.d('[APP ALERTS API] [PRUNE & SORT] ${list.length} ALERTS REMAIN');
    return list;
  }
}

// To parse this JSON data, do
//
//     final githubMessages = githubMessagesFromJson(jsonString);

AppAlertData appAlertDataFromJson(String str) =>
    AppAlertData.fromJson(json.decode(str));

String appAlertDataToJson(AppAlertData data) => json.encode(data.toJson());

class AppAlertData {
  AppAlertData({
    required this.name,
    required this.status,
    required this.alerts,
  });

  final String name;
  final String status;
  final List<AppAlert> alerts;

  factory AppAlertData.fromJson(Map<String, dynamic> json) => AppAlertData(
        name: json["name"],
        status: json["status"] ?? "ERR",
        alerts: List<AppAlert>.from(
            json["alerts"].map((x) => AppAlert.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "status": status,
        "alerts": List<dynamic>.from(alerts.map((x) => x.toJson())),
      };
}

class AppAlert {
  AppAlert({
    required this.startDate,
    required this.expirationDate,
    required this.title,
    required this.message,
    required this.priority,
    required this.userLevels,
    required this.application,
    required this.market,
    required this.url,
    required this.icon,
    required this.supportOption,
    required this.loadingScreen,
    required this.localNotification,
    required this.isAlert,
    required this.additionalData,
    required this.isActive,
    required this.locality,
    required this.isPopUp,
  });

  final DateTime startDate;
  final DateTime expirationDate;
  final String title;
  final String message;
  final int priority;
  final List<String> userLevels;
  final List<String> application;
  final List<String> market;
  final String url;
  final String icon;
  final bool supportOption;
  final bool loadingScreen;
  final bool localNotification;
  final bool isAlert;
  final String additionalData;
  final List<String> locality;
  final bool isActive;
  final bool isPopUp;

  factory AppAlert.fromJson(Map<String, dynamic> json) => AppAlert(
        startDate: json["start_date"] == null || json["start_date"] == ""
            ? DateTime.now()
            : DateTime.parse(json["start_date"]),
        expirationDate:
            json["expiration_date"] == null || json["expiration_date"] == ""
                ? DateTime.now().add(const Duration(days: 1))
                : DateTime.parse(json["expiration_date"]),
        title: json["title"] ?? "",
        message: json["message"] ?? "",
        priority: json["priority"] ?? 99,
        userLevels: List<String>.from(json["user_levels"].map((x) => x)),
        application: List<String>.from(json["application"].map((x) => x)),
        market: List<String>.from(json["market"].map((x) => x)),
        url: json["url"] ?? "",
        icon: json["icon"] ?? "handshake",
        supportOption: json['support_option'] ?? false,
        loadingScreen: json['loading_screen'] ?? false,
        localNotification: json["local_notification"] ?? false,
        isAlert: json['is_alert'] ?? false,
        additionalData: json["additional_data"] ?? "",
        isActive: json["is_active"] ?? false,
        isPopUp: json["is_popup"] ?? false,
        locality: List<String>.from(json["locality"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "start_date": startDate.toIso8601String(),
        "expiration_date": expirationDate.toIso8601String(),
        "title": title,
        "message": message,
        "priority": priority,
        "user_levels": List<dynamic>.from(userLevels.map((x) => x)),
        "application": List<dynamic>.from(application.map((x) => x)),
        "market": List<dynamic>.from(market.map((x) => x)),
        "url": url,
        "icon": icon,
        "support_option": supportOption,
        "loading_screen": loadingScreen,
        "local_notification": localNotification,
        "is_alert": isAlert,
        "additional_data": additionalData,
        "is_active": isActive,
        "is_popup": isPopUp,
        "locality": List<dynamic>.from(locality.map((x) => x)),
      };
}
