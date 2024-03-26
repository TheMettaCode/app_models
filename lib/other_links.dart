import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

/// FUNCTION CONSTANTS
const int apiResponseTimeoutSeconds = 15;
final Logger log = Logger();
const String otherLinksEndpoint = "other-links.json";

/// DATA NOTIFIER
ValueNotifier<GithubOLApplications> githubApplicationsNotifier =
    ValueNotifier(GithubOLApplications(allData: [], thisApplication: null));

/// OTHER LINKS FUNCTIONS
class OLFunctions {
  static Future<GithubOLApplications> getOtherLinks(
      {required BuildContext context,
      required String applicationNameTag}) async {
    GithubOLApplications githubOLApplications =
        GithubOLApplications(allData: [], thisApplication: null);
    try {
      final Map<String, String> headers = {"Accept": "application/json"};
      final response = await http
          .get(
              Uri.parse(
                  "https://themettacode.github.io/mettacode-app-data-api/$otherLinksEndpoint"),
              headers: headers)
          .timeout(const Duration(seconds: apiResponseTimeoutSeconds));
      log.d(
          '[GITHUB OTHER LINKS API] GITHUB MSG API RESPONSE CODE: ${response.statusCode} *****');
      if (response.statusCode == 200) {
        GithubOtherLinksData githubOtherLinksData =
            githubOtherLinksFromJson(response.body);
        log.d('[GITHUB OTHER LINKS API] NEW GITHUB LINKS RETRIEVED');

        List<GithubOtherLinks> githubOtherLinks = githubOtherLinksData
            .otherLinks
            .where((element) => element.isApp)
            .toList();

        GithubOtherLinks? thisApplication = githubOtherLinks
            .firstWhere((element) => element.nameTag == applicationNameTag);

        // githubOtherLinksNotifier.value = githubOtherLinks;

        githubOLApplications = GithubOLApplications(
            allData: githubOtherLinks
                .where((element) => element.nameTag != applicationNameTag)
                .toList(),
            thisApplication: thisApplication);

        githubApplicationsNotifier.value = githubOLApplications;

        // return githubOtherLinks;
      } else {
        log.d(
            '[GITHUB OTHER LINKS API] GITHUB OTHER LINKS API CALL ERROR WITH RESPONSE CODE: ${response.statusCode}');
        // return []; // githubNotificationsPlaceholder;
      }
    } catch (e) {
      popMessage(
          context,
          '[GITHUB OTHER LINKS API] GITHUB OTHER LINKS API CALL ERROR WITH RESPONSE CODE: $e',
          true);
    }
    return githubOLApplications;
  }

  static Future<void> popMessage(
      BuildContext context, String message, bool isError,
      {Color? color}) async {
    log.d('[POP MESSAGE FUNCTION] GENERATING POP-UP MESSAGE *****');
    if (message.isNotEmpty) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
      ));
    }
  }
}

/// OTHER LINKS MODEL
// To parse this JSON data, do
//
//     final githubOtherLinks = githubOtherLinksFromJson(jsonString);

GithubOtherLinksData githubOtherLinksFromJson(String str) =>
    GithubOtherLinksData.fromJson(json.decode(str));

String githubOtherLinksToJson(GithubOtherLinksData data) =>
    json.encode(data.toJson());

class GithubOtherLinksData {
  GithubOtherLinksData({
    required this.otherLinks,
  });

  final List<GithubOtherLinks> otherLinks;

