import 'dart:convert';
import 'dart:io';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as strp;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../shared/constants.dart';
import 'stripe_models/checkout_sessions.dart';
import 'stripe_models/coupon.dart';
import 'stripe_models/customer.dart';
import 'stripe_models/price.dart';
import 'stripe_models/promo_code.dart';
import 'stripe_models/shipping_price.dart';
import 'stripe_models/stripe_product.dart';

/// NOTIFIERS
ValueNotifier<List<StripeCustomer>> stripeCustomerNotifier = ValueNotifier([]);
ValueNotifier<bool> attemptingPurchaseNotifier = ValueNotifier(false);
ValueNotifier<bool> purchaseSuccessfulNotifier = ValueNotifier(false);
ValueNotifier<PriceCalculations?> priceCalculationsNotifier =
    ValueNotifier(null);

const String stripePaymentDelimiter = "<|:|>";
const String stripePriceCalculationsDelimiter = "<|price_calculation|>";
const double stripeFirstPurchaseDiscountPercent = 10;

class StripeSecrets {
  StripeSecrets({
    required this.accountId,
    required this.secretKey,
    required this.secretTestKey,
    required this.publishableKey,
    required this.publishableTestKey,
  });

  final String accountId;
  final String secretKey;
  final String secretTestKey;
  final String? publishableKey;
  final String? publishableTestKey;
}

class StripeHelper {
  ///
  static Future<List<StripeCustomer>> stripePaymentInit({
    required StripeSecrets secrets,
    required bool testing,
    // required String publicKey,
    // required String publicTestKey,
    // required String accountId,
    String? name,
    String? email,
    String? phone,
    Map<String, String>? metadataKeyAndValue,
  }) async {
    List<StripeCustomer> existingStripeCustomers = [];
    appLogger.d(
        '[[ STRIPE PAYMENT API INIT ]]${testing ? ' TEST' : ''} INITIALIZING...');

    if (kIsWeb || Platform.isAndroid) {
      ///
      strp.Stripe.publishableKey =
          testing ? secrets.publishableTestKey! : secrets.publishableKey!;
      strp.Stripe.stripeAccountId = secrets.accountId;
      strp.Stripe.urlScheme = 'flutterstripe';
      await strp.Stripe.instance.applySettings();

      appLogger.f(
          '[[ STRIPE PAYMENT API INIT ]] SEARCHING FOR${testing ? ' TEST' : ''} STRIPE CUSTOMER FROM REMOTE SERVER USING APP USER ID');
      await searchForExistingStripeCustomer(
        secrets: secrets,
        testing: testing,
        name: name,
        email: email,
        metadataKeyAndValue: metadataKeyAndValue,
      ).then((customers) {
        if (customers.isNotEmpty) {
          existingStripeCustomers = customers;
          stripeCustomerNotifier.value = customers;
          appLogger.f(
              '[[ STRIPE PAYMENT API INIT ]]${testing ? ' TEST' : ''} STRIPE CUSTOMERS FOUND FROM REMOTE SERVER! ${customers.map((e) => e.id)}');
        }
      });

      ///
      appLogger.d(
          '[[ STRIPE PAYMENT API INIT ]]${testing ? ' TEST' : ''} INITIALIZATION COMPLETE.');
    } else {
      appLogger.d(
          '[[ STRIPE PAYMENT API INIT ]] NO${testing ? ' TEST' : ''} INITIALIZATION METHOD CURRENTLY IMPLEMENTED FOR ${Platform.operatingSystem.toUpperCase()}');
    }
    return existingStripeCustomers;
  }

