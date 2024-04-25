import 'dart:convert';
import 'dart:io';
import 'package:app_models/payments/stripe/stripe_helper.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../shared/constants.dart';

ValueNotifier<OnesignalUser?> onesignalUserNotifier = ValueNotifier(null);

class OnesignalSecrets {
  OnesignalSecrets({required this.appId, required this.apiKey});

  final String appId;
  final String apiKey;
}

enum OnesignalTags {
  userType("user_type"),
  appOpens("app_opens"),
  appCredits("app_credits");

  final String value;
  const OnesignalTags(this.value);
}

class OnesignalHelper {
  ///

  static Future<void> initialize({
    required OnesignalSecrets secrets,
    String? appUserId,
    String? email,
    bool isAdmin = false,
  }) async {
    appLogger.d(
        "[[ ONESIGNAL API ]] APPLICATION IS RUNNING ON ${kIsWeb ? 'WEB' : Platform.operatingSystem.toUpperCase()}.");
    if (appUserId != null && appUserId.isNotEmpty) {
      ///
      Map<String, String> tags = {};
      if (isAdmin) {
        tags.addAll({OnesignalTags.userType.value: "admin"});
      }

      appLogger.d(
          "[[ ONESIGNAL API : SET TAGS ]] OS TAGS: ${tags.entries.join("\n")}");

      ///
      if (kIsWeb) {
        // await getUser(appUserId: appUserId, email: email, secrets: secrets);
        await _searchForExistingOnesignalUser(
                appUserId: appUserId, secrets: secrets)
            .then((value) => onesignalUserNotifier.value = value);

        ///
      } else if (Platform.isWindows) {
        await getUser(appUserId: appUserId, email: email, secrets: secrets)
            .then((value) => onesignalUserNotifier.value = value);

        ///
        // } else if (
        //     // !kIsWeb &&
        //     Platform.isAndroid) {
        //   OneSignal.initialize(secrets.appId);

        //   /// Setting External User Id with Callback Available in SDK Version 3.9.3+
        //   await OneSignal.login(appUserId);
        //   onesignalSubscriptionNotifier.value = true;

        //   /// UPDATE ONESIGNAL TAGS
        //   if (tags.isNotEmpty) {
        //     await OneSignal.User.addTags(tags);
        //   }

        //   bool optedIn = OneSignal.User.pushSubscription.optedIn ?? false;

        //   appLogger.f(
        //       "[[ ONESIGNAL API :: PUSH NOTIFS PERMIT ]] Accepted permission: $optedIn");
        //   if (optedIn) {
        //     OneSignal.InAppMessages.addTrigger("showPrompt", "true");
        //   }
      } else {
        appLogger.d(
            "[[ ONESIGNAL API ]] APPLICATION IS RUNNING ON ${Platform.operatingSystem.toUpperCase()}. NO METHOD EMPLEMENTED FOR THIS PLATFORM.");
        return;
      }
    }
  }

  static Future<void> updateSubscriberEmail({
    required OnesignalSecrets secrets,
    required String appUserId,
    required String newEmail,
  }) async {
    if (onesignalUserNotifier.value != null) {
      // if (kIsWeb || Platform.isWindows) {
      try {
        await _updateUserEmailWithAPI(
          secrets: secrets,
          appUserId: appUserId,
          newEmail: newEmail,
        );
      } catch (e) {
        appLogger.e(
            "[[ ONESIGNAL API :: UPDATE SUBSCRIBER EMAIL ]] ERROR UPDATING SUBSCRIBER EMAIL: $e");
        //   }
        // } else {
        //   try {
        //     appLogger.f(
        //         "[[ ONESIGNAL API :: UPDATE SUBSCRIBER EMAIL ]] UPDATING SUBSCRIBER EMAIL TO $newEmail.");
        //     await OneSignal.User.addEmail(newEmail);
        //   } catch (e) {
        //     appLogger.e(
        //         "[[ ONESIGNAL API :: UPDATE SUBSCRIBER EMAIL ]] ERROR UPDATING SUBSCRIBER EMAIL: $e");
        //   }
      }
    } else {
      appLogger.d(
          "[[ ONESIGNAL API :: UPDATE SUBSCRIBER EMAIL ]] NO ONESIGNAL USER INFO PROVIDED.");
    }
  }