  factory GithubOtherLinksData.fromJson(Map<String, dynamic> json) =>
      GithubOtherLinksData(
        otherLinks: List<GithubOtherLinks>.from(
            json["links"].map((x) => GithubOtherLinks.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "links": List<dynamic>.from(otherLinks.map((x) => x.toJson())),
      };
}

class GithubOtherLinks {
  GithubOtherLinks({
    required this.nameTag,
    required this.priority,
    required this.isApp,
    required this.active,
    required this.title,
    required this.description,
    required this.userLevels,
    required this.market,
    required this.locality,
    required this.privacyPolicyUrl,
    required this.mobileAdvertisingPolicyUrl,
    required this.webAdvertisingPolicyUrl,
    required this.googlePlayUrl,
    required this.amazonUrl,
    required this.websiteUrl,
    required this.apkUrl,
    required this.avatarUrl,
    required this.icon,
    required this.additionalData,
    required this.inDevelopment,
    required this.appColor,
    required this.socials,
  });

  final String nameTag;
  final int priority;
  final bool isApp;
  final bool active;
  final String title;
  final String description;
  final List<String> userLevels;
  final List<String> market;
  final List<String> locality;
  final String privacyPolicyUrl;
  final String mobileAdvertisingPolicyUrl;
  final String webAdvertisingPolicyUrl;
  final String googlePlayUrl;
  final String amazonUrl;
  final String websiteUrl;
  final String apkUrl;
  final String avatarUrl;
  final String icon;
  final String additionalData;
  final bool inDevelopment;
  final String appColor;
  final OtherLinksSocials socials;

  factory GithubOtherLinks.fromJson(Map<String, dynamic> json) =>
      GithubOtherLinks(
        nameTag: json["name_tag"],
        priority: json["priority"],
        isApp: json["is_app"],
        active: json["active"] ?? false,
        title: json["title"] ?? "",
        description: json["description"] ?? "",
        userLevels: List<String>.from(json["user_levels"].map((x) => x)),
        market: List<String>.from(json["market"].map((x) => x)),
        locality: List<String>.from(json["locality"].map((x) => x)),
        privacyPolicyUrl: json["privacy_policy"],
        mobileAdvertisingPolicyUrl: json["mobile_advertising_policy"],
        webAdvertisingPolicyUrl: json["web_advertising_policy"],
        googlePlayUrl: json["google_play_url"] ?? "",
        amazonUrl: json["amazon_url"] ?? "",
        websiteUrl: json["website_url"] ?? "",
        apkUrl: json["apk_url"] ?? "",
        avatarUrl: json["avatar_url"] ?? "",
        icon: json["icon"] ?? "",
        additionalData: json["additional_data"] ?? "",
        inDevelopment: json["in_development"] ?? true,
        appColor: json["app_color"],
        socials: OtherLinksSocials.fromJson(json["socials"]),
      );

  Map<String, dynamic> toJson() => {
        "name_tag": nameTag,
        "priority": priority,
        "is_app": isApp,
        "active": active,
        "title": title,
        "description": description,
        "user_levels": List<dynamic>.from(userLevels.map((x) => x)),
        "market": List<dynamic>.from(market.map((x) => x)),
        "locality": List<dynamic>.from(locality.map((x) => x)),
        "google_play_url": googlePlayUrl,
        "amazon_url": amazonUrl,
        "website_url": websiteUrl,
        "apk_url": apkUrl,
        "avatar_url": avatarUrl,
        "icon": icon,
        "additional_data": additionalData,
        "in_development": inDevelopment,
        "app_color": appColor,
        "socials": socials.toJson(),
      };
}

class OtherLinksSocials {
  final String twitter;
  final String instagram;
  final String youtube;
  final String facebook;
  final String tiktok;
  final String rumble;

  OtherLinksSocials({
    required this.twitter,
    required this.instagram,
    required this.youtube,
    required this.facebook,
    required this.tiktok,
    required this.rumble,
  });

  factory OtherLinksSocials.fromJson(Map<String, dynamic> json) =>
      OtherLinksSocials(
        twitter: json["twitter"],
        instagram: json["instagram"],
        youtube: json["youtube"],
        facebook: json["facebook"],
        tiktok: json["tiktok"],
        rumble: json["rumble"],
      );

  Map<String, dynamic> toJson() => {
        "twitter": twitter,
        "instagram": instagram,
        "youtube": youtube,
        "facebook": facebook,
        "tiktok": tiktok,
        "rumble": rumble,
      };
}

class GithubOLApplications {
  List<GithubOtherLinks> allData = [];
  GithubOtherLinks? thisApplication;

  GithubOLApplications({required this.allData, required this.thisApplication});
}