  static Future<(bool, CheckoutSessionsDatum?, PriceCalculations?)>
      processPayment({
    required StripeSecrets secrets,
    required BuildContext context,
    required bool testing,
    required String appUserId,
    required GeneralPurchaserInfo purchaserInfo,
    required GeneralProductInfo productInfo,
    String currency = "usd",
  }) async {
    bool paymentSuccessful = false;
    CheckoutSessionsDatum? checkoutSession;
    PriceCalculations? updatedPriceCalculations;

    appLogger.w(
        '[[ STRIPE PAYMENT API PROCESS PAYMENT ]] CURRENT STRIPE CUSTOMER IDS: ${stripeCustomerNotifier.value.join(", ")}');
    StripeCustomer? stripeCustomer = await getStripeCustomer(
      secrets: secrets,
      testing: testing,
      purchaserInfo: purchaserInfo,
    );

    if ((stripeCustomer != null)) {
      try {
        appLogger.d(
            '[[ STRIPE PAYMENT API PROCESS WEB PAYMENT ]] BEGINNING WEB${testing ? ' TEST' : 'LIVE'} PAYMENT PROCESSING...');

        String? fullPaymentLinkData;

        fullPaymentLinkData = await createStripePaymentLink(
          secrets: secrets,
          testing: testing,
          appUserId: appUserId,
          customer: stripeCustomer,
          purchaserInfo: purchaserInfo,
          productInfo: productInfo,
        );

        if (fullPaymentLinkData != null) {
          final String paymentLinkId =
              fullPaymentLinkData.split(stripePaymentDelimiter).first;
          final String paymentLinkUrl =
              fullPaymentLinkData.split(stripePaymentDelimiter)[1];

          ///
          if (await canLaunchUrl(Uri.parse(paymentLinkUrl))) {
            launchUrl(Uri.parse(paymentLinkUrl),
                mode: LaunchMode.platformDefault);
          }

          await showDialog(
              context: context,
              barrierDismissible: false,
              barrierColor: Colors.transparent,
              builder: (context) => Dialog(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(25),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Order In Process...\nClose this message once you complete your transaction.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(),
                            ),
                            ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Finish & Close")),
                          ],
                        ),
                      ),
                    ),
                  )).then((_) async {
            ///
            appLogger.d(
                '[[ STRIPE PAYMENT API PROCESS WEB PAYMENT ]] VERIFYING WEB${testing ? ' TEST' : ''} PAYMENT...');

            ///
            (
              bool,
              CheckoutSessionsDatum?,
              PriceCalculations?
            ) purchaseVerified = await verifyStripePayment(
              secrets: secrets,
              testing: testing,
              customerId: stripeCustomer.id,
              productInfo: productInfo,
              paymentLink: paymentLinkId,
            );

            if (purchaseVerified.$1 && purchaseVerified.$2 != null) {
              appLogger.d(
                  '[[ STRIPE PAYMENT API PROCESS WEB PAYMENT ]] WEB${testing ? ' TEST' : ''} PAYMENT VERIFIED SUCCESSFUL!');
              paymentSuccessful = purchaseVerified.$1;
              checkoutSession = purchaseVerified.$2;
              updatedPriceCalculations = purchaseVerified.$3;
            } else {
              appLogger.d(
                  '[[ STRIPE PAYMENT API PROCESS WEB PAYMENT ]] WEB${testing ? ' TEST' : ''} PAYMENT NOT VERIFIED. UNSUCCESSFUL!');
            }
          });
        } else {
          appLogger.e(
              '[[ STRIPE PAYMENT API PROCESS WEB PAYMENT ]] UNABLE TO CREATE PAYMENT LINK. LINK DATA RETURNED NULL.');
        }
        // }
        // else if (Platform.isAndroid) {
        //   // Get customer ephemeral key
        //   CustomerTemporaryEphemeralKey? customerEphemeralKey =
        //       await getCustomerPaymentEphemeralKey(
        //           stripeCustomer:
        //               testing ? testStripeCustomer! : liveStripeCustomer!);

        //   //STEP 1: Create Payment Intent
        //   appLogger.d(
        //       '[[ STRIPE PAYMENT API PROCESS PAYMENT ]] ATTEMPTING TO CREATE${testing ? ' TEST' : ''} PAYMENT INTENT.');
        //   Map<String, dynamic>? paymentIntent = await createPaymentIntent(
        //     appUser: appUser,
        //     stripeCustomer:
        //         testing ? testStripeCustomer! : liveStripeCustomer!,
        //     product: product,
        //     amountPlusShippingAndHandling: priceCalculations != null
        //         ? priceCalculations.totalForThisSale
        //         : product.retailPrice + product.shippingAndHandling,
        //     shippingAddress: shippingAddress,
        //     currency: currency,
        //   );

        //   if (paymentIntent != null) {
        //     //STEP 2: Initialize Payment Sheet
        //     appLogger.d(
        //         '[[ STRIPE PAYMENT API PROCESS PAYMENT ]] INITIALIZING${testing ? ' TEST' : ''} PAYMENT SHEET.');

        //     // final strp.Address address = strp.Address(
        //     //   city: shippingAddress.city,
        //     //   country: shippingAddress.country,
        //     //   line1: shippingAddress.line1,
        //     //   line2: shippingAddress.line2,
        //     //   postalCode: shippingAddress.postalCode,
        //     //   state: shippingAddress.state,
        //     // );

        //     // paymentSheet =
        //     await strp.Stripe.instance.initPaymentSheet(
        //         paymentSheetParameters: strp.SetupPaymentSheetParameters(
        //       // Set to true for custom flow
        //       customFlow: false,
        //       // Main params
        //       merchantDisplayName: Application.name,
        //       paymentIntentClientSecret:
        //           paymentIntent['client_secret'], //Gotten from payment intent
        //       // // Customer keys
        //       customerEphemeralKeySecret: customerEphemeralKey.secret,
        //       customerId: paymentIntent['customer'],
        //       // Extra options
        //       primaryButtonLabel: "${testing ? ' TEST' : ''} Pay Now",
        //       // style: ThemeMode.dark,
        //       style: ThemeMode.system,
        //       // appearance: const strp.PaymentSheetAppearance(
        //       //     colors: strp.PaymentSheetAppearanceColors()),
        //       // billingDetailsCollectionConfiguration:
        //       //     const strp.BillingDetailsCollectionConfiguration(
        //       //   name: strp.CollectionMode.automatic,
        //       //   address: strp.AddressCollectionMode.automatic,
        //       // ),
        //       // billingDetails: strp.BillingDetails(
        //       //   name: shippingAddress.fullName,
        //       //   email: shippingAddress.email,
        //       //   phone: shippingAddress.phone,
        //       //   address: address,
        //       // ),
        //       // billingDetailsCollectionConfiguration: BillingDetailsCollectionConfiguration()
        //     ));

        //     //STEP 3: Display Payment sheet
        //     appLogger.d(
        //         '[[ STRIPE PAYMENT API PROCESS PAYMENT ]] ATTEMPTING TO DISPLAY PAYMENT SHEET.');
        //     paymentSuccessful = await displayPaymentSheet(
        //         // liveProductOverride: liveProductOverride,
        //         // context: context,
        //         paymentIntentClientSecret: paymentIntent['client_secret']);
        //   } else {
        //     appLogger.e(
        //
        //             '[[ STRIPE PAYMENT API PROCESS PAYMENT ]]${testing ? ' TEST' : ''} PROCESSING FLOW NOT YET IMPLEMENTED FOR ${Platform.operatingSystem.toUpperCase()} PAYMENT.');
        //     // appLogger.d(
        //     //     '[[ STRIPE PAYMENT API PROCESS PAYMENT ]]${testing ? ' TEST' : ''} PROCESSING FLOW NOT YET IMPLEMENTED FOR ${Platform.operatingSystem.toUpperCase()} PAYMENT.');
        //   }
        // }
      } catch (err) {
        appLogger.e(
            '[[ STRIPE PAYMENT API PROCESS PAYMENT ]]${testing ? ' TEST' : ''} PAYMENT PROCESSING $err');
      }
    } else {
      appLogger.e(
          '[[ STRIPE PAYMENT API PAYMENT SHEET ]] UNABLE TO RETRIVE STRIPE CUSTOMER. STRIPE CUSTOMER RETURNED NULL.');
    }

    return (paymentSuccessful, checkoutSession, updatedPriceCalculations);
  }

  // static Future<Map<String, dynamic>?> createPaymentIntent({
  //   required AppUser appUser,
  //   required StripeCustomer stripeCustomer,
  //   required SGAProduct product,
  //   required double amountPlusShippingAndHandling,
  //   required CustomerAddress shippingAddress,
  //   // required bool liveProductOverride,
  //   String? currency,
  // }) async {
  //   final testing = appTestingNotifier.value; //  && !liveProductOverride;
  //   try {
  //     appLogger.d(
  //         '[[ STRIPE PAYMENT API PAYMENT INTENT ]] ATTEMPTING TO CREATE${testing ? ' TEST' : ''} PAYMENT INTENT');

  //     //Request body
  //     Map<String, dynamic> body = {
  //       'amount': (amountPlusShippingAndHandling * 100).toInt().toString(),
  //       'currency': currency ?? 'USD',
  //       'customer': stripeCustomer.id,
  //       "receipt_email": shippingAddress.email,
  //       "description": product.title,
  //       "shipping[name]": shippingAddress.fullName,
  //       "shipping[phone]": shippingAddress.phone,
  //       "shipping[address][line1]": shippingAddress.line1,
  //       "shipping[address][line2]": shippingAddress.line2,
  //       "shipping[address][city]": shippingAddress.city,
  //       "shipping[address][state]": shippingAddress.state,
  //       "shipping[address][postal_code]": shippingAddress.postalCode,
  //       "shipping[address][country]": shippingAddress.country,
  //     };

  //     //Make post request to Stripe
  //     var response = await http.post(
  //       Uri.parse('https://api.stripe.com/v1/payment_intents'),
  //       headers: {
  //         'Authorization': 'Bearer ${testing ? secrets.secretTestKey : secrets.secretKey}',
  //         'Content-Type': 'application/x-www-form-urlencoded'
  //       },
  //       body: body,
  //     );
  //     appLogger.d(
  //         '[[ STRIPE PAYMENT API PAYMENT INTENT ]]${testing ? ' TEST' : ''} RESPONSE: ${response.body}');
  //     return json.decode(response.body);
  //   } catch (err) {
  //     appLogger.d(
  //         '[[ STRIPE PAYMENT API PAYMENT INTENT ]] CREATE ${testing ? ' TEST' : ''}PAYMENT INTENT $err');
  //     throw Exception(err.toString());
  //   }
  // }

  // static Future<bool> displayPaymentSheet({
  //   // required BuildContext context,
  //   // required bool liveProductOverride,
  //   required String paymentIntentClientSecret,
  // }) async {
  //   final testing = appTestingNotifier.value; //  && !liveProductOverride;
  //   bool paymentSuccessful = false;
  //   try {
  //     appLogger.d(
  //         '[[ STRIPE PAYMENT API DISPLAY PAYMENT SHEET ]] ATTEMPTING TO DISPLAY${testing ? ' TEST' : ''} PAYMENT SHEET');
  //     await strp.Stripe.instance
  //         .presentPaymentSheet(
  //             options: const strp.PaymentSheetPresentOptions(timeout: 1200000))
  //         .then((_) async {
  //       appLogger.d(
  //           '[[ STRIPE PAYMENT API DISPLAY PAYMENT SHEET ]]${testing ? ' TEST' : ''} PAYMENT SUCCESSFUL');
  //       paymentSuccessful = true;

  //       // await Stripe.instance
  //       //     .confirmPayment(
  //       //         paymentIntentClientSecret: paymentIntentClientSecret)
  //       //     .then((paymentConfirmation) {
  //       //   appLogger.d(
  //       //       '[[ STRIPE PAYMENT API DISPLAY PAYMENT SHEET ]]${testing ? ' TEST' : ''} PAYMENT INTENT CONFIRMATION: ${paymentConfirmation.toJson()}');
  //       //   if (paymentConfirmation.status.name == "successful") {
  //       //     appLogger.d(
  //       //         '[[ STRIPE PAYMENT API DISPLAY PAYMENT SHEET ]]${testing ? ' TEST' : ''} PAYMENT SUCCESSFUL WITH STATUS ${paymentConfirmation.status.name}');
  //       //     paymentSuccessful = true;
  //       //   } else {
  //       //     appLogger.d(
  //       //         '[[ STRIPE PAYMENT API DISPLAY PAYMENT SHEET ]]${testing ? ' TEST' : ''} PAYMENT UNSUCCESSFUL WITH STATUS ${paymentConfirmation.status.name}');
  //       //     paymentSuccessful = false;
  //       //   }
  //       // });

  //       // /// CONFIRM PAYMENT
  //       // appLogger.d(
  //       //     '[[ STRIPE PAYMENT API DISPLAY PAYMENT SHEET ]] CONFIRMING${testing ? ' TEST' : ''} PAYMENT HERE...');
  //       // await Stripe.instance.confirmPaymentSheetPayment();
  //       // appLogger.d(
  //       //     '[[ STRIPE PAYMENT API DISPLAY PAYMENT SHEET ]] AFTER${testing ? ' TEST' : ''} CONFIRMATION HERE...');

  //       // // Clear paymentIntent variable after successful payment
  //       // setState(() => paymentIntent = null);
  //     }).onError((error, stackTrace) {
  //       appLogger.d(
  //           '[[ STRIPE PAYMENT API DISPLAY PAYMENT SHEET ]]${testing ? ' TEST' : ''} PAYMENT SHEET INSTANCE $error.');
  //       paymentSuccessful = false;
  //       // Functions.popMessage(
  //       //     context,
  //       //     '${testing ? ' TEST' : ''} PAYMENT SHEET INSTANCE $error.',
  //       //     true);
  //       // throw Exception(error);
  //     });
  //   } on strp.StripeException catch (e) {
  //     appLogger.e(
  //
  //             // appLogger.d(
  //             '[[ STRIPE PAYMENT API DISPLAY PAYMENT SHEET ]] STRIPE${testing ? ' TEST' : ''} EXCEPTION $e');
  //     paymentSuccessful = false;
  //     const AlertDialog(
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Row(
  //             children: [
  //               Icon(
  //                 Icons.cancel,
  //                 color: Colors.red,
  //               ),
  //               Text("Payment Failed"),
  //             ],
  //           ),
  //         ],
  //       ),
  //     );
  //   } catch (e) {
  //     appLogger.e(
  //
  //             // appLogger.d(
  //             '[[ STRIPE PAYMENT API DISPLAY PAYMENT SHEET ]] STRIPE${testing ? ' TEST' : ''} EXCEPTION $e');
  //     paymentSuccessful = false;
  //     // Functions.popMessage(
  //     //     context, 'STRIPE${testing ? ' TEST' : ''} EXCEPTION $e', true);
  //   }

  //   return paymentSuccessful;
  // }

  static Future<List<StripeCustomer>> searchForExistingStripeCustomer({
    required StripeSecrets secrets,
    // int? createdAfterDate, // created > createdAfterDate
    required bool testing,
    String? name, // John Doe
    String? email, // name@email.com
    String? phone, // +19999999999
    Map<String, String>? metadataKeyAndValue, //
  }) async {
    List<StripeCustomer> existingStripeCustomers = [];
    String? queryUrl;

    appLogger.f(
        '[STRIPE API STRIPE CUSTOMER SEARCH] ${testing ? 'TEST' : ''} BEGINNING STRIPE CUSTOMER SEARCH...');

    ///
    if (name != null ||
        email != null ||
        phone != null ||
        metadataKeyAndValue != null) {
      queryUrl = email != null
          ? "https://api.stripe.com/v1/customers/search?query=email:'$email'"
          : name != null
              ? "https://api.stripe.com/v1/customers/search?query=name:'$name'"
              : phone != null
                  ? "https://api.stripe.com/v1/customers/search?query=phone:'$phone'"
                  // : createdAfterDate != null
                  //     ? "https://api.stripe.com/v1/customers/search?query=created:'$createdAfterDate'"
                  : metadataKeyAndValue != null &&
                          metadataKeyAndValue.entries.first.key.isNotEmpty &&
                          metadataKeyAndValue.entries.first.value.isNotEmpty
                      ? "https://api.stripe.com/v1/customers/search?query=metadata['${metadataKeyAndValue.entries.first.key}']:'${metadataKeyAndValue.entries.first.value}'"
                      : null;

      appLogger.f(
          "[STRIPE API STRIPE CUSTOMER SEARCH] ${testing ? 'TEST' : ''} SEARCHING FOR STRIPE CUSTOMER WITH QUERY STRING => $queryUrl\n\nName: $name\nEmail: $email\nPhone: $phone\nMetaData: $metadataKeyAndValue");

      if (queryUrl != null) {
        try {
          final customerSearchResponse = await http.get(
            Uri.parse(queryUrl),
            headers: {
              'Authorization':
                  'Bearer ${testing ? secrets.secretTestKey : secrets.secretKey}',
              'Content-Type': 'application/x-www-form-urlencoded'
            },
          );

          appLogger.d(
              '[STRIPE API STRIPE CUSTOMER SEARCH] ${testing ? 'TEST' : ''} STRIPE CUSTOMER SEARCH RESPONSE: ${customerSearchResponse.body}');

          if (customerSearchResponse.statusCode == 200) {
            var responseJson = jsonDecode(customerSearchResponse.body);
            final stripeCustomerList = List<StripeCustomer>.from(
                responseJson['data'].map((x) => StripeCustomer.fromJson(x)));

            appLogger.d(
                '[STRIPE API STRIPE CUSTOMER SEARCH] ${testing ? 'TEST' : ''} STRIPE CUSTOMER SEARCH DATA : [${stripeCustomerList.length}] Items --> ${stripeCustomerList.map((e) => e.toJson().toString())}');

            existingStripeCustomers = stripeCustomerList;
            stripeCustomerNotifier.value = stripeCustomerList;

            appLogger.f('[STRIPE API STRIPE CUSTOMER SEARCH] TEST 3');
          }
        } catch (e) {
          appLogger.e(
              '[[ STRIPE API STRIPE CUSTOMER SEARCH ]] ${testing ? 'TEST' : ''} STRIPE CUSTOMER SEARCH $e');
        }
      }
    } else {
      appLogger.w(
          '[STRIPE API STRIPE CUSTOMER SEARCH] ${testing ? 'TEST' : ''} STRIPE CUSTOMER SEARCH ERROR. ALL GIVEN PARAMETERS FOR SEARCH ARE NULL');
    }

    ///

    appLogger.f(
        '[STRIPE API STRIPE CUSTOMER SEARCH] RETURNING EXISTING ${testing ? 'TEST ' : ''}STRIPE CUSTOMERS: ${existingStripeCustomers.map((e) => e.toJson().toString())}');
    return existingStripeCustomers;
  }

  static Future<StripeCustomer?> getStripeCustomer({
    required StripeSecrets secrets,
    required bool testing,
    GeneralPurchaserInfo? purchaserInfo,
  }) async {
    ///
    StripeCustomer? stripeCustomer;

    if (purchaserInfo != null) {
      List<StripeCustomer> existingStripeCustomers =
          await searchForExistingStripeCustomer(
        secrets: secrets,
        testing: testing,
        name: purchaserInfo.fullName,
        email: purchaserInfo.email,
      );

      if (existingStripeCustomers.isNotEmpty) {
        appLogger.f(
            '[[ STRIPE PAYMENT API GET CUSTOMER ]] EXISTING ${testing ? 'TEST ' : ''}STRIPE CUSTOMERS FOUND!! ${existingStripeCustomers.map((e) => e.toJson().toString())}');

        stripeCustomer = existingStripeCustomers.first;

        ///
      } else {
        try {
          //Request body
          Map<String, String> body = {
            "metadata[app_user_id]": purchaserInfo.applicationUid,
          };

          if (purchaserInfo.email.isEmpty) {
            body.addAll({"email": purchaserInfo.email});
          }

          if (purchaserInfo.fullName.isNotEmpty) {
            body.addAll({"name": purchaserInfo.fullName});
          }

          if (purchaserInfo.description != null) {
            body.addAll({"description": purchaserInfo.description!});
          }

          if (purchaserInfo.phone != null) {
            body.addAll({"phone": purchaserInfo.description!});
          }

          ///
          appLogger.d(
              '[[ STRIPE PAYMENT API GET CUSTOMER ]] ATTEMPTING TO CREATE ${testing ? 'TEST ' : ''}CUSTOMER');

          var createCustomerResponse = await http.post(
            Uri.parse('https://api.stripe.com/v1/customers'),
            headers: {
              'Authorization':
                  'Bearer ${testing ? secrets.secretTestKey : secrets.secretKey}',
              'Content-Type': 'application/x-www-form-urlencoded'
            },
            body: body,
          );
          appLogger.d(
              '[[ STRIPE PAYMENT API GET CUSTOMER ]] CREATE ${testing ? 'TEST ' : ''}STRIPE CUSTOMER RESPONSE: ${createCustomerResponse.body}');

          stripeCustomer = stripeCustomerFromJson(createCustomerResponse.body);
        } catch (err) {
          appLogger.e(
              '[[ STRIPE PAYMENT API GET CUSTOMER ]] GET ${testing ? 'TEST ' : ''}CUSTOMER $err');
        }
      }
    } else {
      appLogger.e(
          '[[ STRIPE PAYMENT API GET CUSTOMER ]] GET ${testing ? 'TEST ' : ''}CUSTOMER LOCAL APP USER INFO NOT FOUND');
    }

    appLogger.f(
        '[[ STRIPE PAYMENT API GET CUSTOMER ]] RETURNING ${testing ? 'TEST ' : ''}CUSTOMER: ${stripeCustomer?.toJson().toString()}');
    return stripeCustomer;
  }

  // static Future<CustomerTemporaryEphemeralKey> getCustomerPaymentEphemeralKey({
  //   // required bool liveProductOverride,
  //   required StripeCustomer stripeCustomer,
  // }) async {
  //   final testing = appTestingNotifier.value; //  && !liveProductOverride;
  //   CustomerTemporaryEphemeralKey ephemeralKey;
  //   //! RETRIEVE EPHEMERAL KEY HERE...
  //   try {
  //     appLogger.d(
  //         '[[ STRIPE PAYMENT API EPHEMERAL KEY ]] ATTEMPTING TO CREATE${testing ? ' TEST' : ''} EPHEMERAL KEY');

  //     //Request body
  //     Map<String, dynamic> body = {
  //       'customer': stripeCustomer.id,
  //     };

  //     //Make post request to Stripe
  //     var response = await http.post(
  //       Uri.parse('https://api.stripe.com/v1/ephemeral_keys'),
  //       headers: {
  //         'Authorization': 'Bearer ${testing ? secrets.secretTestKey : secrets.secretKey}',
  //         'Content-Type': 'application/x-www-form-urlencoded',
  //         'Stripe-Version': '2022-11-15',
  //       },
  //       body: body,
  //     );
  //     appLogger.d(
  //         '[[ STRIPE PAYMENT API EPHEMERAL KEY ]]${testing ? ' TEST' : ''} RESPONSE: ${response.body}');
  //     ephemeralKey =
  //         CustomerTemporaryEphemeralKey.fromJson(jsonDecode(response.body));
  //     // return json.decode(response.body);
  //   } catch (err) {
  //     appLogger.e(
  //
  //             // appLogger.d(
  //             '[[ STRIPE PAYMENT API EPHEMERAL KEY ]] CREATE${testing ? ' TEST' : ''} EPHEMERAL KEY $err');
  //     throw Exception(err.toString());
  //   }
  //   return ephemeralKey;
  // }

  static Future<StripeProduct?> getExistingStripeProduct({
    required StripeSecrets secrets,
    required bool testing,
    required String productId,
  }) async {
    StripeProduct? existingProduct;

    try {
      appLogger.d(
          '[[ STRIPE API GET PRODUCT ]] ATTEMPTING TO GET${testing ? ' TEST' : ''} PRODUCT');

      var productResponse = await http.post(
        Uri.parse('https://api.stripe.com/v1/products/$productId'),
        headers: {
          'Authorization':
              'Bearer ${testing ? secrets.secretTestKey : secrets.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        // body: body,
      );
      appLogger.d(
          '[[ STRIPE API GET PRODUCT ]] GET${testing ? ' TEST' : ''} PRODUCT RESPONSE: ${productResponse.body}');

      if (productResponse.statusCode == 200) {
        var retrievedProduct = stripeProductFromJson(productResponse.body);
        existingProduct = retrievedProduct;
      } else {
        appLogger.e(
            '[[ STRIPE API GET PRODUCT ]] GET${testing ? ' TEST' : ''} PRODUCT RESPONSE ERROR STATUS CODE: ${productResponse.statusCode}');
      }
    } catch (err) {
      appLogger.e(

          // appLogger.d(
          '[[ STRIPE API GET PRODUCT ]] GET${testing ? ' TEST' : ''} PRODUCT $err');
    }
    return existingProduct;
  }

  static Future<List<StripeProduct?>> createStripeProduct({
    required StripeSecrets secrets,
    required bool testing,
    required GeneralProductInfo productInfo,
    PriceCalculations? priceCalculations,
  }) async {
    StripeProduct? stripeLiveProduct;
    StripeProduct? stripeTestProduct;
    try {
      appLogger.d(
          '[[ STRIPE API CREATE PRODUCT ]] ATTEMPTING TO CREATE${testing ? ' TEST' : ''} PRODUCT');

      //Request body
      Map<String, dynamic> body = {
        "id": productInfo.id,
        // "id": product.id,
        "name": productInfo.title,
        // "name": product.title,
        "description": productInfo.description,
        // "features": product.otherAttributes,
        "default_price_data[currency]": "usd",
        "default_price_data[unit_amount_decimal]":
            // priceCalculations == null
            //     ?
            "${(productInfo.retailPrice * 100).truncate()}"
        // : "${(priceCalculations.finalBuyPrice * 100).truncate()}"
        ,
        // "${(product.retailPrice * 100).truncate()}",
        "shippable": "true",
        "unit_label": "pc",
        "statement_descriptor": "SCAPEGOATS",
        "images[0]": productInfo.imageUrls.first,
        // "metadata[cost_string]": "${(product.cost * 100).toInt()}",
        // "metadata[retail_price_string]":
        //     "${(product.retailPrice * 100).toInt()}",
      };

      /// CREATE LIVE STRIPE PRODUCT
      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/products'),
        headers: {
          'Authorization':
              'Bearer ${testing ? secrets.secretTestKey : secrets.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: body,
      );
      appLogger.d(
          '[[ STRIPE API CREATE PRODUCT ]] CREATE${testing ? ' TEST' : ''} PRODUCT RESPONSE: ${response.body}');
      var newLiveProduct = stripeProductFromJson(response.body);
      stripeLiveProduct = newLiveProduct;
    } catch (err) {
      appLogger.e('[[ STRIPE API CREATE PRODUCT ]] CREATE PRODUCT $err');
    }
    return [stripeLiveProduct, stripeTestProduct];
  }

  static Future<StripePrice?> getStripePrice({
    required StripeSecrets secrets,
    required bool testing,
    required GeneralProductInfo productInfo,
    bool createNewPrice = false,
  }) async {
    StripePrice? price;
    PriceCalculations? priceCalculations = priceCalculationsNotifier.value;

    if (!createNewPrice) {
      try {
        /// Check for existing price
        price = await searchForExistingStripePrice(
          secrets: secrets,
          testing: testing,
          productInfo: productInfo,
          priceToCheck: priceCalculations!.retailPrice,
          // priceToCheck: priceCalculations!.finalBuyPrice,
        );
        appLogger.d(
            '[[ STRIPE API CREATE PRICE ]] RETURNED PRICE OBJECT IS: ${price?.toJson().toString()}');
      } catch (e) {
        appLogger.d('[[ STRIPE API CREATE PRICE ]] SEARCH FOR STRIPE PRICE $e');
      }
    }

    if (createNewPrice || price == null) {
      try {
        // appLogger.d(
        //     '[[ STRIPE API CREATE PRICE ]] CURRENT PRICE OBJECT IS: ${price?.toJson().toString()}, ATTEMPTING TO CREATE${testing ? ' TEST' : ''} PRICE WITH ${priceCalculations?.finalBuyPrice}');
        appLogger.d(
            '[[ STRIPE API CREATE PRICE ]] CURRENT PRICE OBJECT IS: ${price?.toJson().toString()}, ATTEMPTING TO CREATE${testing ? ' TEST' : ''} PRICE WITH ${priceCalculations?.retailPrice}');

        //Request body
        Map<String, String> priceBody = {
          // "product": productInfo.id,
          "unit_amount":
              (priceCalculations!.retailPrice * 100).toStringAsFixed(0),
          // (priceCalculations!.finalBuyPrice * 100).toStringAsFixed(0),
          "currency": "usd",
          "product_data[name]": productInfo.title,
        };

        //Make post request to Stripe
        var priceResponse = await http.post(
          Uri.parse('https://api.stripe.com/v1/prices'),
          headers: {
            'Authorization':
                'Bearer ${testing ? secrets.secretTestKey : secrets.secretKey}',
            'Content-Type': 'application/x-www-form-urlencoded'
          },
          body: priceBody,
        );

        ///
        appLogger.i(
            '[[ STRIPE API CREATE PRICE ]]${testing ? ' TEST' : ''} RESPONSE: ${priceResponse.body}');

        if (priceResponse.body.contains("No such product")) {
          appLogger.i(
              '[[ STRIPE API CREATE PRICE ]] THE PROVIDED${testing ? ' TEST' : ''} PRICE WAS NOT FOUND. ATTEMPTING TO CREATE NEW...');
          StripePrice? newPrice = await getStripePrice(
            secrets: secrets,
            testing: testing,
            productInfo: productInfo,
            createNewPrice: true,
          );

          if (newPrice != null) {
            appLogger.i(
                '[[ STRIPE API CREATE PRICE ]] NEW${testing ? ' TEST' : ''} PRICE CREATED SUCCESSFULLY. CONTINUING CURRENT PROCESS...');
          }
        } else {
          price = StripePrice.fromJson(jsonDecode(priceResponse.body));
        }
      } catch (err) {
        appLogger.e(
            '[[ STRIPE API CREATE PRICE ]] CREATE${testing ? ' TEST' : ''} PRICE $err');
      }
    } else {
      appLogger.i(
          '[[ STRIPE API CREATE PRICE ]] NEW PRICE NOT REQUIRED. EXISTING PRICE USED: ${price.toJson().toString()}');
    }
    return price;
  }

  static Future<StripePrice?> searchForExistingStripePrice({
    required StripeSecrets secrets,
    required bool testing,
    GeneralProductInfo? productInfo,
    required double priceToCheck,
  }) async {
    StripePrice? existingStripePrice;

    var queryUrl = productInfo != null
        ? "https://api.stripe.com/v1/prices/search?query=active:'true' AND product:'${productInfo.id}'"
        : "https://api.stripe.com/v1/prices/search?query=active:'true'";

    try {
      final priceSearchResponse = await http.get(
        Uri.parse(queryUrl),
        headers: {
          'Authorization':
              'Bearer ${testing ? secrets.secretTestKey : secrets.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
      );

      appLogger.d(
          '[STRIPE API STRIPE PRICE SEARCH] STRIPE PRICE SEARCH RESPONSE: ${priceSearchResponse.body}');

      if (priceSearchResponse.statusCode == 200) {
        var responseJson = jsonDecode(priceSearchResponse.body);
        final stripePriceList = List<StripePrice>.from(
            responseJson['data'].map((x) => StripePrice.fromJson(x)));
        appLogger.d(
            '[STRIPE API STRIPE PRICE SEARCH] STRIPE PRICE SEARCH DATA : [${stripePriceList.length}] Items --> ${stripePriceList.map((e) => e.unitAmountDecimal)}');

        List<StripePrice> reducedList = [];
        if (productInfo != null) {
          reducedList = stripePriceList
              .where((item) =>
                  item.product == productInfo.id &&
                  item.unitAmountDecimal ==
                      (priceToCheck * 100).toStringAsFixed(0))
              .toList();
        } else {
          reducedList = stripePriceList
              .where((item) =>
                  item.unitAmountDecimal ==
                  (priceToCheck * 100).toStringAsFixed(0))
              .toList();
        }
        if (reducedList.isNotEmpty) {
          appLogger.f(
              '[STRIPE API STRIPE PRICE SEARCH] STRIPE PRICE REDUCED LIST: [${reducedList.length}] Items --> ${reducedList.map((e) => e.unitAmountDecimal)}');
          existingStripePrice = reducedList.first;
        } else {
          appLogger.f(
              '[STRIPE API STRIPE PRICE SEARCH] STRIPE PRICE REDUCED LIST IS EMPTY: [${reducedList.length}]');
          // existingStripePrice = stripePriceList.first;
        }
      }
    } catch (e) {
      appLogger.e(
          '[[ STRIPE API STRIPE PRICE SEARCH ]] ${testing ? 'TEST' : ''} STRIPE PRICE SEARCH $e');
    }

    ///
    appLogger.f(
        '[STRIPE API STRIPE PRICE SEARCH] RETURNING EXISTING STRIPE PRICE REDUCED LIST FIRST ITEM: [${existingStripePrice?.toJson().toString()}]');
    return existingStripePrice;
  }

  static Future<String?> createStripePaymentLink({
    required StripeSecrets secrets,
    required bool testing,
    required String appUserId,
    required StripeCustomer customer,
    required GeneralPurchaserInfo purchaserInfo,
    required GeneralProductInfo productInfo,
  }) async {
    appLogger.d(
        '[[ STRIPE API CREATE PAYMENT LINK ]] ATTEMPTING TO CREATE ${testing ? 'TEST' : ''} WEB PAYMENT LINK');

    /// CHECK FOR PRICE ID
    String? priceId;

    var priceCalculations = priceCalculationsNotifier.value;

    if (priceCalculations != null) {
      appLogger.w(
          '[STRIPE API CREATE PAYMENT LINK] ATTEMPTING TO CREATE ADJUSTED ${testing ? 'TEST' : ''} PRICE ID WITH NEWLY CALCULATED DATA...');
      await getStripePrice(
        secrets: secrets,
        testing: testing,
        productInfo: productInfo,
      ).then((newPrice) {
        if (newPrice != null) {
          priceId = newPrice.id;
        }
      });
    }

    /// CHECK FOR SHIPPING ID
    String? shippingId;
    appLogger.d(
        '[STRIPE API CREATE PAYMENT LINK] CREATING STRIPE ${testing ? 'TEST' : ''} SHIPPING ID');
    await getStripeProductShippingPrice(
      secrets: secrets,
      testing: testing,
      productInfo: productInfo,
    ).then((newShippingId) {
      shippingId = newShippingId?.id;
    });

    /// CREATE PURCHASE PAYMENT LINK
    if (shippingId != null && priceId != null) {
      final body = <String, String>{
        "line_items[0][price]": priceId!,
        "line_items[0][quantity]": "1",
        "shipping_options[0][shipping_rate]": shippingId!,
        "billing_address_collection": "required",
        // "shipping_address_collection[allowed_countries][0]": "US",
        //? "shipping_address_collection[allowed_countries][1]": "CA",
        // "after_completion[type]": "redirect",
        // "after_completion[redirect][url]": Application.paymentSuccessUrl,
        "after_completion[type]": "hosted_confirmation",
        "after_completion[hosted_confirmation][custom_message]":
            "Your transaction is complete. You may now close this window.",
        "allow_promotion_codes": "true",
        // "automatic_tax[enabled]": "true",
        "metadata[app_user_id]": appUserId,
        // "metadata[app_user_id]": appUser.appUserId,
        "metadata[order_options]":
            productInfo.orderOptions ?? "No options for this order",
      };

      if (productInfo.shipToRegions.isNotEmpty) {
        var regions = productInfo.shipToRegions;
        for (var i = 0; i < regions.length; i++) {
          body.addAll({
            "shipping_address_collection[allowed_countries][$i]":
                // ignore: unnecessary_string_interpolations
                "${regions[i].toUpperCase()}"
          });
        }
      } else {
        body.addAll(
            {"shipping_address_collection[allowed_countries][0]": "US"});
      }

      final paymentLinkResponse = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_links'),
        headers: {
          'Authorization':
              'Bearer ${testing ? secrets.secretTestKey : secrets.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: body,
      );

      appLogger.d(
          '[STRIPE API CREATE PAYMENT LINK] ${testing ? 'TEST' : ''} PAYMENT LINK RESPONSE: ${paymentLinkResponse.body}');

      if (paymentLinkResponse.statusCode == 200) {
        var responseJson = jsonDecode(paymentLinkResponse.body);
        final String rootPaymentLink = responseJson['url'];
        appLogger.d(
            '[STRIPE API CREATE PAYMENT LINK] ${testing ? 'TEST' : ''} PAYMENT LINK ROOT: $rootPaymentLink');
        final String paymentLinkId = responseJson["id"];

        appLogger.f(
            '[STRIPE API CREATE PAYMENT LINK] ${testing ? 'TEST' : ''} PRICE CALCULATIONS USED: ${priceCalculations?.toDisplayString()}');

        /// Get coupon and promo-code
        PromoCode? promoCode;
        await getCouponAndPromoCode(
                secrets: secrets,
                testing: testing,
                productInfo: productInfo,
                percentOff: priceCalculations!.totalPercentOff)
            .then((val) {
          if (val != null) {
            promoCode = val.promoCode;
          }
        });

        /// Create final payment link
        final String customerPaymentLink = promoCode != null
            ? "$rootPaymentLink?prefilled_email=${purchaserInfo.email}&client_reference_id=$appUserId&prefilled_promo_code=${promoCode!.code}"
            : "$rootPaymentLink?prefilled_email=${purchaserInfo.email}&client_reference_id=$appUserId";

        appLogger.d(
            '[STRIPE API CREATE PAYMENT LINK] ${testing ? 'TEST' : ''} PAYMENT LINK RETURNED: $customerPaymentLink');
        return "$paymentLinkId$stripePaymentDelimiter$customerPaymentLink";
      } else {
        appLogger.e(
            '[STRIPE API CREATE PAYMENT LINK] CREATE ${testing ? 'TEST' : ''} PAYMENT LINK API CALL ${paymentLinkResponse.statusCode}');
        return null;
      }
    } else {
      appLogger.e(
          '[STRIPE API CREATE PAYMENT LINK] FAILED TO CREATE ${testing ? 'TEST' : ''} PAYMENT LINK. UNABLE TO CREATE SHIPPING ID OR PRICE ID IS NULL');
      return null;
    }
  }

  static Future<StripeShippingPrice?> getStripeProductShippingPrice({
    required StripeSecrets secrets,
    required bool testing,
    required GeneralProductInfo productInfo,
  }) async {
    StripeShippingPrice? finalShippingId;
    double shippingAndHandling = productInfo.defaultHandlingPrice +
        (productInfo.retailPrice * productInfo.defaultShippingMultiplier);

    /// Check for existing price
    try {
      finalShippingId = await searchForExistingShippingPrice(
        secrets: secrets,
        testing: testing,
        priceToCheck: shippingAndHandling,
      );

      ///
    } catch (e) {
      appLogger.d('[[ STRIPE API CREATE PRICE ]] SEARCH FOR STRIPE PRICE $e');
    }

    ///
    if (finalShippingId == null) {
      try {
        appLogger.d(
            '[[ STRIPE API CREATE SHIPPING ID ]] ATTEMPTING TO CREATE ${testing ? 'TEST' : ''} SHIPPING ID');

        //Request body
        Map<String, dynamic> body = {
          "display_name": "Shipping & Handling",
          "type": "fixed_amount",
          "fixed_amount[amount]": "${(shippingAndHandling * 100).toInt()}",
          "fixed_amount[currency]": "usd",
          // "metadata[cost_string]": "${(product.cost * 100).toInt()}",
          // "metadata[retail_price_string]":
          //     "${(product.retailPrice * 100).toInt()}",
        };

        /// CREATE LIVE SHIPPING ID
        var response = await http.post(
          Uri.parse('https://api.stripe.com/v1/shipping_rates'),
          headers: {
            'Authorization':
                'Bearer ${testing ? secrets.secretTestKey : secrets.secretKey}',
            'Content-Type': 'application/x-www-form-urlencoded'
          },
          body: body,
        );
        appLogger.d(
            '[[ STRIPE API CREATE SHIPPING ID ]] ${testing ? 'TEST' : ''} SHIPPING ID RESPONSE: ${response.body}');
        finalShippingId = stripeShippingIdFromJson(response.body);
      } catch (err) {
        appLogger.e(
            '[[ STRIPE API CREATE SHIPPING ID ]] CREATE ${testing ? 'TEST' : ''} SHIPPING ID $err');
      }
    } else {
      appLogger.d(
          '[[ STRIPE API CREATE SHIPPING ID ]] EXISTING ${testing ? 'TEST' : ''} SHIPPING ID FOUND!');
    }
    return finalShippingId;
  }

  static Future<StripeShippingPrice?> searchForExistingShippingPrice({
    required StripeSecrets secrets,
    required bool testing,
    required double priceToCheck,
  }) async {
    StripeShippingPrice? existingStripePrice;

    var queryUrl = "https://api.stripe.com/v1/shipping_rates";

    try {
      final searchResponse = await http.get(
        Uri.parse(queryUrl),
        headers: {
          'Authorization':
              'Bearer ${testing ? secrets.secretTestKey : secrets.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
      );

      appLogger.d(
          '[STRIPE API STRIPE SHIPPING PRICE SEARCH] STRIPE ${testing ? 'TEST' : ''} SHIPPING PRICE SEARCH RESPONSE: ${searchResponse.body}');

      if (searchResponse.statusCode == 200) {
        var responseJson = jsonDecode(searchResponse.body);
        final shippingPriceList = List<StripeShippingPrice>.from(
            responseJson['data'].map((x) => StripeShippingPrice.fromJson(x)));
        appLogger.d(
            '[STRIPE API STRIPE SHIPPING PRICE SEARCH] STRIPE ${testing ? 'TEST' : ''} SHIPPING PRICE SEARCH DATA : [${shippingPriceList.length}] Items --> ${shippingPriceList.map((e) => e.id)}');

        List<StripeShippingPrice> reducedList = [];
        reducedList = shippingPriceList
            .where((item) =>
                item.fixedAmount.amount.toString() ==
                (priceToCheck * 100).toStringAsFixed(0))
            .toList();

        ///
        if (reducedList.isNotEmpty) {
          appLogger.f(
              '[STRIPE API STRIPE SHIPPING PRICE SEARCH] STRIPE ${testing ? 'TEST' : ''} SHIPPING PRICE REDUCED LIST: [${reducedList.length}] Items --> ${reducedList.map((e) => e.id)}');
          existingStripePrice = reducedList.first;
        } else {
          appLogger.f(
              '[STRIPE API STRIPE SHIPPING PRICE SEARCH] STRIPE ${testing ? 'TEST' : ''} SHIPPING PRICE REDUCED LIST IS EMPTY: [${reducedList.length}]');
        }
      }
    } catch (e) {
      appLogger.e(
          '[[ STRIPE API STRIPE SHIPPING PRICE SEARCH ]] ${testing ? 'TEST' : ''} STRIPE SHIPPING PRICE SEARCH $e');
    }

    ///
    return existingStripePrice;
  }

  static Future<(bool, CheckoutSessionsDatum?, PriceCalculations?)>
      verifyStripePayment({
    required StripeSecrets secrets,
    required bool testing,
    required GeneralProductInfo productInfo,
    required String customerId,
    required String paymentLink,
  }) async {
    /// RETRIEVE RECENT CHECKOUT SESSIONS
    bool verified = false;
    PriceCalculations? newPriceCalculations;
    PriceCalculations? currentPriceCalculations =
        priceCalculationsNotifier.value;
    CheckoutSessionsDatum? checkoutSession;
    List<CheckoutSessionsDatum> checkoutSessionsList =
        await getRecentCheckoutSessions(
      secrets: secrets,
      testing: testing,
      customerId: customerId,
      paymentLink: paymentLink,
    );
    appLogger.d(
        '[STRIPE API PURCHASE VERIFICATION] ${checkoutSessionsList.length} CHECKOUT SESSIONS RECEIVED');

    /// START PURCHASE VERIFICATION
    if (checkoutSessionsList.isNotEmpty) {
      appLogger.d(
          '[STRIPE API PURCHASE VERIFICATION] THIS PRODUCT: ${productInfo.title} - ${checkoutSessionsList.length} CHECKOUT SESSIONS');

      final bool purchaseIsValid = checkoutSessionsList.any(
        (element) =>
            element.status == "complete" && element.paymentStatus == "paid",
      );

      if (purchaseIsValid) {
        purchaseSuccessfulNotifier.value = true;
        verified = true;
        checkoutSession = checkoutSessionsList.firstWhere((element) =>
            element.status == "complete" && element.paymentStatus == "paid");

        /// CHECK FOR DISCREPANCIES IN LOCAL PRICES VS. FINAL STRIPE PRICES
        var currentOrderFinalPrice = double.parse(
            currentPriceCalculations!.totalForThisSale.toStringAsFixed(2));

        var checkoutSessionFinalPrice = double.parse(
            (checkoutSession.amountTotal! / 100).toStringAsFixed(2));

        appLogger.w(
            "[STRIPE API PURCHASE VERIFICATION] CHECKING FOR FINAL ORDER PRICE EQUALITY. LOCAL APP PRICE:$currentOrderFinalPrice VS. $checkoutSessionFinalPrice");

        if (currentOrderFinalPrice != checkoutSessionFinalPrice) {
          appLogger.f(
              "[STRIPE API PURCHASE VERIFICATION] PRICE COMPARISON DISCREPANCY FOUND. UPDATING PRICE CALCULATIONS TO FINAL VALUES...");

          ///
          double checkoutSessionFinalPercentOff =
              (checkoutSession.totalDetails.amountDiscount /
                      checkoutSession.amountSubtotal!) *
                  100;
          double checkoutSessionFinalSubtotal =
              (checkoutSession.amountSubtotal! -
                      checkoutSession.totalDetails.amountDiscount) /
                  100;

          ///
          newPriceCalculations = PriceCalculations(
            retailPrice: currentPriceCalculations.retailPrice,
            salePrice: currentPriceCalculations.salePrice,
            memberPrice: currentPriceCalculations.memberPrice,
            // finalBuyPrice: currentPriceCalculations.finalBuyPrice,
            totalPercentOff: checkoutSessionFinalPercentOff,
            shippingPrice: currentPriceCalculations.shippingPrice,
            subtotal: checkoutSessionFinalSubtotal,
            totalForThisSale: checkoutSessionFinalPrice,
          );

          /// UPDATE NOTIFIEER
          priceCalculationsNotifier.value = newPriceCalculations;
        }
      }
    }
    return (
      verified,
      checkoutSession,
      newPriceCalculations ?? currentPriceCalculations
    );
  }

  /// GET RECENT CHECKOUT SESSIONS
  static Future<List<CheckoutSessionsDatum>> getRecentCheckoutSessions({
    required StripeSecrets secrets,
    required bool testing,
    required String customerId,
    required String paymentLink,
  }) async {
    // final testing = appTestingNotifier.value;
    // var localData = localDataNotifier.value;
    List<CheckoutSessionsDatum> sessionsList = [];

    try {
      appLogger.d(
          '[STRIPE API GET CHECKOUT SESSIONS] FETCHING CHECKOUT SESSIONS...');
      final checkoutSessionsResponse = await http.get(
        Uri.parse('https://api.stripe.com/v1/checkout/sessions'),
        headers: {
          'Authorization':
              'Bearer ${testing ? secrets.secretTestKey : secrets.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
      );

      if (checkoutSessionsResponse.statusCode == 200) {
        appLogger.d(
            '[STRIPE API GET CHECKOUT SESSIONS] CHECKOUT SESSIONS STATUS CODE: ${checkoutSessionsResponse.statusCode}');

        final checkoutSessions =
            checkoutSessionsFromJson(checkoutSessionsResponse.body);

        List<CheckoutSessionsDatum> stripeCheckoutSessionsList =
            checkoutSessions.data;

        appLogger.d(
            '[STRIPE API GET CHECKOUT SESSIONS] ${stripeCheckoutSessionsList.length} CHECKOUT SESSIONS RETRIEVED');

        appLogger.d(
            '[STRIPE API GET CHECKOUT SESSIONS] FIRST ${testing ? 'TEST' : ''} CHECKOUT SESSIONS RESPONSE DATA PAYMENT LINK : ${stripeCheckoutSessionsList.first.paymentLink} VS. COMPARABLE PAYMENT LINK: $paymentLink');
        stripeCheckoutSessionsList
            .retainWhere((element) => element.paymentLink == paymentLink);
        appLogger.d(
            '[STRIPE API GET CHECKOUT SESSIONS] ${stripeCheckoutSessionsList.length} CHECKOUT SESSION REMAIN AFTER PRUNING FOR PAYMENT-LINK');

        if (stripeCheckoutSessionsList.isNotEmpty &&
            stripeCheckoutSessionsList.first.customerDetails != null &&
            stripeCheckoutSessionsList.first.shippingDetails != null) {
          ///! SAVE SESSION SHIPPING ADDRESS TO LOCAL DATABASE
          var thisCheckoutSession = stripeCheckoutSessionsList.first;
          var custDet = thisCheckoutSession.customerDetails;
          var shipDet = thisCheckoutSession.shippingDetails;

          ///
          // ignore: unused_local_variable
          var orderAddress = CustomerAddress(
            city: shipDet!.address.city,
            country: shipDet.address.country,
            line1: shipDet.address.line1,
            line2: shipDet.address.line2,
            postalCode: shipDet.address.postalCode,
            state: shipDet.address.state,
            fullName: shipDet.name,
            email: custDet!.email,
            phone: custDet.phone ?? "",
          );
        }

        sessionsList = stripeCheckoutSessionsList;
      } else {
        appLogger.d(
            '[STRIPE API GET CHECKOUT SESSIONS] NO ${testing ? 'TEST' : ''} CHECKOUT SESSIONS FOUND: STATUS CODE = ${checkoutSessionsResponse.statusCode}');
      }
    } catch (e) {
      appLogger.e(
          '[STRIPE API GET CHECKOUT SESSIONS] ${testing ? 'TEST' : ''} CHECKOUT SESSIONS RETRIEVAL $e');
    }
    return sessionsList;
  }

  static Future<CouponAndPromoCode?> getCouponAndPromoCode({
    required StripeSecrets secrets,
    required bool testing,
    GeneralProductInfo? productInfo,
    bool memberLoggedIn = false,
    bool isFirstPurchase = false,
    double? memberPercentOff,
    String? couponName,
    double? percentOff,
    int? maxRedemptions,
  }) async {
    Coupon? newCoupon;
    PromoCode? newPromoCode;

    if (productInfo != null) {
      var priceCalculations = priceCalculationsNotifier.value ??
          await PriceCalculations.calculatePrices(
            isFirstPurchase: isFirstPurchase,
            memberLoggedIn: memberLoggedIn,
            memberPercentOff: memberPercentOff,
            retailPrice: productInfo.retailPrice,
            salePercentOff: productInfo.salePercentOff,
            defaultProductHandlingPrice: productInfo.defaultHandlingPrice,
            shippingPriceMultiplier: productInfo.defaultShippingMultiplier,
          );

      appLogger.w(
          '[STRIPE API CREATE COUPON WITH PROMO CODE] FINAL PERCENT OFF TO BE USED ==> ${priceCalculations.totalPercentOff}%');

      if ((percentOff != null && percentOff > 0.01) ||
          priceCalculations.totalPercentOff > 0.01) {
        await getCoupon(
          secrets: secrets,
          testing: testing,
          productInfo: productInfo,
          // product: product,
          couponName: couponName,
          maxRedemptions: maxRedemptions,
        ).then((coupon) async {
          if (coupon != null) {
            appLogger.i(
                '[STRIPE API CREATE COUPON WITH PROMO CODE] COUPON TO BE USED ==> ${coupon.id}');
            newCoupon = coupon;
            await getPromoCode(
                    secrets: secrets, testing: testing, coupon: coupon)
                .then((promoCode) {
              if (promoCode != null) {
                appLogger.i(
                    '[STRIPE API CREATE COUPON WITH PROMO CODE] PROMO CODE TO BE USED ==> ${promoCode.code}');
                newPromoCode = promoCode;
              }
            });
          } else {
            appLogger.e(
                '[STRIPE API CREATE COUPON WITH PROMO CODE] COUPON RETURNED NULL. PROMO CODE NOT CREATED.');
          }
        });
      } else {
        appLogger.w(
            '[STRIPE API CREATE COUPON WITH PROMO CODE] DISCOUNT PERCENT IS ${priceCalculations.totalPercentOff}. COUPON NOT REQUIRED.');
      }
    }
    return newCoupon == null || newPromoCode == null
        ? null
        : CouponAndPromoCode(coupon: newCoupon!, promoCode: newPromoCode!);
  }

  static Future<Coupon?> getCoupon({
    required StripeSecrets secrets,
    required bool testing,
    GeneralProductInfo? productInfo,
    String? couponName,
    int? maxRedemptions,
  }) async {
    var priceCalculations = priceCalculationsNotifier.value;
    Coupon? coupon;

    ///
    try {
      if (productInfo?.salePercentOff != null) {
        await checkForExistingCoupon(
                secrets: secrets,
                testing: testing,
                percentOff: priceCalculations?.totalPercentOff ??
                    productInfo!.salePercentOff!)
            .then((value) {
          if (value != null) {
            coupon = value;
          }
        });
      }
    } catch (e) {
      appLogger.e(
          '[[ STRIPE API CREATE COUPON ]] GET${testing ? ' TEST' : ''} EXISTING COUPON RETRIEVAL ERROR. ATTEMPTING TO CREATE NEW...\n $e');
    }

    ///
    if (coupon == null) {
      try {
        appLogger.d(
            '[[ STRIPE API CREATE COUPON ]] ATTEMPTING TO GET${testing ? ' TEST' : ''} COUPON');

        //Request body
        Map<String, String>? couponBody;

        if (priceCalculations != null) {
          couponBody = {
            "name": couponName ??
                "${priceCalculations.totalPercentOff.toStringAsFixed(2)}% OFF",
            "percent_off": priceCalculations.totalPercentOff.toStringAsFixed(2),
            "currency": "usd",
            "duration": "forever",
          };

          if (maxRedemptions != null) {
            couponBody.addAll({
              "max_redemptions": maxRedemptions.toString(),
            });
          }
        }

        if (couponBody != null) {
          //Make post request to Stripe
          var couponResponse = await http.post(
            Uri.parse('https://api.stripe.com/v1/coupons'),
            headers: {
              'Authorization':
                  'Bearer ${testing ? secrets.secretTestKey : secrets.secretKey}',
              'Content-Type': 'application/x-www-form-urlencoded'
            },
            body: couponBody,
          );
          appLogger.i(
              '[[ STRIPE API GET COUPON ]]${testing ? ' TEST' : ''} RESPONSE: ${couponResponse.body}');
          var newCoupon = Coupon.fromJson(jsonDecode(couponResponse.body));
          coupon = newCoupon;
        }
      } catch (err) {
        appLogger.e(
            '[[ STRIPE API GET COUPON ]] GET${testing ? ' TEST' : ''} COUPON/PROMO-CODE $err');
      }
    }

    ///
    return coupon;
  }

  static Future<Coupon?> checkForExistingCoupon(
      {required StripeSecrets secrets,
      required bool testing,
      required double percentOff}) async {
    Coupon? existingCoupon;

    try {
      ///
      await getAllCoupons(secrets: secrets, testing: testing).then((coupons) {
        if (coupons.isNotEmpty &&
            coupons.map((e) => e.percentOff).any((element) =>
                element.toStringAsFixed(2) == percentOff.toStringAsFixed(2))) {
          var possibleCoupon = coupons.firstWhere((coupon) =>
              coupon.percentOff.toStringAsFixed(2) ==
              percentOff.toStringAsFixed(2));

          ///
          if (possibleCoupon.livemode == !testing &&
              possibleCoupon.valid &&
              (possibleCoupon.maxRedemptions == null ||
                  (possibleCoupon.maxRedemptions != null &&
                      possibleCoupon.timesRedeemed <
                          possibleCoupon.maxRedemptions))) {
            existingCoupon = possibleCoupon;
          }
        }
      });
    } catch (e) {
      appLogger.e(
          '[[ STRIPE API CHECK FOR EXISTING COUPON ]] ${testing ? 'TEST' : ''} EXISTING COUPON RETRIEVAL $e');
    }

    ///
    return existingCoupon;
  }

  static Future<List<Coupon>> getAllCoupons(
      {required StripeSecrets secrets, required bool testing}) async {
    List<Coupon> coupons = [];

    try {
      appLogger.d(
          '[[ STRIPE PAYMENT API COUPONS ]] ATTEMPTING TO RETRIEVE${testing ? ' TEST' : ''} COUPONS');

      //Make post request to Stripe
      var response = await http.get(
        Uri.parse('https://api.stripe.com/v1/coupons'),
        headers: {
          'Authorization':
              'Bearer ${testing ? secrets.secretTestKey : secrets.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );
      appLogger.d(
          '[[ STRIPE PAYMENT API COUPONS ]]${testing ? ' TEST' : ''} RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        var stripeCouponList =
            StripeCouponList.fromJson(jsonDecode(response.body));
        coupons = stripeCouponList.coupons;
        appLogger.d(
            '[[ STRIPE PAYMENT API COUPONS ]]${testing ? ' TEST' : ''} COUPONS RETRIEVE: ${coupons.map((e) => e.id).join(",\n")}');
      } else {
        appLogger.d(
            '[[ STRIPE PAYMENT API COUPONS ]] RETRIEVE${testing ? ' TEST' : ''} COUPONS JSON DECODE ${response.statusCode}');
      }
    } catch (err) {
      appLogger.e(
          '[[ STRIPE PAYMENT API COUPONS ]] RETRIEVE${testing ? ' TEST' : ''} COUPONS RETRIEVAL $err');
      throw Exception(err.toString());
    }
    return coupons;
  }

  static Future<PromoCode?> getPromoCode({
    required StripeSecrets secrets,
    required bool testing,
    required Coupon coupon,
    StripeCustomer? customer,
  }) async {
    PromoCode? promotionCode;

    ///
    try {
      await checkForExistingPromoCode(
              secrets: secrets, testing: testing, coupon: coupon)
          .then((value) {
        if (value != null) {
          promotionCode = value;
        }
      });
    } catch (e) {
      appLogger.e(
          '[[ STRIPE API CREATE PROMO CODE ]] GET${testing ? ' TEST' : ''} EXISTING PROMO CODE RETRIEVAL ERROR. ATTEMPTING TO CREATE NEW...\n $e');
    }

    ///
    if (promotionCode == null) {
      try {
        appLogger.d(
            '[[ STRIPE API CREATE PROMO CODE ]] ATTEMPTING TO CREATE${testing ? ' TEST' : ''} PROMO CODE');

        //Request body
        Map<String, String> promoCodeBody = {
          "coupon": coupon.id,
        };

        if (coupon.maxRedemptions != null) {
          promoCodeBody.addAll({
            "max_redemptions": coupon.maxRedemptions,
          });
        }

        var promoCodeResponse = await http.post(
          Uri.parse('https://api.stripe.com/v1/promotion_codes'),
          headers: {
            'Authorization':
                'Bearer ${testing ? secrets.secretTestKey : secrets.secretKey}',
            'Content-Type': 'application/x-www-form-urlencoded'
          },
          body: promoCodeBody,
        );
        appLogger.i(
            '[[ STRIPE API CREATE PROMO CODE ]]${testing ? ' TEST' : ''} RESPONSE: ${promoCodeResponse.body}');
        PromoCode newPromoCode =
            PromoCode.fromJson(jsonDecode(promoCodeResponse.body));
        appLogger.i(
            '[[ STRIPE API CREATE PROMO CODE ]]${testing ? ' TEST' : ''} PROMO CODE: ${newPromoCode.code}');
        promotionCode = newPromoCode;
      } catch (err) {
        appLogger.e(

            // appLogger.e(
            '[[ STRIPE API CREATE PROMO CODE ]] CREATE${testing ? ' TEST' : ''} PROMO-CODE $err');
      }
    }
    return promotionCode;
  }

  static Future<PromoCode?> checkForExistingPromoCode(
      {required StripeSecrets secrets,
      required bool testing,
      required Coupon coupon}) async {
    appLogger.d(
        '[[ STRIPE PAYMENT API CHECK FOR EXISTING PROMO CODE ]] ATTEMPTING TO FIND EXISTING${testing ? ' TEST' : ''} PROMO CODE');

    ///
    PromoCode? existingPromoCode;

    ///
    try {
      await getAllPromoCodes(secrets: secrets, testing: testing)
          .then((promoCodes) {
        if (promoCodes.isNotEmpty &&
            promoCodes.map((e) => e.coupon.id).contains(coupon.id)) {
          PromoCode retrievedPromoCode =
              promoCodes.firstWhere((c) => c.coupon.id == coupon.id);

          if (retrievedPromoCode.active &&
              (retrievedPromoCode.maxRedemptions == null ||
                  (retrievedPromoCode.maxRedemptions != null &&
                      retrievedPromoCode.timesRedeemed <
                          retrievedPromoCode.maxRedemptions))) {
            existingPromoCode = retrievedPromoCode;
          }
        }
      });
    } catch (e) {
      appLogger.e(
          '[[ STRIPE API CHECK FOR EXISTING PROMO CODE ]] ${testing ? 'TEST' : ''} EXISTING PROMO CODE RETRIEVAL $e');
    }

    ///
    return existingPromoCode;
  }

  static Future<List<PromoCode>> getAllPromoCodes({
    required StripeSecrets secrets,
    required bool testing,
  }) async {
    List<PromoCode> promoCodes = [];

    try {
      appLogger.d(
          '[[ STRIPE PAYMENT API PROMO CODES ]] ATTEMPTING TO RETRIEVE${testing ? ' TEST' : ''} PROMO CODES');

      //Make post request to Stripe
      var response = await http.get(
        Uri.parse('https://api.stripe.com/v1/promotion_codes'),
        headers: {
          'Authorization':
              'Bearer ${testing ? secrets.secretTestKey : secrets.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );
      appLogger.d(
          '[[ STRIPE PAYMENT API PROMO CODES ]]${testing ? ' TEST' : ''} RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        var stripePromoCodeList =
            StripePromoCodeList.fromJson(jsonDecode(response.body));
        promoCodes = stripePromoCodeList.data;
        appLogger.d(
            '[[ STRIPE PAYMENT API PROMO CODES ]]${testing ? ' TEST' : ''} PROMO CODES RETRIEVE: ${promoCodes.map((e) => e.id).join(",\n")}');
      } else {
        appLogger.d(
            '[[ STRIPE PAYMENT API PROMO CODES ]] RETRIEVE${testing ? ' TEST' : ''} PROMO CODES JSON DECODE ${response.statusCode}');
      }
    } catch (err) {
      appLogger.e(
          '[[ STRIPE PAYMENT API PROMO CODES ]] RETRIEVE${testing ? ' TEST' : ''} PROMO CODES RETRIEVAL $err');
      throw Exception(err.toString());
    }
    return promoCodes;
  }
}

class CouponAndPromoCode {
  Coupon? coupon;
  PromoCode? promoCode;

  CouponAndPromoCode({
    required this.coupon,
    required this.promoCode,
  });
}

class StripeError {
  String code;
  String docUrl;
  String message;
  String param;
  String requestLogUrl;
  String type;

  StripeError({
    required this.code,
    required this.docUrl,
    required this.message,
    required this.param,
    required this.requestLogUrl,
    required this.type,
  });

  factory StripeError.fromJson(Map<String, dynamic> json) => StripeError(
        code: json["code"],
        docUrl: json["doc_url"],
        message: json["message"],
        param: json["param"],
        requestLogUrl: json["request_log_url"],
        type: json["type"],
      );

  Map<String, dynamic> toJson() => {
        "code": code,
        "doc_url": docUrl,
        "message": message,
        "param": param,
        "request_log_url": requestLogUrl,
        "type": type,
      };
}

class GeneralPurchaserInfo {
  GeneralPurchaserInfo({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.description,
    required this.applicationUid,
  });

  final String fullName;
  final String email;
  final String? phone;
  final String? description;
  final String applicationUid;

  factory GeneralPurchaserInfo.fromJson(Map<String, dynamic> json) =>
      GeneralPurchaserInfo(
        fullName: json["name"],
        email: json["email"],
        phone: json["phone"],
        description: json["description"],
        applicationUid: json["uid"],
      );

  Map<String, dynamic> toJson() => {
        "name": fullName,
        "email": email,
        "phone": phone,
        "description": description,
        "uid": applicationUid,
      };

  @override
  toString() => [
        fullName,
        email,
        phone ?? "",
        description ?? "",
        applicationUid,
      ].join(purchaserInfoDelimiter);

  factory GeneralPurchaserInfo.fromString(String x) => GeneralPurchaserInfo(
        fullName: x.split(purchaserInfoDelimiter).isNotEmpty
            ? x.split(purchaserInfoDelimiter).first
            : "",
        email: x.split(purchaserInfoDelimiter).length > 1
            ? x.split(purchaserInfoDelimiter)[1]
            : "",
        phone: x.split(purchaserInfoDelimiter).length > 2
            ? x.split(purchaserInfoDelimiter)[2]
            : null,
        description: x.split(purchaserInfoDelimiter).length > 3
            ? x.split(purchaserInfoDelimiter)[3]
            : null,
        applicationUid: x.split(purchaserInfoDelimiter).length > 4
            ? x.split(purchaserInfoDelimiter)[4]
            : "",
      );
}

class GeneralProductInfo {
  String id;
  String title;
  String description;
  String? orderOptions;
  List<String> shipToRegions;
  List<String> imageUrls;
  double retailPrice;
  double? salePercentOff;
  double? memberPercentOff;
  double defaultHandlingPrice;
  double defaultShippingMultiplier;

  GeneralProductInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.orderOptions,
    required this.shipToRegions,
    required this.imageUrls,
    required this.retailPrice,
    required this.salePercentOff,
    required this.memberPercentOff,
    required this.defaultHandlingPrice,
    required this.defaultShippingMultiplier,
  });
}

enum ShipToRegions {
  unitedStates("US"),
  canada("CA"),
  mexico("MX");

  const ShipToRegions(this.value);
  final String value;
}

class PriceCalculations {
  double retailPrice;
  double? salePrice;
  double? memberPrice;
  double totalPercentOff;
  double shippingPrice;
  double subtotal;
  double totalForThisSale;

  PriceCalculations({
    required this.retailPrice,
    required this.salePrice,
    required this.memberPrice,
    required this.totalPercentOff,
    required this.shippingPrice,
    required this.subtotal,
    required this.totalForThisSale,
  });

  factory PriceCalculations.fromJson(Map<String, dynamic> json) =>
      PriceCalculations(
        retailPrice: json["retail_price"],
        salePrice: json["sale_price"],
        memberPrice: json["member_price"],
        totalPercentOff: json["total_percent"],
        shippingPrice: json["shipping_price"],
        subtotal: json["subtotal"],
        totalForThisSale: json["total_sale"],
      );

  Map<String, dynamic> toJson() => {
        "retail_price": retailPrice,
        "sale_price": salePrice,
        "member_price": memberPrice,
        "total_percent": totalPercentOff,
        "shipping_price": shippingPrice,
        "subtotal": subtotal,
        "total_sale": totalForThisSale,
      };

  List<String> toGSheetsList() => [
        retailPrice.toStringAsFixed(2),
        salePrice == null ? "" : salePrice!.toStringAsFixed(2),
        memberPrice == null ? "" : memberPrice!.toStringAsFixed(2),
        totalPercentOff.toStringAsFixed(2),
        shippingPrice.toStringAsFixed(2),
        subtotal.toStringAsFixed(2),
        totalForThisSale.toStringAsFixed(2),
      ];

  factory PriceCalculations.fromGSheetsList(List<String> thisOrder) =>
      PriceCalculations(
        retailPrice: double.parse(thisOrder[0]),
        salePrice: thisOrder[1].isEmpty ? null : double.parse(thisOrder[1]),
        memberPrice: thisOrder[2].isEmpty ? null : double.parse(thisOrder[2]),
        totalPercentOff: double.parse(thisOrder[3]),
        shippingPrice: double.parse(thisOrder[4]),
        subtotal: double.parse(thisOrder[5]),
        totalForThisSale: double.parse(
          thisOrder[6],
        ),
      );

  @override
  toString() => toGSheetsList().join(stripePriceCalculationsDelimiter);

  toDisplayString() =>
      "Retail Price: \$${retailPrice.toStringAsFixed(2)}  Discount: ${totalPercentOff.round()}%  Shipping: \$${shippingPrice.toStringAsFixed(2)}";
  // "Buy Price: \$${finalBuyPrice.toStringAsFixed(2)}  Discount: ${totalPercentOff.round()}%  Shipping: \$${shippingPrice.toStringAsFixed(2)}";

  factory PriceCalculations.fromString(String string) =>
      PriceCalculations.fromGSheetsList(
          string.split(stripePriceCalculationsDelimiter));

  static Future<PriceCalculations> calculatePrices({
    required bool isFirstPurchase,
    required bool memberLoggedIn,
    required double retailPrice,
    required double? salePercentOff,
    required double? memberPercentOff,
    required double defaultProductHandlingPrice,
    required double shippingPriceMultiplier,
  }) async {
    ///
    bool onSale = salePercentOff != null && salePercentOff > 0;
    // bool onSale = product.onSalePercent.value > 0;

    ///
    double? salePrice;
    double? memberPrice;
    // double finalBuyPrice = retailPrice;
    double totalPercentOff = 0;
    double shippingPrice =
        defaultProductHandlingPrice + (retailPrice * shippingPriceMultiplier);
    double subtotal = retailPrice - (retailPrice * (totalPercentOff / 100));
    // double subtotal = finalBuyPrice - (finalBuyPrice * (totalPercentOff / 100));
    double totalForThisSale;

    ///
    if (isFirstPurchase) {
      salePrice = retailPrice -
          (retailPrice * (stripeFirstPurchaseDiscountPercent / 100));

      totalPercentOff = totalPercentOff + stripeFirstPurchaseDiscountPercent;
      // finalBuyPrice = salePrice;
      subtotal = retailPrice - (retailPrice * (totalPercentOff / 100));
      // subtotal = finalBuyPrice - (finalBuyPrice * (totalPercentOff / 100));
    } else if (onSale) {
      totalPercentOff = totalPercentOff + salePercentOff;
      salePrice = retailPrice - (retailPrice * (totalPercentOff / 100));
      // finalBuyPrice = salePrice;
      subtotal = salePrice;

      // subtotal = finalBuyPrice - (finalBuyPrice * (totalPercentOff / 100));

      if (memberLoggedIn && memberPercentOff != null && memberPercentOff > 0) {
        memberPrice = salePrice - (salePrice * (memberPercentOff / 100));

        double additionalPercentOff =
            ((salePrice - memberPrice) / ((salePrice + memberPrice) / 2) * 100);

        totalPercentOff = totalPercentOff + additionalPercentOff;
        // finalBuyPrice = memberPrice;
        subtotal = retailPrice - (retailPrice * (totalPercentOff / 100));
        // subtotal = finalBuyPrice - (finalBuyPrice * (totalPercentOff / 100));
      }
    } else if (!onSale &&
        memberLoggedIn &&
        memberPercentOff != null &&
        memberPercentOff > 0) {
      totalPercentOff = memberPercentOff;
      memberPrice = retailPrice - ((retailPrice * memberPercentOff) / 100);

      // finalBuyPrice = memberPrice;
      subtotal = memberPrice;
      // subtotal = finalBuyPrice - (finalBuyPrice * (totalPercentOff / 100));
    }

    totalForThisSale = subtotal + shippingPrice;

    ///
    appLogger.w(
        // '[[ CALCULATE PRICES FUNCTION ]] RETAIL PRICE ==> \$$retailPrice\n[[ CALCULATE PRICES FUNCTION ]] IS FIRST PURCHASE? ==> $isFirstPurchase\n[[ CALCULATE PRICES FUNCTION ]] SALE PRICE ==> ${salePrice == null ? "Not on sale" : "\$$salePrice"}\n[[ CALCULATE PRICES FUNCTION ]] MEMBER PRICE ==> ${memberPrice == null ? "Not a member" : "\$$memberPrice"}\n[[ CALCULATE PRICES FUNCTION ]] FINAL BUY PRICE ==> \$$finalBuyPrice\n[[ CALCULATE PRICES FUNCTION ]] TOTAL %OFF ==> $totalPercentOff%\n[[ CALCULATE PRICES FUNCTION ]] SUBTOTAL ==> \$$subtotal\n[[ CALCULATE PRICES FUNCTION ]] SHIPPING PRICE ==> \$$shippingPrice\n[[ CALCULATE PRICES FUNCTION ]] TOTAL THIS SALE ==> \$$totalForThisSale');
        '[[ CALCULATE PRICES FUNCTION ]] RETAIL PRICE ==> \$$retailPrice\n[[ CALCULATE PRICES FUNCTION ]] IS FIRST PURCHASE? ==> $isFirstPurchase\n[[ CALCULATE PRICES FUNCTION ]] SALE PRICE ==> ${salePrice == null ? "Not on sale" : "\$$salePrice"}\n[[ CALCULATE PRICES FUNCTION ]] MEMBER PRICE ==> ${memberPrice == null ? "Not a member" : "\$$memberPrice"}\n[[ CALCULATE PRICES FUNCTION ]] TOTAL %OFF ==> $totalPercentOff%\n[[ CALCULATE PRICES FUNCTION ]] SUBTOTAL ==> \$$subtotal\n[[ CALCULATE PRICES FUNCTION ]] SHIPPING PRICE ==> \$$shippingPrice\n[[ CALCULATE PRICES FUNCTION ]] TOTAL THIS SALE ==> \$$totalForThisSale');

    var priceCalculations = PriceCalculations(
        retailPrice: retailPrice,
        salePrice: salePrice,
        memberPrice: memberPrice,
        totalPercentOff: totalPercentOff,
        shippingPrice: shippingPrice,
        // finalBuyPrice: finalBuyPrice,
        subtotal: subtotal,
        totalForThisSale: totalForThisSale);

    priceCalculationsNotifier.value = priceCalculations;

    return priceCalculations;
  }

  static Widget priceCalculationsCard({ShapeBorder? cardShape}) {
    return ValueListenableBuilder(
        valueListenable: priceCalculationsNotifier,
        builder: (context, priceCalculations, child) {
          var tertiaryColor = Theme.of(context).colorScheme.tertiary;

          ///
          return priceCalculations == null
              ? const SizedBox.shrink()
              : Flash(
                  child: Card(
                    shape: cardShape,
                    color: Theme.of(context).colorScheme.error,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Table(children: [
                        TableRow(children: [
                          Text(
                            'Price (Tax Included)'.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${currencyFormat(priceCalculations.retailPrice)}'
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ]),
                        TableRow(children: [
                          Text(
                            'Discount'.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${priceCalculations.totalPercentOff.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ]),
                        TableRow(children: [
                          Text(
                            'Subtotal'.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${currencyFormat(priceCalculations.subtotal)}'
                                .toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ]),
                        const TableRow(children: [Divider(), Divider()]),
                        TableRow(children: [
                          Text(
                            'Shipping & Handling'.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${currencyFormat(priceCalculations.shippingPrice)}'
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ]),
                        TableRow(children: [
                          Text(
                            'Order Total'.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: tertiaryColor,
                            ),
                          ),
                          Text(
                            '${currencyFormat(priceCalculations.totalForThisSale)}'
                                .toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: tertiaryColor,
                            ),
                          ),
                        ]),
                      ]),
                    ),
                  ),
                );
        });
  }
}