  // static Future<void> updateSubscriberSms(
  //     {required String newSmsPhoneNumber}) async {
  //   if (kIsWeb) {
  //     appLogger.e(
  //         "[[ ONESIGNAL API :: UPDATE SUBSCRIBER SMS PHONE NUMBER ]] PLATFORM IS WEB WITH NO ONESIGNAL METHOD CURRENTLY PROVIDED.");
  //   } else {
  //     try {
  //       appLogger.d(
  //           "[[ ONESIGNAL API :: UPDATE SUBSCRIBER SMS PHONE NUMBER ]] UPDATING SUBSCRIBER SMS PHONE NUMBER TO $newSmsPhoneNumber.");
  //       await OneSignal.User.addSms(newSmsPhoneNumber);
  //     } catch (e) {
  //       appLogger.e(
  //           "[[ ONESIGNAL API :: UPDATE SUBSCRIBER SMS PHONE NUMBER ]] ERROR UPDATING SUBSCRIBER SMS PHONE NUMBER: $e");
  //     }
  //   }
  // }

  static Future<OnesignalUser?> _updateUserPushSubscriptionWithAPI({
    required OnesignalSecrets secrets,
    required String appUserId,
  }) async {
    OnesignalUser? onesignalUser;

    if ((kIsWeb || Platform.isWindows) &&
        onesignalUserNotifier.value?.subscriptions?.firstWhereOrNull((e) =>
                kIsWeb ? e.type == "ChromePush" : e.type == "WindowsPush") !=
            null) {
      /// update EMAIL SUBSCRIPTION
      var subscription = onesignalUserNotifier.value!.subscriptions!.firstWhere(
          (element) => kIsWeb
              ? element.type == "ChromePush"
              : element.type == "WindowsPush");

      ///
      try {
        appLogger.d(
            '[[ ONESIGNAL API ]] ATTEMPTING TO UPDATE ONESIGNAL USER SUBSCRIPTION');

        // Make get request to Onesignal
        var response = await http.patch(
          Uri.parse(
              'https://api.onesignal.com/apps/${secrets.appId}/subscriptions/${subscription.id}'),
          headers: {
            'accept': 'application/json; charset=utf-8',
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: jsonEncode({
            "subscription": {
              "type": kIsWeb ? "ChromePush" : "WindowsPush",
              "token": subscription.token
            }
          }),
        );
        appLogger.d(
            '[[ ONESIGNAL API ]] SUBSCRIPTION UPDATE RESPONSE: ${response.body}');

        if (response.statusCode == 200) {
          onesignalUser = await getUser(secrets: secrets, appUserId: appUserId);
        }
      } catch (err) {
        appLogger.e(
            '[[ ONESIGNAL API ]] ONESIGNAL SUBSCRIPTION UPDATE ERROR. ERROR => $err');
      }
    } else {
      /// CREATE EMAIL SUBSCRIPTION
      try {
        appLogger.d(
            '[[ ONESIGNAL API ]] ATTEMPTING TO UPDATE ONESIGNAL USER SUBSCRIPTION');

        // Make get request to Onesignal
        var response = await http.post(
          Uri.parse(
              'https://api.onesignal.com/apps/${secrets.appId}/users/by/external_id/$appUserId/subscriptions'),
          headers: {
            'Authorization': 'Basic ${secrets.apiKey}',
            'accept': 'application/json; charset=utf-8',
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: jsonEncode({
            "subscription": {"type": kIsWeb ? "ChromePush" : "WindowsPush"}
          }),
        );
        appLogger.d(
            '[[ ONESIGNAL API ]] SUBSCRIPTION UPDATE RESPONSE: ${response.body}');

        if (response.statusCode == 201 || response.statusCode == 202) {
          onesignalUser = await getUser(secrets: secrets, appUserId: appUserId);
          // onesignalUserNotifier.value!.subscriptions
          //     .add(Subscription.fromJson(jsonDecode(response.body)));
          // onesignalUser = onesignalUserNotifier.value;
          // } else if (response.statusCode == 202) {
          //   onesignalUser =
          //       await getUser(secrets: secrets, appUserId: appUserId);
        }
      } catch (err) {
        appLogger.e(
            '[[ ONESIGNAL API ]] ONESIGNAL SUBSCRIPTION UPDATE ERROR. ERROR => $err');
      }
    }

    ///
    onesignalUserNotifier.value = onesignalUser;
    // return onesignalUserNotifier.value;
    return onesignalUser;
  }

  static Future<OnesignalUser?> _updateUserEmailWithAPI({
    required OnesignalSecrets secrets,
    required String appUserId,
    required String newEmail,
    // required bool isUpdate,
  }) async {
    OnesignalUser? onesignalUser;

    if (newEmail.isNotEmpty) {
      if (onesignalUserNotifier.value?.subscriptions
              ?.firstWhereOrNull((e) => e.type == "email") !=
          null) {
        /// update EMAIL SUBSCRIPTION
        var subscriptionId = onesignalUserNotifier.value!.subscriptions!
            .firstWhere((element) => element.type == "email")
            .id;
        try {
          appLogger.d(
              '[[ ONESIGNAL API ]] ATTEMPTING TO UPDATE ONESIGNAL USER EMAIL SUBSCRIPTION ADDRESS');

          // Make get request to Onesignal
          var response = await http.patch(
            Uri.parse(
                'https://api.onesignal.com/apps/${secrets.appId}/subscriptions/$subscriptionId'),
            headers: {
              'accept': 'application/json; charset=utf-8',
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: jsonEncode({
              "subscription": {"type": "email", "token": newEmail}
            }),
          );
          appLogger.d(
              '[[ ONESIGNAL API ]] SUBSCRIPTION UPDATE RESPONSE: ${response.body}');

          if (response.statusCode == 200) {
            onesignalUser =
                await getUser(secrets: secrets, appUserId: appUserId);
          }
        } catch (err) {
          appLogger.e(
              '[[ ONESIGNAL API ]] ONESIGNAL EMAIL UPDATE ERROR. ERROR => $err');
        }
      } else {
        /// CREATE EMAIL SUBSCRIPTION
        try {
          appLogger.d(
              '[[ ONESIGNAL API ]] ATTEMPTING TO UPDATE ONESIGNAL USER EMAIL SUBSCRIPTION ADDRESS');

          // Make get request to Onesignal
          var response = await http.post(
            Uri.parse(
                'https://api.onesignal.com/apps/${secrets.appId}/users/by/external_id/$appUserId/subscriptions'),
            headers: {
              'Authorization': 'Basic ${secrets.apiKey}',
              'accept': 'application/json; charset=utf-8',
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: jsonEncode({
              "subscription": {"type": "Email", "token": newEmail}
            }),
          );
          appLogger
              .d('[[ ONESIGNAL API ]] EMAIL UPDATE RESPONSE: ${response.body}');

          if (response.statusCode == 201 || response.statusCode == 202) {
            onesignalUser =
                await getUser(secrets: secrets, appUserId: appUserId);
            // onesignalUserNotifier.value!.subscriptions
            //     .add(Subscription.fromJson(jsonDecode(response.body)));
            // onesignalUser = onesignalUserNotifier.value;
            // } else if (response.statusCode == 202) {
            //   onesignalUser =
            //       await getUser(secrets: secrets, appUserId: appUserId);
          }
        } catch (err) {
          appLogger.e(
              '[[ ONESIGNAL API ]] ONESIGNAL EMAIL UPDATE ERROR. ERROR => $err');
        }
      }
    }

    ///
    onesignalUserNotifier.value = onesignalUser;
    // return onesignalUserNotifier.value;
    return onesignalUser;
  }

  static Future<OnesignalUser?> getUser({
    required OnesignalSecrets secrets,
    required String appUserId,
    String? email,
    bool isAdmin = false,
  }) async {
    OnesignalUser? onesignalUser;

    try {
      onesignalUser = await _searchForExistingOnesignalUser(
          secrets: secrets, appUserId: appUserId);
      appLogger.f(
          "[[ ONESIGNAL API :: GET USER ]] USER FOUND: ${onesignalUser?.toJson().toString()}");
    } catch (e) {
      appLogger.e(
          "[[ ONESIGNAL API :: GET USER ]] ERROR ON RETURN FROM ONESIGNAL USER SEARCH: $e");
    }

    if (onesignalUser == null) {
      try {
        onesignalUser = await _createOnesignalUser(
          secrets: secrets,
          appUserId: appUserId,
          email: email,
          isAdmin: isAdmin,
        );
        appLogger.f(
            "[[ ONESIGNAL API :: GET USER ]] USER CREATED: ${onesignalUser?.toJson().toString()}");
      } catch (e) {
        appLogger.e(
            "[[ ONESIGNAL API :: GET USER ]] ERROR ON RETURN FROM ONESIGNAL USER CREATE: $e");
      }
    }
    return onesignalUser;
  }

  static Future<OnesignalUser?> _searchForExistingOnesignalUser(
      {required OnesignalSecrets secrets, required String appUserId}) async {
    OnesignalUser? onesignalUser;

    if (kIsWeb) {
      appLogger.f(
          '[[ ONESIGNAL API ]] USER SEARCH: APP IS RUNNING ON WEB. THERE IS CURRENTLY NO VARIABLE TO USE FOR SEARCH. TBD.');
    } else {
      try {
        appLogger.d('[[ ONESIGNAL API ]] ATTEMPTING ONESIGNAL USER SEARCH...');

        // Make get request to Onesignal
        var response = await http.get(
          Uri.parse(
              'https://api.onesignal.com/apps/${secrets.appId}/users/by/external_id/$appUserId'),
          headers: {
            'accept': 'application/json; charset=utf-8',
            // 'Content-Type': 'application/json; charset=utf-8',
          },
        );
        appLogger.d(
            '[[ ONESIGNAL API ]] USER SEARCH RESPONSE CODE ${response.statusCode}: ${response.body}');

        if (response.statusCode == 200) {
          try {
            onesignalUser = onesignalUserFromJson(response.body);
            appLogger.f(
                '[[ ONESIGNAL API ]] USER DECODED: ${onesignalUser.toJson().toString()}');
          } catch (e) {
            appLogger.e(
                '[[ ONESIGNAL API ]] ONESIGNAL USER JSON DECODE ERROR. ERROR => $e');
          }
        }
      } catch (err) {
        appLogger.e(
            '[[ ONESIGNAL API ]] ONESIGNAL USER SEARCH ERROR. ERROR => $err');
      }
    }

    if (onesignalUser != null &&
        (onesignalUser.subscriptions == null ||
            onesignalUser.subscriptions!.isEmpty)) {
      onesignalUser = await _updateUserPushSubscriptionWithAPI(
          secrets: secrets, appUserId: appUserId);
    }

    appLogger.f(
        '[[ ONESIGNAL API ]] USER SEARCH RETURNED: ${onesignalUser?.toJson().toString()}');

    ///
    // onesignalUserNotifier.value = user;
    return onesignalUser;
  }

  static Future<OnesignalUser?> _createOnesignalUser({
    required OnesignalSecrets secrets,
    required String appUserId,
    String? email,
    required bool isAdmin,
  }) async {
    OnesignalUser? onesignalUser;
    //Request body
    var data = jsonEncode({
      "properties": {
        "tags": {
          "user_type": isAdmin ? "admin" : "general_user",
          "platform": kIsWeb ? "web" : Platform.operatingSystem
        }
        //? "tags": {"user_type": isAdmin ? "admin" : "user", "foo": "bar"}
      },
      "identity": {"external_id": appUserId, "email": email ?? ""},
      "subscriptions": [
        {
          "type": kIsWeb
              ? "ChromePush"
              : Platform.isWindows
                  ? "WindowsPush"
                  : Platform.isAndroid
                      ? "AndroidPush"
                      : "ChromePush",
          // "token": OneSignal.User.pushSubscription.token ?? "",
          "enabled": true
        }
      ]
    });

    try {
      appLogger.d('[[ ONESIGNAL API ]] ATTEMPTING CREATE ONESIGNAL USER...');

      // Make post request to Onesignal
      var response = await http.post(
        Uri.parse('https://api.onesignal.com/apps/${secrets.appId}/users'),
        headers: {
          'accept': 'application/json; charset=utf-8',
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: data,
      );
      appLogger.d(
          '[[ ONESIGNAL API ]] CREATE ONESIGNAL USER RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        onesignalUser = onesignalUserFromJson(response.body);
      }
    } catch (err) {
      appLogger.e('[[ ONESIGNAL API ]] CREATE ONESIGNAL USER ERROR: $err');
    }

    ///
    // onesignalUserNotifier.value = user;
    return onesignalUser;
  }

  static Future<void> sendNotificationEmails({
    required OnesignalSecrets secrets,
    required String appUserId,
    required String fromName,
    required String fromEmail,
    required String replyToEmail,
    required String subject,
    required String emailBody,
    required String oneSignalTemplateId,
    bool? includeUnsubscribed,
    String? imageUrl,
    String? preHeader,
  }) async {
    Map<String, String> customData = {
      "app_user_id": appUserId,
      "from_email": fromEmail,
      "subject": subject,
      "body": emailBody,
    };

    if (imageUrl != null) {
      customData.addAll({"image_url": imageUrl});
    }

    appLogger.d('[[ ONESIGNAL API ]] CUSTOM DATA USED: $customData');

    try {
      appLogger.d('[[ ONESIGNAL API ]] ATTEMPTING TO SEND EMAIL NOTIFICATION');

      //Request body
      var emailNotificationBody = jsonEncode({
        "app_id": secrets.appId,
        "template_id":
            oneSignalTemplateId, // OnesignalTemplateIds.generalEmail.value,
        "email_subject": subject,
        "email_from_name": fromName,
        "email_reply_to_address": replyToEmail,
        "email_preheader": preHeader ??
            (emailBody.length > 100
                ? emailBody.replaceRange(100, null, "...")
                : emailBody),
        "included_segments": ["Subscribed Users"],
        "include_unsubscribed": includeUnsubscribed,
        "custom_data": customData
      });

      //Make post request to Stripe
      var emailResponse = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Authorization': 'Basic ${secrets.apiKey}',
          // 'Authorization': 'Basic ${testing ? restApiKey : restApiKey}',
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: emailNotificationBody,
      );
      appLogger
          .d('[[ ONESIGNAL API ]] EMAIL SEND RESPONSE: ${emailResponse.body}');
    } catch (err) {
      appLogger
          .e('[[ ONESIGNAL API ]] CREATE NOTIFICATION EMAIL SEND ERROR: $err');
      throw Exception(err.toString());
    }
  }

  static Future<void> sendGeneralEmail({
    required OnesignalSecrets secrets,
    required String appUserId,
    required List<String> toEmails,
    required String fromName,
    required String replyToEmail,
    required String subject,
    required String emailBody,
    required String oneSignalTemplateId,
    bool? includeUnsubscribed,
    String? toName,
    String? imageUrl,
    String? fromAddress,
    String? preHeader,
  }) async {
    Map<String, String> customData = {
      "app_user_id": appUserId,
      "subject": subject,
      "body": emailBody,
    };

    if (imageUrl != null) {
      customData.addAll({"image_url": imageUrl});
    }

    appLogger.d('[[ ONESIGNAL API ]] CUSTOM DATA USED: $customData');

    try {
      appLogger.d('[[ ONESIGNAL API ]] ATTEMPTING TO SEND EMAIL NOTIFICATION');

      //Request body
      var emailNotificationBody = jsonEncode({
        "app_id": secrets.appId,
        "template_id":
            oneSignalTemplateId, // OnesignalTemplateIds.generalEmail.value,
        "email_subject": subject,
        "email_from_name": fromName,
        "email_reply_to_address": replyToEmail,
        "email_preheader": preHeader ??
            (emailBody.length > 100
                ? emailBody.replaceRange(100, null, "...")
                : emailBody),
        // "email_body": emailBody,
        // "<html><head>Welcome to Cat Facts</head><body><h1>Welcome to Cart Facts<h1><h4>Learn more about everyone's favorite furry companions!</h4><hr/><p>Hi Nick,</p><p>Thanks for subscribing to Cat Facts! We can't wait to surprise you with funny details about your favorite animal.</p><h5>Today's Cat Fact (March 27)</h5><p>In tigers and tabbies, the middle of the tongue is covered in backward-pointing spines, used for breaking off and gripping meat.</p><a href='https://catfac.ts/welcome'>Show me more Cat Facts</a><hr/><p><small>(c) 2018 Cat Facts, inc</small></p><p><small><a href='[unsubscribe_url]'>Unsubscribe</a></small></p></body></html>",
        // "included_segments": ["Subscribed Users"],
        "include_email_tokens": toEmails,
        "include_unsubscribed": includeUnsubscribed,
        "custom_data": customData
      });

      //Make post request to Stripe
      var emailResponse = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Authorization': 'Basic ${secrets.apiKey}',
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: emailNotificationBody,
      );
      appLogger
          .d('[[ ONESIGNAL API ]] EMAIL SEND RESPONSE: ${emailResponse.body}');
    } catch (err) {
      appLogger.e('[[ ONESIGNAL API ]] CREATE EMAIL SEND ERROR: $err');
      throw Exception(err.toString());
    }
  }

  static Future<void> sendGeneralPush({
    required OnesignalSecrets secrets,
    required String appUserId,
    required String subject,
    required String body,
    required String oneSignalTemplateId,
    bool? includeUnsubscribed,
    String? imageUrl,
  }) async {
    Map<String, String> customData = {
      "subject": subject,
      "body": body,
    };

    if (imageUrl != null) {
      customData.addAll({"image_url": imageUrl});
    }

    appLogger.d('[[ ONESIGNAL API ]] CUSTOM DATA USED: $customData');

    try {
      //Request body
      var pushNotificationBody = jsonEncode({
        "app_id": secrets.appId,
        "template_id":
            oneSignalTemplateId, //  OnesignalTemplateIds.generalPush.value,
        "custom_data": customData,
        "included_segments": ["Subscribed Users"],
        // "android_group": OnesignalPushGroups.promotion.value,
      });

      /// Make post request to Stripe
      var pushResponse = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Authorization': 'Basic ${secrets.apiKey}',
          'accept': 'application/json',
          'content-Type': 'application/json',
        },
        body: pushNotificationBody,
      );
      appLogger
          .d('[[ ONESIGNAL API ]] PUSH SEND RESPONSE: ${pushResponse.body}');
    } catch (err) {
      appLogger.d('[[ ONESIGNAL API ]] CREATE NOTIFICATION SEND ERROR: $err');
      throw Exception(err.toString());
    }
  }

  static Future<void> sendPromotionPush({
    required OnesignalSecrets secrets,
    required String appUserId,
    required String subject,
    required String body,
    required String oneSignalTemplateId,
    bool? includeUnsubscribed,
    String? imageUrl,
  }) async {
    Map<String, String> customData = {
      "app_user_id": appUserId,
      "subject": subject,
      "body": body,
    };

    if (imageUrl != null) {
      customData.addAll({"image_url": imageUrl});
    }

    appLogger.d('[[ ONESIGNAL API ]] CUSTOM DATA USED: $customData');

    try {
      //Request body
      var pushNotificationBody = jsonEncode({
        "app_id": secrets.appId,
        "template_id":
            oneSignalTemplateId, //  OnesignalTemplateIds.promotionPush.value,
        "custom_data": customData,
        "included_segments": ["Subscribed Users"],
        // "android_group": OnesignalPushGroups.promotion.value,
      });

      /// Make post request to Stripe
      var pushResponse = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Authorization': 'Basic ${secrets.apiKey}',
          'accept': 'application/json',
          'content-Type': 'application/json',
        },
        body: pushNotificationBody,
      );
      appLogger
          .d('[[ ONESIGNAL API ]] PUSH SEND RESPONSE: ${pushResponse.body}');
    } catch (err) {
      appLogger.d('[[ ONESIGNAL API ]] CREATE NOTIFICATION SEND ERROR: $err');
      throw Exception(err.toString());
    }
  }

  static Future<void> sendSuccessfulPurchaseNotifications({
    required OnesignalSecrets secrets,
    required String appUserId,
    required PriceCalculations finalPriceCalculations,
    required ProductOrderInformation orderInfo,
    // required ProductOrder order,
    required List<String> customerEmails,
    required List<String> clientEmails,
    required String fromName,
    required String replyToEmail,
    required String oneSignalCustomerEmailTemplateId,
    required String oneSignalClientEmailTemplateId,
    required String oneSignalClientPushTemplateId,
    String? toName,
  }) async {
    ///
    Map<String, String> customData = {
      "app_user_id": appUserId,
      "order_id": orderInfo.orderId,
      "order_date": formatter
          .format(DateTime.fromMillisecondsSinceEpoch(orderInfo.orderDate)),
      "buy_price": "\$${finalPriceCalculations.retailPrice.toStringAsFixed(2)}",
      // "\$${finalPriceCalculations.finalBuyPrice.toStringAsFixed(2)}",
      "shipping_price":
          "\$${finalPriceCalculations.shippingPrice.toStringAsFixed(2)}",
      "total_for_this_sale":
          "\$${finalPriceCalculations.totalForThisSale.toStringAsFixed(2)}",
      "total_percent_off":
          "\$${finalPriceCalculations.totalPercentOff.toStringAsFixed(2)}",
      "subtotal": "\$${finalPriceCalculations.subtotal.toStringAsFixed(2)}",
      "product_title": orderInfo.productName,
      "product_category": orderInfo.productCategory ?? "No category required",
      "product_options":
          orderInfo.productOptions?.join(", ") ?? "No options required",
      "product_brand": orderInfo.productBrand ?? "No brand name provided",
      "image_url": orderInfo.productImageUrl,
      "shipping_name": orderInfo.shipToName,
      "shipping_email": orderInfo.customerEmail,
      "shipping_phone": orderInfo.shipToPhone ?? "No phone number provided",
      "shipping_address": orderInfo.fullShipToAddress,
      // "${order.shippingAddress?.line1} ${order.shippingAddress?.line2}",
      // "shipping_address_locale":
      //     "${order.shippingAddress?.city}, ${order.shippingAddress?.state} \n${order.shippingAddress?.postalCode} ${order.shippingAddress?.country}",
    };

    appLogger.d('[[ ONESIGNAL API ]] CUSTOM DATA USED: $customData');
    var subject = "👍 We've received your order!";
    var preheader =
        '''Your order for ${orderInfo.productName} has been received and is in process. You will receive another email when your order has shipped. If we run across any issues, we'll reach out using the email you provided while placing your order.''';

    try {
      appLogger.d('[[ ONESIGNAL API ]] ATTEMPTING TO SEND EMAIL NOTIFICATION');

      //! Customer email request body
      var customerBody = jsonEncode({
        "app_id": secrets.appId,
        "template_id":
            oneSignalCustomerEmailTemplateId, //   OnesignalTemplateIds.successfulProductPurchaseCustomerEmail.value,
        "email_subject": subject,
        "email_from_name": fromName,
        // "email_from_address": AppClient.supportEmail,
        "email_reply_to_address": replyToEmail,
        "email_preheader": preheader,
        "include_email_tokens": customerEmails, // + [AppClient.supportEmail],
        // "email_body": emailBody,
        // "<html><head>Welcome to Cat Facts</head><body><h1>Welcome to Cat Facts<h1><h4>Learn more about everyone's favorite furry companions!</h4><hr/><p>Hi Nick,</p><p>Thanks for subscribing to Cat Facts! We can't wait to surprise you with funny details about your favorite animal.</p><h5>Today's Cat Fact (March 27)</h5><p>In tigers and tabbies, the middle of the tongue is covered in backward-pointing spines, used for breaking off and gripping meat.</p><a href='https://catfac.ts/welcome'>Show me more Cat Facts</a><hr/><p><small>(c) 2018 Cat Facts, inc</small></p><p><small><a href='[unsubscribe_url]'>Unsubscribe</a></small></p></body></html>",
        // "included_segments": ["Subscribed Users"],
        "custom_data": customData
      });

      // Make post request to Onesignal
      var customerEmailResponse = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Authorization': 'Basic ${secrets.apiKey}',
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: customerBody,
      );
      appLogger.d(
          '[[ ONESIGNAL API ]] CUSTOMER EMAIL SEND RESPONSE: ${customerEmailResponse.body}');

      //! Client email request body
      var clientBody = jsonEncode({
        "app_id": secrets.appId,
        "template_id":
            oneSignalClientEmailTemplateId, //    OnesignalTemplateIds.successfulProductPurchaseClientEmail.value,
        "email_subject":
            "🎉 An order for ${orderInfo.productName} has been placed!",
        "email_from_name": fromName,
        // "email_from_address": AppClient.supportEmail,
        "email_reply_to_address": replyToEmail,
        "email_preheader":
            "${orderInfo.shipToName} has placed an order for ${orderInfo.productName}! Time to get to work!",
        "include_email_tokens": clientEmails,
        "custom_data": customData
      });

      // Make post request to Onesignal
      var clientEmailResponse = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Authorization': 'Basic ${secrets.apiKey}',
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: clientBody,
      );
      appLogger.d(
          '[[ ONESIGNAL API ]] CUSTOMER EMAIL SEND RESPONSE: ${clientEmailResponse.body}');

      //! Push request body
      var pushNotificationBody = jsonEncode({
        "app_id": secrets.appId,
        "template_id":
            oneSignalClientPushTemplateId, //   OnesignalTemplateIds.successfulProductPurchaseClientPush.value,
        "filters": [
          {
            "field": "tag",
            "key": "user_type",
            "relation": "=",
            "value": "admin"
          }
        ],
        "custom_data": customData,
        // "android_group": OnesignalPushGroups.purchase.value,
      });
      // Make post request to Onesignal
      var clientPushResponse = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Authorization': 'Basic ${secrets.apiKey}',
          'accept': 'application/json',
          'content-Type': 'application/json',
        },
        body: pushNotificationBody,
      );
      appLogger.d(
          '[[ ONESIGNAL API ]] PUSH SEND RESPONSE: ${clientPushResponse.body}');
    } catch (err) {
      appLogger.d('[[ ONESIGNAL API ]] CREATE EMAIL SEND ERROR: $err');
      throw Exception(err.toString());
    }
  }

  static Future<void> sendFailedPurchaseNotifications({
    required OnesignalSecrets secrets,
    required String appUserId,
    required List<String> toEmails,
    required String fromName,
    required String replyToEmail,
    required String productTitle,
    required String oneSignalTemplateId,
    String? toName,
    String? imageUrl,
  }) async {
    ///
    Map<String, String> customData = {
      "product_title": productTitle,
    };

    ///
    customData.addAll({
      "app_user_id": appUserId,
    });

    if (imageUrl != null) {
      customData.addAll({"image_url": imageUrl});
    }

    appLogger.d('[[ ONESIGNAL API ]] CUSTOM DATA USED: $customData');

    var subject = "😢 There was a problem with your order.";

    var preheader = "Your order for $productTitle was unsuccessful.";

    try {
      appLogger.d('[[ ONESIGNAL API ]] ATTEMPTING TO SEND EMAIL NOTIFICATION');

      //Request body
      var body = jsonEncode({
        "app_id": secrets.appId,
        "template_id":
            oneSignalTemplateId, //  OnesignalTemplateIds.failedProductPurchaseEmail.value,
        "email_subject": subject,
        "email_from_name": fromName,
        "email_reply_to_address": replyToEmail,
        "email_preheader": preheader,
        "include_email_tokens": toEmails,
        "custom_data": customData
      });

      //Make post request to Stripe
      var response = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Authorization': 'Basic ${secrets.apiKey}',
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: body,
      );
      appLogger.d('[[ ONESIGNAL API ]] EMAIL SEND RESPONSE: ${response.body}');
    } catch (err) {
      appLogger.d('[[ ONESIGNAL API ]] CREATE EMAIL SEND ERROR: $err');
      throw Exception(err.toString());
    }
  }
}

