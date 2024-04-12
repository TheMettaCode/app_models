import 'dart:async';
import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'shared/constants.dart';
import 'shared/functions.dart';

/// FUNCTION CONSTANTS
const String adCreativesEndpoint = "ad-creatives.json";
const String adCreativesDataName = "ad_creatives";

/// DATA NOTIFIER
ValueNotifier<List<AdCreatives>> adCreativesNotifier = ValueNotifier([]);

class AdCreativeWidgets {
  static Widget bannerAdContainer() => ValueListenableBuilder(
      valueListenable: adCreativesNotifier,
      builder: (context, ads, widget) {
        if (ads.isNotEmpty) {
          ads.shuffle();
          var thisAdCreative = ads.first;
          return SizedBox(
            height: 55,
            child: FadeIn(
              delay: const Duration(milliseconds: 2000),
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Tooltip(
                  message: thisAdCreative.altText,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flash(
                        infinite: false,
                        duration: const Duration(milliseconds: 5000),
                        delay: const Duration(milliseconds: 4000),
                        child: InkWell(
                          onTap: () async {
                            launchLink(
                                context: context, url: thisAdCreative.linkUrl);
                          },
                          onDoubleTap: null,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Stack(
                              alignment: Alignment.centerRight,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: Image.network(
                                    thisAdCreative.creativeUrl,
                                    fit: BoxFit.fitHeight,

                                    ///
                                    frameBuilder: (BuildContext context,
                                        Widget child,
                                        int? frame,
                                        bool? wasSynchronouslyLoaded) {
                                      return Flash(
                                        duration:
                                            const Duration(milliseconds: 80),
                                        child: child,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // spaceWidth5,
                      Icon(
                        FontAwesomeIcons.adversal,
                        size: 15,
                        color: Colors.blue.shade900,
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      });
}

class AdCreativeFunctions {
  static Future<List<AdCreatives>> getGithubAdCreatives(
      {required String appNameTag}) async {
    final DateTime now = DateTime.now();
    List<AdCreatives> activeAdCreatives = [];
    try {
      final Map<String, String> headers = {"Accept": "application/json"};
      final response = await http
          .get(
              Uri.parse(
                  "https://themettacode.github.io/mettacode-app-data-api/$adCreativesEndpoint"),
              headers: headers)
          .timeout(const Duration(seconds: appApiResponseTimeoutSeconds));
      appLogger.d(
          '[GITHUB AD CREATIVES API] GITHUB ADS API RESPONSE CODE: ${response.statusCode} *****');
      // appLogger.d('\n[GITHUB AD CREATIVES API] ${response.body}');
      if (response.statusCode == 200) {
        try {
          appLogger.w('[GITHUB AD CREATIVES API] MAPPING RETRIEVED DATA');
          AdCreativesData adCreativesData = adCreativesFromJson(response.body);
          if (adCreativesData.status == "OK" &&
              adCreativesData.name == adCreativesDataName) {
            appLogger.d(
                '[GITHUB AD CREATIVES API] GITHUB NOTIFIACATION DATA RETRIEVED');

            List<AdCreatives> rawGithubAdCreatives = adCreativesData.creatives;

            /// PRUNE AND SORT
            List<AdCreatives> sortedCreatives = await pruneAndSortAdCreatives(
                adCreativesList: rawGithubAdCreatives,
                dateTime: now,
                appNameTag: appNameTag);

            appLogger.d(
                '[GITHUB AD CREATIVES API] ${sortedCreatives.length} SORTED ADS RETRIEVED');
            adCreativesNotifier.value = sortedCreatives;
            activeAdCreatives = sortedCreatives;
          } else {
            appLogger.d(
                '[GITHUB AD CREATIVES API]  GITHUB DATA ERROR: DATA APP => ${adCreativesData.name} | DATA STATUS => ${adCreativesData.status}');
            // return [];
          }
        } catch (e) {
          appLogger.e('[GITHUB AD CREATIVES API] GITHUB ADS API ERROR: $e');
        }
      } else {
        appLogger.d(
            '[GITHUB AD CREATIVES API] GITHUB ADS API CALL ERROR WITH RESPONSE CODE: ${response.statusCode}');
        // return [];
      }
    } catch (e) {
      throw ('[GITHUB AD CREATIVES API] GITHUB ADS API ERROR');
      // return [];
    }
    // adCreativesNotifier.value = activeAdCreatives;
    return activeAdCreatives;
  }

  /// PRUNE AND SORT NOTIFICATIONS
  static Future<List<AdCreatives>> pruneAndSortAdCreatives(
      {required String appNameTag,
      required List<AdCreatives> adCreativesList,
      required DateTime dateTime}) async {
    appLogger.d(
        '[GITHUB AD CREATIVES API] [PRUNE & SORT] PRUNING ${adCreativesList.length} GITHUB AD CREATIVES');

    adCreativesList
        .sort((a, b) => a.frequencyPriority.compareTo(b.frequencyPriority));

    adCreativesList.retainWhere((element) =>
        element.applications.any((app) => app == appNameTag) &&
        element.startDate.isBefore(dateTime) &&
        (element.expirationDate == null ||
            (element.expirationDate != null &&
                    element.expirationDate.toString().isEmpty ||
                (element.expirationDate != null &&
                    element.expirationDate!.isAfter(dateTime)))));

    appLogger.d(
        '[GITHUB NOTIFICATIONS API] [PRUNE & SORT] ${adCreativesList.length} GITHUB PROMO NOTIFICATIONS REMAIN');
    return adCreativesList;
  }
}

// To parse this JSON data, do
//
//     final githubMessages = githubMessagesFromJson(jsonString);

AdCreativesData adCreativesFromJson(String str) =>
    AdCreativesData.fromJson(json.decode(str));

String adCreativesToJson(AdCreativesData data) => json.encode(data.toJson());

class AdCreativesData {
  AdCreativesData({
    required this.name,
    required this.status,
    required this.creatives,
  });

  final String name;
  final String status;
  final List<AdCreatives> creatives;

  factory AdCreativesData.fromJson(Map<String, dynamic> json) =>
      AdCreativesData(
        name: json["name"],
        status: json["status"] ?? "ERR",
        creatives: List<AdCreatives>.from(
            json["creatives"].map((x) => AdCreatives.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "status": status,
        "creatives": List<dynamic>.from(creatives.map((x) => x.toJson())),
      };
}

class AdCreatives {
  AdCreatives({
    required this.clientName,
    required this.clientId,
    required this.clientDescription,
    required this.clientInternalNotes,
    required this.startDate,
    required this.expirationDate,
    required this.isActive,
    required this.title,
    required this.altText,
    required this.frequencyPriority,
    required this.durationInDays,
    required this.applications,
    required this.markets,
    required this.locality,
    required this.linkUrl,
    required this.creativeUrl,
    required this.creativeHeight,
    required this.creativeWidth,
  });

  final String clientName;
  final dynamic clientId;
  final String? clientDescription;
  final String? clientInternalNotes;
  final DateTime startDate;
  final DateTime? expirationDate;
  final bool isActive;
  final String title;
  final String? altText;
  final int frequencyPriority;
  final int? durationInDays;
  final List<String> applications;
  final List<String> markets;
  final List<String> locality;
  final String linkUrl;
  final String creativeUrl;
  final int? creativeHeight;
  final int? creativeWidth;

  factory AdCreatives.fromJson(Map<String, dynamic> json) => AdCreatives(
        clientName: "client_name",
        clientId: "client_id",
        clientDescription: "client_description",
        clientInternalNotes: "client_internal_notes",
        startDate: json["start_date"] == null || json["start_date"] == ""
            ? DateTime.now()
            : DateTime.parse(json["start_date"]),
        expirationDate:
            json["expiration_date"] == null || json["expiration_date"] == ""
                ? DateTime.now().add(const Duration(days: 1))
                : DateTime.parse(json["expiration_date"]),
        isActive: json["is_active"] ?? false,
        title: json["title"] ?? "",
        altText: json["alt_Text"] ?? "",
        frequencyPriority: json["frequency_priority"] ?? 99,
        durationInDays: json["duration_in_days"],
        applications: List<String>.from(json["applications"].map((x) => x)),
        markets: List<String>.from(json["markets"].map((x) => x)),
        locality: List<String>.from(json["locality"].map((x) => x)),
        linkUrl: json["link_url"],
        creativeUrl: json["creative_url"],
        creativeHeight: json["creative_height"],
        creativeWidth: json["creative_width"],
      );

  Map<String, dynamic> toJson() => {
        "client_name": clientName,
        "client_id": clientId,
        "client_description": clientDescription,
        "client_internal_notes": clientInternalNotes,
        "start_date": startDate.toIso8601String(),
        "expiration_date": expirationDate?.toIso8601String(),
        "is_active": isActive,
        "title": title,
        "alt_text": altText,
        "frequency_priority": frequencyPriority,
        "duration_in_days": durationInDays,
        "applications": List<dynamic>.from(applications.map((x) => x)),
        "markets": List<dynamic>.from(markets.map((x) => x)),
        "locality": List<dynamic>.from(locality.map((x) => x)),
        "link_url": linkUrl,
        "creative_url": creativeUrl,
        "creative_height": creativeHeight,
        "creative_width": creativeWidth,
      };
}