// To parse this JSON data, do
//
//     final onesignalUser = onesignalUserFromJson(jsonString);

OnesignalUser onesignalUserFromJson(String str) =>
    OnesignalUser.fromJson(json.decode(str));

String onesignalUserToJson(OnesignalUser data) => json.encode(data.toJson());

class OnesignalUser {
  Properties properties;
  Identity identity;
  List<Subscription>? subscriptions;

  OnesignalUser({
    required this.properties,
    required this.identity,
    required this.subscriptions,
  });

  factory OnesignalUser.fromJson(Map<String, dynamic> json) => OnesignalUser(
        properties: Properties.fromJson(json["properties"]),
        identity: Identity.fromJson(json["identity"]),
        // subscriptions: json["subscriptions"]
        subscriptions: json["subscriptions"] == null
            ? []
            : List<Subscription>.from(
                json["subscriptions"].map((x) => Subscription.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "properties": properties.toJson(),
        "identity": identity.toJson(),
        // "subscriptions": subscriptions.toString()
        "subscriptions":
            subscriptions == null ? [] : subscriptions!.map((x) => x.toJson()),
      };
}

class Identity {
  String externalId;
  String onesignalId;

  Identity({
    required this.externalId,
    required this.onesignalId,
  });

  factory Identity.fromJson(Map<String, dynamic> json) => Identity(
        externalId: json["external_id"],
        onesignalId: json["onesignal_id"],
      );

  Map<String, dynamic> toJson() => {
        "external_id": externalId,
        "onesignal_id": onesignalId,
      };
}

class Properties {
  // Tags tags;
  int firstActive;
  int lastActive;

  Properties({
    // required this.tags,
    required this.firstActive,
    required this.lastActive,
  });

  factory Properties.fromJson(Map<String, dynamic> json) => Properties(
        // tags: Tags.fromJson(json["tags"]),
        firstActive: json["first_active"],
        lastActive: json["last_active"],
      );

  Map<String, dynamic> toJson() => {
        // "tags": tags.toJson(),
        "first_active": firstActive,
        "last_active": lastActive,
      };
}

// class Tags {
//   String key;
//   String value;

//   Tags({
//     required this.key,
//     required this.value,
//   });

//   factory Tags.fromJson(Map<String, dynamic> json) =>
//       Tags(key: json["key"], value: json["value"]);

//   Map<String, dynamic> toJson() => {
//         "key": key,
//         "value": value,
//       };
// }

class Subscription {
  String id;
  String appId;
  String type;
  String? token;
  bool? enabled;
  // int notificationTypes;
  // int sessionTime;
  // int sessionCount;
  // String sdk;
  // String deviceModel;
  // String deviceOs;
  // bool rooted;
  // int testType;
  // String appVersion;
  // int netType;
  // String carrier;
  // String webAuth;
  // String webP256;

  Subscription({
    required this.id,
    required this.appId,
    required this.type,
    required this.token,
    required this.enabled,
    // required this.notificationTypes,
    // required this.sessionTime,
    // required this.sessionCount,
    // required this.sdk,
    // required this.deviceModel,
    // required this.deviceOs,
    // required this.rooted,
    // required this.testType,
    // required this.appVersion,
    // required this.netType,
    // required this.carrier,
    // required this.webAuth,
    // required this.webP256,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        id: json["id"],
        appId: json["app_id"],
        type: json["type"],
        token: json["token"] ?? "",
        enabled: json["enabled"] ?? false,
        // notificationTypes: json["notification_types"],
        // sessionTime: json["session_time"],
        // sessionCount: json["session_count"],
        // sdk: json["sdk"],
        // deviceModel: json["device_model"],
        // deviceOs: json["device_os"],
        // rooted: json["rooted"],
        // testType: json["test_type"],
        // appVersion: json["app_version"],
        // netType: json["net_type"],
        // carrier: json["carrier"],
        // webAuth: json["web_auth"],
        // webP256: json["web_p256"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "app_id": appId,
        "type": type,
        "token": token ?? "",
        "enabled": enabled ?? false,
        // "notification_types": notificationTypes,
        // "session_time": sessionTime,
        // "session_count": sessionCount,
        // "sdk": sdk,
        // "device_model": deviceModel,
        // "device_os": deviceOs,
        // "rooted": rooted,
        // "test_type": testType,
        // "app_version": appVersion,
        // "net_type": netType,
        // "carrier": carrier,
        // "web_auth": webAuth,
        // "web_p256": webP256,
      };
}

class ProductOrderInformation {
  ProductOrderInformation(
      {required this.orderId,
      required this.orderDate,
      required this.productName,
      this.productCategory,
      this.productOptions,
      this.productBrand,
      required this.productImageUrl,
      required this.shipToName,
      this.shipToPhone,
      required this.customerEmail,
      required this.fullShipToAddress});

  final String orderId;
  final int orderDate;
  final String productName;
  final String? productCategory;
  final List<String>? productOptions;
  final String? productBrand;
  final String productImageUrl;
  final String shipToName;
  final String? shipToPhone;
  final String customerEmail;
  final String fullShipToAddress;
}
