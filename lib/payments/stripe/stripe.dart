// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_stripe/flutter_stripe.dart' as strp;
// import 'package:http/http.dart' as http;
// import 'package:url_launcher/url_launcher.dart';
// import '../../constants.dart';
// import 'stripe_models/checkout_sessions.dart';
// import 'stripe_models/coupon.dart';
// import 'stripe_models/customer.dart';
// import 'stripe_models/promo_code.dart';

// /// NOTIFIERS
// ValueNotifier<List<StripeCustomer>> stripeCustomerNotifier = ValueNotifier([]);
// ValueNotifier<bool> attemptingPurchaseNotifier = ValueNotifier(false);
// ValueNotifier<bool> purchaseSuccessfulNotifier = ValueNotifier(false);
// ValueNotifier<PriceCalculations?> priceCalculationsNotifier =
//     ValueNotifier(null);

// class StripeApi {
//   // static final publicKey = Env.stripePublicKey;
//   // static final publicTestKey = Env.stripePublicTestKey;
//   // static final privateKey = Env.stripeSecretKey;
//   // static final privateTestKey = Env.stripeSecretTestKey;
//   // static final accountId = Env.stripeAccountId;

//   ///
//   static Future<List<StripeCustomer>> stripePaymentInit({
//     required String userId,
//     required String publicApiKey,
//     required bool testing,
//   }) async {
//     List<StripeCustomer> existingStripeCustomers = [];
//     appLogger.d(
//         '[[ STRIPE PAYMENT API INIT ]] INITIALIZING WITH USER ID $userId ...');

//     // Set your publishable key: remember to change this to your live publishable key in production
//     // See your keys here: https://dashboard.stripe.com/apikeys

//     if (kIsWeb || Platform.isAndroid) {
//       ///
//       strp.Stripe.publishableKey = publicApiKey;
//       strp.Stripe.stripeAccountId = userId;

//       strp.Stripe.urlScheme = 'flutterstripe';
//       await strp.Stripe.instance.applySettings();

//       appLogger.f(
//           '[[ STRIPE PAYMENT API INIT ]]SEARCHING FOR STRIPE CUSTOMER FROM REMOTE SERVER');

//       await searchForExistingStripeCustomer(searchForTestCustomer: testing)
//           .then((customers) {
//         if (customers.isNotEmpty) {
//           existingStripeCustomers = customers;
//           stripeCustomerNotifier.value = customers;
//           appLogger.f(
//               '[[ STRIPE PAYMENT API INIT ]] ${customers.length} STRIPE CUSTOMERS FOUND FROM REMOTE SERVER! ${customers.map((e) => e.toJson().toString())}');
//         } else {
//           appLogger.e(
//               '[[ STRIPE PAYMENT API INIT ]] NO STRIPE CUSTOMER FOUND ON REMOTE SERVER!');
//         }
//       });

//       ///
//       appLogger.d('[[ STRIPE PAYMENT API INIT ]] INITIALIZATION COMPLETE.');
//     } else {
//       appLogger.e(
//           '[[ STRIPE PAYMENT API INIT ]] NO INITIALIZATION METHOD CURRENTLY IMPLEMENTED FOR ${Platform.operatingSystem.toUpperCase()}');
//     }
//     return existingStripeCustomers;
//   }

//   static Future<(bool, CheckoutSessionsDatum?, PriceCalculations?)>
//       processPayment({
//     required BuildContext context,
//     required GeneralProductInfo productInfo,
//     bool isTestTransaction = false,
//     bool createCustomerIfNone = true,
//     String defaultCurrency = "usd",
//   }) async {
//     // attemptingPurchaseNotifier.value = true;
//     // final testing = appTestingNotifier.value; //  && !liveProductOverride;
//     // bool isAdmin = userTypeNotifier.value.any((e) => e);
//     // var appUser = localDataNotifier.value.appUser;
//     bool paymentSuccessful = false;
//     CheckoutSessionsDatum? checkoutSession;
//     PriceCalculations? updatedPriceCalculations;

//     List<StripeCustomer?> stripeCustomer = await getStripeCustomer(
//       createLiveCustomer: !isTestTransaction,
//       createTestCustomer: isTestTransaction,
//       // purchaserInfo: purchaserInfo,
//       // shippingAddress: shippingAddress,
//     );

//     var liveStripeCustomer = stripeCustomer.first;
//     var testStripeCustomer = stripeCustomer[1];

//     if ((!isTestTransaction && liveStripeCustomer != null) ||
//         (isTestTransaction && testStripeCustomer != null)) {
//       try {
//         // if (kIsWeb || !Platform.isAndroid) {
//         appLogger.d(
//             '[[ STRIPE PAYMENT API PROCESS WEB PAYMENT ]] BEGINNING WEB${isTestTransaction ? ' TEST' : 'LIVE'} PAYMENT PROCESSING...');

//         String? fullPaymentLinkData;

//         if (isTestTransaction && testStripeCustomer != null) {
//           fullPaymentLinkData = await createStripePaymentLink(
//             // appUser: appUser,
//             customer: testStripeCustomer,
//             // purchaserInfo: purchaserInfo,
//             // shippingAddress: shippingAddress,
//             productInfo: productInfo,
//             // product: product,
//             // amount: amount,
//             // priceCalculations: priceCalculations,
//           );
//         } else if (!isTestTransaction && liveStripeCustomer != null) {
//           fullPaymentLinkData = await createStripePaymentLink(
//             // appUser: appUser,
//             customer: liveStripeCustomer,
//             // purchaserInfo: purchaserInfo,
//             // shippingAddress: shippingAddress,
//             productInfo: productInfo,
//             // product: product,
//             // amount: amount,
//             // priceCalculations: priceCalculations,
//           );
//         } else {
//           appLogger.e(
//               '[[ STRIPE PAYMENT API PROCESS WEB PAYMENT ]]${isTestTransaction ? ' TEST' : 'LIVE'} STRIPE CUSTOMER DATA RETURNED NULL.');
//         }

//         if (fullPaymentLinkData != null) {
//           final String paymentLinkId =
//               fullPaymentLinkData.split(standardDelimiter).first;
//           final String paymentLinkUrl =
//               fullPaymentLinkData.split(standardDelimiter)[1];

//           await canLaunchUrl(Uri.parse(paymentLinkUrl))
//               ? launchUrl(Uri.parse(paymentLinkUrl),
//                   mode: LaunchMode.platformDefault)
//               : context.mounted
//                   ? ScaffoldMessenger.maybeOf(context)?.showSnackBar(
//                       const SnackBar(
//                           content: Text("Could not lauch payment page")))
//                   : null;

//           if (context.mounted) {
//             await showDialog(
//                 context: context,
//                 // useSafeArea: false,
//                 barrierDismissible: false,
//                 barrierColor: Colors.transparent,
//                 builder: (context) => Dialog(
//                       elevation: 0,
//                       backgroundColor: Colors.transparent,
//                       child: Card(
//                         child: Padding(
//                           padding: const EdgeInsets.all(25),
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Text(
//                                 "Order In Process...\nClose this message once you complete your transaction.",
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     color: Theme.of(context)
//                                         .colorScheme
//                                         .onPrimary),
//                               ),
//                               const Padding(
//                                 padding: EdgeInsets.all(10),
//                                 child: CircularProgressIndicator(),
//                               ),
//                               ElevatedButton(
//                                   onPressed: () => Navigator.pop(context),
//                                   // icon: const Icon(FontAwesomeIcons.checkDouble),
//                                   child: const Text("Finish & Close")),
//                             ],
//                           ),
//                         ),
//                       ),
//                     )).then((_) async {
//               ///
//               appLogger.d(
//                   '[[ STRIPE PAYMENT API PROCESS WEB PAYMENT ]] VERIFYING WEB${isTestTransaction ? ' TEST' : ''} PAYMENT...');

//               ///
//               (
//                 bool,
//                 CheckoutSessionsDatum?,
//                 PriceCalculations?
//               ) purchaseVerified = await verifyStripePayment(
//                 customerId: isTestTransaction
//                     ? testStripeCustomer!.id
//                     : liveStripeCustomer!.id,
//                 // product: product,
//                 productInfo: productInfo,
//                 // stripeProductId: product.id,
//                 paymentLink: paymentLinkId,
//               );

//               if (purchaseVerified.$1 && purchaseVerified.$2 != null) {
//                 appLogger.d(
//                     '[[ STRIPE PAYMENT API PROCESS WEB PAYMENT ]] WEB${isTestTransaction ? ' TEST' : ''} PAYMENT VERIFIED SUCCESSFUL!');
//                 paymentSuccessful = purchaseVerified.$1;
//                 checkoutSession = purchaseVerified.$2;
//                 updatedPriceCalculations = purchaseVerified.$3;
//               } else {
//                 appLogger.d(
//                     '[[ STRIPE PAYMENT API PROCESS WEB PAYMENT ]] WEB${isTestTransaction ? ' TEST' : ''} PAYMENT NOT VERIFIED. UNSUCCESSFUL!');
//               }
//             });
//           }
//         } else {
//           appLogger.e(
//               '[[ STRIPE PAYMENT API PROCESS WEB PAYMENT ]] UNABLE TO CREATE PAYMENT LINK. LINK DATA RETURNED NULL.');
//         }
//         // }
//         // else if (Platform.isAndroid) {
//         //   // Get customer ephemeral key
//         //   CustomerTemporaryEphemeralKey? customerEphemeralKey =
//         //       await getCustomerPaymentEphemeralKey(
//         //           stripeCustomer:
//         //               testing ? testStripeCustomer! : liveStripeCustomer!);

//         //   //STEP 1: Create Payment Intent
//         //   appLogger.d(
//         //       '[[ STRIPE PAYMENT API PROCESS PAYMENT ]] ATTEMPTING TO CREATE${testing ? ' TEST' : ''} PAYMENT INTENT.');
//         //   Map<String, dynamic>? paymentIntent = await createPaymentIntent(
//         //     appUser: appUser,
//         //     stripeCustomer:
//         //         testing ? testStripeCustomer! : liveStripeCustomer!,
//         //     product: product,
//         //     amountPlusShippingAndHandling: priceCalculations != null
//         //         ? priceCalculations.totalForThisSale
//         //         : product.retailPrice + product.shippingAndHandling,
//         //     shippingAddress: shippingAddress,
//         //     currency: currency,
//         //   );

//         //   if (paymentIntent != null) {
//         //     //STEP 2: Initialize Payment Sheet
//         //     appLogger.d(
//         //         '[[ STRIPE PAYMENT API PROCESS PAYMENT ]] INITIALIZING${testing ? ' TEST' : ''} PAYMENT SHEET.');

//         //     // final strp.Address address = strp.Address(
//         //     //   city: shippingAddress.city,
//         //     //   country: shippingAddress.country,
//         //     //   line1: shippingAddress.line1,
//         //     //   line2: shippingAddress.line2,
//         //     //   postalCode: shippingAddress.postalCode,
//         //     //   state: shippingAddress.state,
//         //     // );

//         //     // paymentSheet =
//         //     await strp.Stripe.instance.initPaymentSheet(
//         //         paymentSheetParameters: strp.SetupPaymentSheetParameters(
//         //       // Set to true for custom flow
//         //       customFlow: false,
//         //       // Main params
//         //       merchantDisplayName: Application.name,
//         //       paymentIntentClientSecret:
//         //           paymentIntent['client_secret'], //Gotten from payment intent
//         //       // // Customer keys
//         //       customerEphemeralKeySecret: customerEphemeralKey.secret,
//         //       customerId: paymentIntent['customer'],
//         //       // Extra options
//         //       primaryButtonLabel: "${testing ? ' TEST' : ''} Pay Now",
//         //       // style: ThemeMode.dark,
//         //       style: ThemeMode.system,
//         //       // appearance: const strp.PaymentSheetAppearance(
//         //       //     colors: strp.PaymentSheetAppearanceColors()),
//         //       // billingDetailsCollectionConfiguration:
//         //       //     const strp.BillingDetailsCollectionConfiguration(
//         //       //   name: strp.CollectionMode.automatic,
//         //       //   address: strp.AddressCollectionMode.automatic,
//         //       // ),
//         //       // billingDetails: strp.BillingDetails(
//         //       //   name: shippingAddress.fullName,
//         //       //   email: shippingAddress.email,
//         //       //   phone: shippingAddress.phone,
//         //       //   address: address,
//         //       // ),
//         //       // billingDetailsCollectionConfiguration: BillingDetailsCollectionConfiguration()
//         //     ));

//         //     //STEP 3: Display Payment sheet
//         //     appLogger.d(
//         //         '[[ STRIPE PAYMENT API PROCESS PAYMENT ]] ATTEMPTING TO DISPLAY PAYMENT SHEET.');
//         //     paymentSuccessful = await displayPaymentSheet(
//         //         // liveProductOverride: liveProductOverride,
//         //         // context: context,
//         //         paymentIntentClientSecret: paymentIntent['client_secret']);
//         //   } else {
//         //     Functions.sendErrorNotification(
//         //         error:
//         //             '[[ STRIPE PAYMENT API PROCESS PAYMENT ]]${testing ? ' TEST' : ''} PROCESSING FLOW NOT YET IMPLEMENTED FOR ${Platform.operatingSystem.toUpperCase()} PAYMENT.');
//         //     // appLogger.d(
//         //     //     '[[ STRIPE PAYMENT API PROCESS PAYMENT ]]${testing ? ' TEST' : ''} PROCESSING FLOW NOT YET IMPLEMENTED FOR ${Platform.operatingSystem.toUpperCase()} PAYMENT.');
//         //   }
//         // }
//       } catch (err) {
//         appLogger.e(
//             '[[ STRIPE PAYMENT API PROCESS PAYMENT ]]${isTestTransaction ? ' TEST' : ''} PAYMENT PROCESSING ERROR: $err');
//       }
//     } else {
//       appLogger.e(
//           '[[ STRIPE PAYMENT API PAYMENT SHEET ]] UNABLE TO RETRIVE STRIPE CUSTOMER. STRIPE CUSTOMER RETURNED NULL.');
//     }

//     return (paymentSuccessful, checkoutSession, updatedPriceCalculations);
//   }

//   // static Future<Map<String, dynamic>?> createPaymentIntent({
//   //   required AppUser appUser,
//   //   required StripeCustomer stripeCustomer,
//   //   required SGAProduct product,
//   //   required double amountPlusShippingAndHandling,
//   //   required CustomerAddress shippingAddress,
//   //   // required bool liveProductOverride,
//   //   String? currency,
//   // }) async {
//   //   final testing = appTestingNotifier.value; //  && !liveProductOverride;
//   //   try {
//   //     appLogger.d(
//   //         '[[ STRIPE PAYMENT API PAYMENT INTENT ]] ATTEMPTING TO CREATE${testing ? ' TEST' : ''} PAYMENT INTENT');

//   //     //Request body
//   //     Map<String, dynamic> body = {
//   //       'amount': (amountPlusShippingAndHandling * 100).toInt().toString(),
//   //       'currency': currency ?? 'USD',
//   //       'customer': stripeCustomer.id,
//   //       "receipt_email": shippingAddress.email,
//   //       "description": product.title,
//   //       "shipping[name]": shippingAddress.fullName,
//   //       "shipping[phone]": shippingAddress.phone,
//   //       "shipping[address][line1]": shippingAddress.line1,
//   //       "shipping[address][line2]": shippingAddress.line2,
//   //       "shipping[address][city]": shippingAddress.city,
//   //       "shipping[address][state]": shippingAddress.state,
//   //       "shipping[address][postal_code]": shippingAddress.postalCode,
//   //       "shipping[address][country]": shippingAddress.country,
//   //     };

//   //     //Make post request to Stripe
//   //     var response = await http.post(
//   //       Uri.parse('https://api.stripe.com/v1/payment_intents'),
//   //       headers: {
//   //         'Authorization': 'Bearer ${testing ? privateTestKey : privateKey}',
//   //         'Content-Type': 'application/x-www-form-urlencoded'
//   //       },
//   //       body: body,
//   //     );
//   //     appLogger.d(
//   //         '[[ STRIPE PAYMENT API PAYMENT INTENT ]]${testing ? ' TEST' : ''} RESPONSE: ${response.body}');
//   //     return json.decode(response.body);
//   //   } catch (err) {
//   //     appLogger.d(
//   //         '[[ STRIPE PAYMENT API PAYMENT INTENT ]] CREATE ${testing ? ' TEST' : ''}PAYMENT INTENT ERROR: $err');
//   //     throw Exception(err.toString());
//   //   }
//   // }

//   // static Future<bool> displayPaymentSheet({
//   //   // required BuildContext context,
//   //   // required bool liveProductOverride,
//   //   required String paymentIntentClientSecret,
//   // }) async {
//   //   final testing = appTestingNotifier.value; //  && !liveProductOverride;
//   //   bool paymentSuccessful = false;
//   //   try {
//   //     appLogger.d(
//   //         '[[ STRIPE PAYMENT API DISPLAY PAYMENT SHEET ]] ATTEMPTING TO DISPLAY${testing ? ' TEST' : ''} PAYMENT SHEET');
//   //     await strp.Stripe.instance
//   //         .presentPaymentSheet(
//   //             options: const strp.PaymentSheetPresentOptions(timeout: 1200000))
//   //         .then((_) async {
//   //       appLogger.d(
//   //           '[[ STRIPE PAYMENT API DISPLAY PAYMENT SHEET ]]${testing ? ' TEST' : ''} PAYMENT SUCCESSFUL');
//   //       paymentSuccessful = true;

//   //       // await Stripe.instance
//   //       //     .confirmPayment(
//   //       //         paymentIntentClientSecret: paymentIntentClientSecret)
//   //       //     .then((paymentConfirmation) {
//   //       //   appLogger.d(
//   //       //       '[[ STRIPE PAYMENT API DISPLAY PAYMENT SHEET ]]${testing ? ' TEST' : ''} PAYMENT INTENT CONFIRMATION: ${paymentConfirmation.toJson()}');
//   //       //   if (paymentConfirmation.status.name == "successful") {
//   //       //     appLogger.d(
//   //       //         '[[ STRIPE PAYMENT API DISPLAY PAYMENT SHEET ]]${testing ? ' TEST' : ''} PAYMENT SUCCESSFUL WITH STATUS ${paymentConfirmation.status.name}');
//   //       //     paymentSuccessful = true;
//   //       //   } else {
//   //       //     appLogger.d(
//   //       //         '[[ STRIPE PAYMENT API DISPLAY PAYMENT SHEET ]]${testing ? ' TEST' : ''} PAYMENT UNSUCCESSFUL WITH STATUS ${paymentConfirmation.status.name}');
//   //       //     paymentSuccessful = false;
//   //       //   }
//   //       // });

//   //       // /// CONFIRM PAYMENT
//   //       // appLogger.d(
//   //       //     '[[ STRIPE PAYMENT API DISPLAY PAYMENT SHEET ]] CONFIRMING${testing ? ' TEST' : ''} PAYMENT HERE...');
//   //       // await Stripe.instance.confirmPaymentSheetPayment();
//   //       // appLogger.d(
//   //       //     '[[ STRIPE PAYMENT API DISPLAY PAYMENT SHEET ]] AFTER${testing ? ' TEST' : ''} CONFIRMATION HERE...');

//   //       // // Clear paymentIntent variable after successful payment
//   //       // setState(() => paymentIntent = null);
//   //     }).onError((error, stackTrace) {
//   //       appLogger.d(
//   //           '[[ STRIPE PAYMENT API DISPLAY PAYMENT SHEET ]]${testing ? ' TEST' : ''} PAYMENT SHEET INSTANCE ERROR: $error.');
//   //       paymentSuccessful = false;
//   //       // Functions.popMessage(
//   //       //     context,
//   //       //     '${testing ? ' TEST' : ''} PAYMENT SHEET INSTANCE ERROR: $error.',
//   //       //     true);
//   //       // throw Exception(error);
//   //     });
//   //   } on strp.StripeException catch (e) {
//   //     Functions.sendErrorNotification(
//   //         error:
//   //             // appLogger.d(
//   //             '[[ STRIPE PAYMENT API DISPLAY PAYMENT SHEET ]] STRIPE${testing ? ' TEST' : ''} EXCEPTION ERROR: $e');
//   //     paymentSuccessful = false;
//   //     const AlertDialog(
//   //       content: Column(
//   //         mainAxisSize: MainAxisSize.min,
//   //         children: [
//   //           Row(
//   //             children: [
//   //               Icon(
//   //                 Icons.cancel,
//   //                 color: Colors.red,
//   //               ),
//   //               Text("Payment Failed"),
//   //             ],
//   //           ),
//   //         ],
//   //       ),
//   //     );
//   //   } catch (e) {
//   //     Functions.sendErrorNotification(
//   //         error:
//   //             // appLogger.d(
//   //             '[[ STRIPE PAYMENT API DISPLAY PAYMENT SHEET ]] STRIPE${testing ? ' TEST' : ''} EXCEPTION ERROR: $e');
//   //     paymentSuccessful = false;
//   //     // Functions.popMessage(
//   //     //     context, 'STRIPE${testing ? ' TEST' : ''} EXCEPTION ERROR: $e', true);
//   //   }

//   //   return paymentSuccessful;
//   // }

//   static Future<List<StripeCustomer>> searchForExistingStripeCustomer({
//     required bool searchForTestCustomer,
//     // int? createdAfterDate, // created > createdAfterDate
//     String? name, // John Doe
//     String? email, // name@email.com
//     String? phone, // +19999999999
//     Map<String, String>? metadataKeyAndValue, //
//   }) async {
//     List<StripeCustomer> existingStripeCustomers = [];
//     // StripeCustomer? stripeCustomer = stripeCustomerNotifier.value;
//     String? queryUrl;

//     ///
//     queryUrl = email != null
//         ? "https://api.stripe.com/v1/customers/search?query=email:'$email'"
//         : name != null
//             ? "https://api.stripe.com/v1/customers/search?query=name:'$name'"
//             : phone != null
//                 ? "https://api.stripe.com/v1/customers/search?query=phone:'$phone'"
//                 // : createdAfterDate != null
//                 //     ? "https://api.stripe.com/v1/customers/search?query=created:'$createdAfterDate'"
//                 : metadataKeyAndValue != null &&
//                         metadataKeyAndValue.entries.first.key.isNotEmpty &&
//                         metadataKeyAndValue.entries.first.value.isNotEmpty
//                     ? "https://api.stripe.com/v1/customers/search?query=metadata['${metadataKeyAndValue.entries.first.key}']:'${metadataKeyAndValue.entries.first.value}'"
//                     : null;

//     if (queryUrl != null) {
//       try {
//         ///
//         appLogger.f(
//             '[STRIPE API STRIPE CUSTOMER SEARCH] SEARCHING FOR ${searchForTestCustomer ? 'TEST' : ''} STRIPE CUSTOMER WITH QUERY => $queryUrl');

//         final customerSearchResponse = await http.get(
//           Uri.parse(queryUrl),
//           headers: {
//             'Authorization':
//                 'Bearer ${searchForTestCustomer ? privateTestKey : privateKey}',
//             'Content-Type': 'application/x-www-form-urlencoded'
//           },
//           // body: body,
//         );

//         appLogger.d(
//             '[STRIPE API STRIPE CUSTOMER SEARCH] ${searchForTestCustomer ? 'TEST' : ''} STRIPE CUSTOMER SEARCH RESPONSE: ${customerSearchResponse.body}');

//         if (customerSearchResponse.statusCode == 200) {
//           var responseJson = jsonDecode(customerSearchResponse.body);
//           final stripeCustomerList = List<StripeCustomer>.from(
//               responseJson['data'].map((x) => StripeCustomer.fromJson(x)));

//           ///
//           appLogger.d(
//               '[STRIPE API STRIPE CUSTOMER SEARCH] ${searchForTestCustomer ? 'TEST' : ''} STRIPE CUSTOMER SEARCH DATA : [${stripeCustomerList.length}] Items --> ${stripeCustomerList.map((e) => e.toJson().toString())}');

//           existingStripeCustomers = stripeCustomerList;
//         }
//       } catch (e) {
//         appLogger.e(
//             '[[ STRIPE API STRIPE CUSTOMER SEARCH ]] ${searchForTestCustomer ? 'TEST' : ''} STRIPE CUSTOMER SEARCH ERROR: $e');
//       }
//     } else {
//       appLogger.e(
//           '[[ STRIPE API STRIPE CUSTOMER SEARCH ]] ${searchForTestCustomer ? 'TEST' : ''} NO QUERY PARAMETERS GIVEN FOR STRIPE CUSTOMER SEARCH');
//     }

//     ///
//     return existingStripeCustomers;
//   }

//   static Future<List<StripeCustomer?>> getStripeCustomer({
//     required bool createLiveCustomer,
//     required bool createTestCustomer,
//     // PurchaserInfo? purchaserInfo,
//     // CustomerAddress? shippingAddress,
//   }) async {
//     ///
//     // final testing = appTestingNotifier.value; //  && !liveProductOverride;
//     // var appUser = localDataNotifier.value.appUser;
//     // PackageInfo packageInfo = await Functions.getPackageInfo();
//     // String deviceInfo = await Functions.getDeviceInfo();
//     ///
//     StripeCustomer? stripeLiveCustomer;
//     StripeCustomer? stripeTestCustomer;

//     if (appUser != null) {
//       var stripeLiveCustomerId = appUser.stripeCustomerIds.isNotEmpty
//           ? appUser.stripeCustomerIds.first
//           : null;
//       var stripeTestCustomerId = appUser.stripeCustomerIds.length > 1
//           ? appUser.stripeCustomerIds[1]
//           : null;
//       // if (stripeCustomerId != null) {
//       if ((!testing && stripeLiveCustomerId != null && !createLiveCustomer)) {
//         // if (stripeCustomerId != null && !createNewCustomer) {
//         try {
//           appLogger.d(
//               '[[ STRIPE PAYMENT API GET CUSTOMER ]] ATTEMPTING TO RETRIEVE LIVE CUSTOMER');

//           /// GET LIVE STRIPE CUSTOMER
//           var liveCustomerResponse = await http.post(
//             Uri.parse(
//                 'https://api.stripe.com/v1/customers/$stripeLiveCustomerId'),
//             headers: {
//               'Authorization': 'Bearer $privateKey',
//               'Content-Type': 'application/x-www-form-urlencoded'
//             },
//             // body: body,
//           );
//           appLogger.d(
//               '[[ STRIPE PAYMENT API GET CUSTOMER ]] LIVE CUSTOMER RETRIEVE RESPONSE: ${liveCustomerResponse.body}');

//           if (liveCustomerResponse.body
//               .toLowerCase()
//               .contains("no such customer")) {
//             appLogger.f(
//                 '[[ STRIPE PAYMENT API GET CUSTOMER ]] LIVE CUSTOMER NOT FOUND. ATTEMPTING TO CREATE NEW...');
//             await getStripeCustomer(
//               createLiveCustomer: true,
//               createTestCustomer: false,
//               // purchaserInfo: purchaserInfo,
//               // shippingAddress: shippingAddress,
//             ).then((value) => stripeLiveCustomer = value.first);
//           } else {
//             appLogger.f(
//                 '[[ STRIPE PAYMENT API GET CUSTOMER ]] LIVE CUSTOMER FOUND AND RETRIEVED!');
//             var retrievedLiveCustomer =
//                 stripeCustomerFromJson(liveCustomerResponse.body);
//             stripeLiveCustomer = retrievedLiveCustomer;
//           }

//           // ///! UPDATE STRIPE CUSTOMER DATA IN LOCAL DATABASE
//           // appUser.updateStripeCustomerIds(
//           //   liveStripeCustomerId: stripeLiveCustomer?.id ?? "",
//           //   testStripeCustomerId: stripeTestCustomerId ?? "",
//           // );
//         } catch (e) {
//           appLogger.e(
//               // appLogger.d(
//               '[[ STRIPE PAYMENT API GET CUSTOMER ]] RETRIEVE CUSTOMER ERROR: $e\n==> ATTEMPTING TO CREATE NEW LIVE CUSTOMER...');

//           // // StripeCustomerError error =
//           // //     StripeCustomerError.fromJson(jsonDecode(e.toString()));

//           // // if (error.message.contains("No such customer")) {
//           // await getStripeCustomer(
//           //     // liveProductOverride: !liveProductOverride,
//           //     stripeCustomerId: stripeCustomerId,
//           //     createNewCustomer: true,
//           //     shippingAddress: shippingAddress);
//           // // }
//         }
//       } else if (testing &&
//           stripeTestCustomerId != null &&
//           !createTestCustomer) {
//         try {
//           appLogger.d(
//               '[[ STRIPE PAYMENT API GET CUSTOMER ]] ATTEMPTING TO RETRIEVE TEST CUSTOMER');

//           /// GET TEST STRIPE CUSTOMER
//           var testCustomerResponse = await http.post(
//             Uri.parse(
//                 'https://api.stripe.com/v1/customers/$stripeTestCustomerId'),
//             headers: {
//               'Authorization': 'Bearer $privateTestKey',
//               'Content-Type': 'application/x-www-form-urlencoded'
//             },
//             // body: body,
//           );
//           appLogger.d(
//               '[[ STRIPE PAYMENT API GET CUSTOMER ]] TEST CUSTOMER RETRIEVE RESPONSE: ${testCustomerResponse.body}');

//           if (testCustomerResponse.body
//               .toLowerCase()
//               .contains("no such customer")) {
//             appLogger.f(
//                 '[[ STRIPE PAYMENT API GET CUSTOMER ]] TEST CUSTOMER NOT FOUND. ATTEMPTING TO CREATE NEW...');
//             await getStripeCustomer(
//               createLiveCustomer: false,
//               createTestCustomer: true,
//               purchaserInfo: purchaserInfo,
//               // shippingAddress: shippingAddress,
//             ).then((value) => stripeTestCustomer = value[1]);
//           } else {
//             appLogger.f(
//                 '[[ STRIPE PAYMENT API GET CUSTOMER ]] TEST CUSTOMER FOUND AND RETRIEVED!');
//             var retrievedTestCustomer =
//                 stripeCustomerFromJson(testCustomerResponse.body);
//             stripeTestCustomer = retrievedTestCustomer;
//           }

//           ///! UPDATE STRIPE CUSTOMER DATA IN LOCAL DATABASE
//           appUser.updateStripeCustomerIds(
//             liveStripeCustomerId: stripeLiveCustomerId ?? "",
//             testStripeCustomerId: stripeTestCustomer?.id ?? "",
//           );
//         } catch (e) {
//           Functions.sendErrorNotification(
//               error:
//                   '[[ STRIPE PAYMENT API GET CUSTOMER ]] RETRIEVE CUSTOMER ERROR: $e\n==> ATTEMPTING TO CREATE TEST CUSTOMER...');
//         }
//       } else {
//         // List<StripeCustomer?> stripeCustomerInfo = await createStripeCustomer();
//         try {
//           //Request body
//           Map<String, String> body = {
//             "name": purchaserInfo == null || purchaserInfo.fullName.isEmpty
//                 ? appUser.appUserId
//                 : purchaserInfo.fullName,
//             "email": purchaserInfo == null || purchaserInfo.email.isEmpty
//                 ? appUser.contactEmails.first
//                 : purchaserInfo.email,

//             // "name": shippingAddress == null || shippingAddress.fullName.isEmpty
//             //     ? appUser.appUserId
//             //     : shippingAddress.fullName,
//             // "email": shippingAddress == null || shippingAddress.email.isEmpty
//             //     ? appUser.contactEmails.first
//             //     : shippingAddress.email,
//             // "phone": shippingAddress == null || shippingAddress.phone.isEmpty
//             //     ? appUser.phone
//             //     : shippingAddress.phone,
//             "description": appUser.appUserDescription,
//             // "metadata[country]": deviceInfo,
//             "metadata[application]": packageInfo.appName,
//             "metadata[app_user_id]": appUser.appUserId,
//             "metadata[app_version]":
//                 "${packageInfo.version} : ${packageInfo.buildNumber}",
//             "metadata[installer_store]": "${packageInfo.installerStore}",
//             "metadata[total_credits]": "${appUser.appCredits}",
//           };

//           /// CREATE LIVE STRIPE CUSTOMER
//           if (!testing || createLiveCustomer) {
//             appLogger.d(
//                 '[[ STRIPE PAYMENT API GET CUSTOMER ]] ATTEMPTING TO CREATE LIVE CUSTOMER');

//             var liveCreateCustomerResponse = await http.post(
//               Uri.parse('https://api.stripe.com/v1/customers'),
//               headers: {
//                 'Authorization': 'Bearer $privateKey',
//                 'Content-Type': 'application/x-www-form-urlencoded'
//               },
//               body: body,
//             );
//             appLogger.d(
//                 '[[ STRIPE PAYMENT API GET CUSTOMER ]] CREATE LIVE STRIPE CUSTOMER RESPONSE: ${liveCreateCustomerResponse.body}');
//             var newLiveCustomer =
//                 stripeCustomerFromJson(liveCreateCustomerResponse.body);
//             stripeLiveCustomer = newLiveCustomer;
//           }

//           /// CREATE TEST STRIPE CUSTOMER
//           if (testing || createTestCustomer) {
//             appLogger.d(
//                 '[[ STRIPE PAYMENT API GET CUSTOMER ]] ATTEMPTING TO CREATE TEST CUSTOMER');

//             var testCreateCustomerResponse = await http.post(
//               Uri.parse('https://api.stripe.com/v1/customers'),
//               headers: {
//                 'Authorization': 'Bearer $privateTestKey',
//                 'Content-Type': 'application/x-www-form-urlencoded'
//               },
//               body: body,
//             );
//             appLogger.d(
//                 '[[ STRIPE PAYMENT API GET CUSTOMER ]] CREATE TEST STRIPE CUSTOMER RESPONSE: ${testCreateCustomerResponse.body}');
//             var newTestCustomer =
//                 stripeCustomerFromJson(testCreateCustomerResponse.body);
//             stripeTestCustomer = newTestCustomer;
//           }

//           ///! UPDATE STRIPE CUSTOMER DATA IN LOCAL DATABASE
//           appUser.updateStripeCustomerIds(
//             liveStripeCustomerId:
//                 stripeLiveCustomer == null ? "" : stripeLiveCustomer.id,
//             testStripeCustomerId:
//                 stripeTestCustomer == null ? "" : stripeTestCustomer.id,
//           );
//         } catch (err) {
//           Functions.sendErrorNotification(
//               error:
//                   // appLogger.d(
//                   '[[ STRIPE PAYMENT API GET CUSTOMER ]] GET CUSTOMER ERROR: $err');
//         }
//       }
//     } else {
//       appLogger.d(
//           '[[ STRIPE PAYMENT API GET CUSTOMER ]] GET CUSTOMER ERROR: LOCAL APP USER INFO NOT FOUND');
//     }
//     return [stripeLiveCustomer, stripeTestCustomer];
//   }

//   // static Future<CustomerTemporaryEphemeralKey> getCustomerPaymentEphemeralKey({
//   //   // required bool liveProductOverride,
//   //   required StripeCustomer stripeCustomer,
//   // }) async {
//   //   final testing = appTestingNotifier.value; //  && !liveProductOverride;
//   //   CustomerTemporaryEphemeralKey ephemeralKey;
//   //   //! RETRIEVE EPHEMERAL KEY HERE...
//   //   try {
//   //     appLogger.d(
//   //         '[[ STRIPE PAYMENT API EPHEMERAL KEY ]] ATTEMPTING TO CREATE${testing ? ' TEST' : ''} EPHEMERAL KEY');

//   //     //Request body
//   //     Map<String, dynamic> body = {
//   //       'customer': stripeCustomer.id,
//   //     };

//   //     //Make post request to Stripe
//   //     var response = await http.post(
//   //       Uri.parse('https://api.stripe.com/v1/ephemeral_keys'),
//   //       headers: {
//   //         'Authorization': 'Bearer ${testing ? privateTestKey : privateKey}',
//   //         'Content-Type': 'application/x-www-form-urlencoded',
//   //         'Stripe-Version': '2022-11-15',
//   //       },
//   //       body: body,
//   //     );
//   //     appLogger.d(
//   //         '[[ STRIPE PAYMENT API EPHEMERAL KEY ]]${testing ? ' TEST' : ''} RESPONSE: ${response.body}');
//   //     ephemeralKey =
//   //         CustomerTemporaryEphemeralKey.fromJson(jsonDecode(response.body));
//   //     // return json.decode(response.body);
//   //   } catch (err) {
//   //     Functions.sendErrorNotification(
//   //         error:
//   //             // appLogger.d(
//   //             '[[ STRIPE PAYMENT API EPHEMERAL KEY ]] CREATE${testing ? ' TEST' : ''} EPHEMERAL KEY ERROR: $err');
//   //     throw Exception(err.toString());
//   //   }
//   //   return ephemeralKey;
//   // }

//   static Future<StripeProduct?> getExistingStripeProduct({
//     required String productId,
//   }) async {
//     final testing = appTestingNotifier.value;
//     StripeProduct? existingProduct;

//     try {
//       appLogger.d(
//           '[[ STRIPE API GET PRODUCT ]] ATTEMPTING TO GET${testing ? ' TEST' : ''} PRODUCT');

//       var productResponse = await http.post(
//         Uri.parse('https://api.stripe.com/v1/products/$productId'),
//         headers: {
//           'Authorization': 'Bearer ${testing ? privateTestKey : privateKey}',
//           'Content-Type': 'application/x-www-form-urlencoded'
//         },
//         // body: body,
//       );
//       appLogger.d(
//           '[[ STRIPE API GET PRODUCT ]] GET${testing ? ' TEST' : ''} PRODUCT RESPONSE: ${productResponse.body}');

//       if (productResponse.statusCode == 200) {
//         var retrievedProduct = stripeProductFromJson(productResponse.body);
//         existingProduct = retrievedProduct;
//       } else {
//         appLogger.e(
//             '[[ STRIPE API GET PRODUCT ]] GET${testing ? ' TEST' : ''} PRODUCT RESPONSE ERROR STATUS CODE: ${productResponse.statusCode}');
//       }
//     } catch (err) {
//       Functions.sendErrorNotification(
//           error:
//               // appLogger.d(
//               '[[ STRIPE API GET PRODUCT ]] GET${testing ? ' TEST' : ''} PRODUCT ERROR: $err');
//     }
//     return existingProduct;
//   }

//   static Future<List<StripeProduct?>> createStripeProduct({
//     // required SGAProduct product,
//     bool isTestProduct = false,
//     required GeneralProductInfo productInfo,
//     PriceCalculations? priceCalculations,
//     // bool createLiveProduct = true,
//     // bool createTestProduct = true,
//   }) async {
//     // final testing = appTestingNotifier.value || isTestProduct;
//     StripeProduct? stripeLiveProduct;
//     StripeProduct? stripeTestProduct;
//     try {
//       appLogger
//           .d('[[ STRIPE API CREATE PRODUCT ]] ATTEMPTING TO CREATE PRODUCT');

//       //Request body
//       Map<String, dynamic> body = {
//         "id": productInfo.id,
//         // "id": product.id,
//         "name": productInfo.title,
//         // "name": product.title,
//         "description": productInfo.description,
//         // "features": product.otherAttributes,
//         "default_price_data[currency]": "usd",
//         "default_price_data[unit_amount_decimal]": priceCalculations == null
//             ? "${(productInfo.retailPrice * 100).truncate()}"
//             : "${(priceCalculations.finalBuyPrice * 100).truncate()}",
//         // "${(product.retailPrice * 100).truncate()}",
//         "shippable": "true",
//         "unit_label": "pc",
//         "statement_descriptor": "SCAPEGOATS",
//         "images[0]": productInfo.imageUrls.first,
//         // "metadata[cost_string]": "${(product.cost * 100).toInt()}",
//         // "metadata[retail_price_string]":
//         //     "${(product.retailPrice * 100).toInt()}",
//       };

//       /// CREATE LIVE STRIPE PRODUCT
//       if (!isTestProduct) {
//         // if (createLiveProduct) {
//         var liveResponse = await http.post(
//           Uri.parse('https://api.stripe.com/v1/products'),
//           headers: {
//             'Authorization': 'Bearer $privateKey',
//             'Content-Type': 'application/x-www-form-urlencoded'
//           },
//           body: body,
//         );
//         appLogger.d(
//             '[[ STRIPE API CREATE PRODUCT ]] CREATE LIVE PRODUCT RESPONSE: ${liveResponse.body}');
//         var newLiveProduct = stripeProductFromJson(liveResponse.body);
//         stripeLiveProduct = newLiveProduct;
//       }

//       /// CREATE TEST STRIPE PRODUCT
//       if (isTestProduct) {
//         // if (createTestProduct) {
//         var testResponse = await http.post(
//           Uri.parse('https://api.stripe.com/v1/products'),
//           headers: {
//             'Authorization': 'Bearer $privateTestKey',
//             'Content-Type': 'application/x-www-form-urlencoded'
//           },
//           body: body,
//         );
//         appLogger.d(
//             '[[ STRIPE API CREATE PRODUCT ]] CREATE TEST PRODUCT RESPONSE: ${testResponse.body}');
//         var newTestProduct = stripeProductFromJson(testResponse.body);
//         stripeTestProduct = newTestProduct;
//       }

//       // ///
//       // product.updateStripeProductIds(
//       //     newProducts: [stripeLiveProduct, stripeTestProduct]);
//     } catch (err) {
//       Functions.sendErrorNotification(
//           error:
//               // appLogger.d(
//               '[[ STRIPE API CREATE PRODUCT ]] CREATE PRODUCT ERROR: $err');
//     }
//     return [stripeLiveProduct, stripeTestProduct];
//   }

//   static Future<StripePrice?> getSpecificStripePrice({
//     required String priceId,
//   }) async {
//     final testing = appTestingNotifier.value;
//     StripePrice? price;
//     try {
//       appLogger.d(
//           '[[ STRIPE API RETRIEVE PRICE ]] ATTEMPTING TO RETRIEVE${testing ? ' TEST' : ''} PRICE');

//       //Make post request to Stripe
//       var priceResponse = await http.post(
//         Uri.parse('https://api.stripe.com/v1/prices/$priceId'),
//         headers: {
//           'Authorization': 'Bearer ${testing ? privateTestKey : privateKey}',
//           'Content-Type': 'application/x-www-form-urlencoded'
//         },
//       );

//       ///
//       appLogger.i(
//           '[[ STRIPE API RETRIEVE PRICE ]]${testing ? ' TEST' : ''} RESPONSE: ${priceResponse.body}');
//       var newPrice = StripePrice.fromJson(jsonDecode(priceResponse.body));
//       price = newPrice;
//     } catch (err) {
//       Functions.sendErrorNotification(
//           error:
//               // appLogger.e(
//               '[[ STRIPE API RETRIEVE PRICE ]] CREATE${testing ? ' TEST' : ''} PRICE ERROR: $err');
//     }
//     return price;
//   }

//   static Future<StripePrice?> getStripePrice({
//     // required bool liveProductOverride,

//     // required SGAProduct product,
//     required GeneralProductInfo productInfo,
//     // bool priceAdjusted = false,
//     // required PriceCalculations priceCalculations,
//     // bool createTestProduct = true,
//     // required String productIdTag,
//   }) async {
//     // var appUser = localDataNotifier.value.appUser;
//     final testing = appTestingNotifier.value; //  && !liveProductOverride;
//     StripePrice? price;
//     PriceCalculations? priceCalculations = priceCalculationsNotifier.value;
//     // Map<String, dynamic>? responseError;

//     try {
//       /// Check for existing price
//       await searchForExistingStripePrice(
//         // product: product,
//         productInfo: productInfo,
//         priceToCheck: priceCalculations!.finalBuyPrice,
//       )
//           // product: product, priceToCheck: priceCalculations!.finalBuyPrice)
//           .then((value) {
//         if (value != null) {
//           price = value;
//         }
//       });
//     } catch (e) {
//       appLogger
//           .d('[[ STRIPE API CREATE PRICE ]] SEARCH FOR STRIPE PRICE ERROR: $e');
//     }

//     if (price == null) {
//       try {
//         appLogger.d(
//             '[[ STRIPE API CREATE PRICE ]] ATTEMPTING TO CREATE${testing ? ' TEST' : ''} PRICE');

//         // if (priceAdjusted) {
//         appLogger.d(
//             '[[ STRIPE API CREATE PRICE ]] FINAL BUY PRICE USED =>${priceCalculations!.finalBuyPrice}');
//         // }

//         // appLogger.d(
//         //     '[[ STRIPE API CREATE PRICE ]] FINAL BUY PRICE USED =>${priceCalculations.finalBuyPrice}');

//         //Request body
//         Map<String, String> priceBody = {
//           "product": productInfo.id,
//           "unit_amount":
//               // priceAdjusted && priceCalculations != null
//               // ?
//               (priceCalculations.finalBuyPrice * 100).toStringAsFixed(0)
//           // : (product.retailPrice * 100).toStringAsFixed(0)
//           ,
//           "currency": "usd",
//         };

//         //Make post request to Stripe
//         var priceResponse = await http.post(
//           Uri.parse('https://api.stripe.com/v1/prices'),
//           headers: {
//             'Authorization': 'Bearer ${testing ? privateTestKey : privateKey}',
//             'Content-Type': 'application/x-www-form-urlencoded'
//           },
//           body: priceBody,
//         );

//         ///
//         appLogger.i(
//             '[[ STRIPE API CREATE PRICE ]]${testing ? ' TEST' : ''} RESPONSE: ${priceResponse.body}');

//         if (priceResponse.body.contains("No such product")) {
//           appLogger.i(
//               '[[ STRIPE API CREATE PRICE ]] THE PROVIDED${testing ? ' TEST' : ''} PRODUCT WAS NOT FOUND. ATTEMPTING TO CREATE NEW...');
//           var newProduct = await createStripeProduct(
//             // product: product,
//             productInfo: productInfo,
//             priceCalculations: priceCalculations,
//             // createLiveProduct: !testing,
//             // createTestProduct: testing,
//           );

//           if (newProduct.isNotEmpty) {
//             appLogger.i(
//                 '[[ STRIPE API CREATE PRICE ]] NEW${testing ? ' TEST' : ''} PRODUCT CREATED SUCCESSFULLY. CONTINUING CURRENT PROCESS...');

//             // ///
//             // product.updateStripeProductIds(
//             //     newProduct: testing ? newProduct[1]! : newProduct.first!,
//             //     isTestProduct: testing);

//             ///
//             // var newStripePrice = await getSpecificStripePrice(
//             //     priceId: testing
//             //         ? newProduct[1]!.defaultPrice
//             //         : newProduct.first!.defaultPrice);

//             // if (newStripePrice != null) {
//             //   price = newStripePrice;
//             //   product.updateStripePriceId(
//             //       newPrice: newStripePrice, isTestPrice: testing);
//             // }
//           }
//         } else {
//           var newPrice = StripePrice.fromJson(jsonDecode(priceResponse.body));
//           price = newPrice;
//           // product.updateStripePriceId(newPrice: newPrice, isTestPrice: testing);
//         }
//       } catch (err) {
//         Functions.sendErrorNotification(
//             error:
//                 // appLogger.e(
//                 '[[ STRIPE API CREATE PRICE ]] CREATE${testing ? ' TEST' : ''} PRICE ERROR: $err');
//       }
//     }
//     return price;
//   }

//   static Future<StripePrice?> searchForExistingStripePrice({
//     // SGAProduct? product,
//     GeneralProductInfo? productInfo,
//     required double priceToCheck,
//   }) async {
//     final testing = appTestingNotifier.value;
//     StripePrice? existingStripePrice;

//     var queryUrl = productInfo != null
//         ? "https://api.stripe.com/v1/prices/search?query=active:'true' AND product:'${productInfo.id}'"
//         : "https://api.stripe.com/v1/prices/search?query=active:'true'";

//     try {
//       final priceSearchResponse = await http.get(
//         Uri.parse(queryUrl),
//         headers: {
//           'Authorization': 'Bearer ${testing ? privateTestKey : privateKey}',
//           'Content-Type': 'application/x-www-form-urlencoded'
//         },
//         // body: body,
//       );

//       appLogger.d(
//           '[STRIPE API STRIPE PRICE SEARCH] STRIPE PRICE SEARCH RESPONSE: ${priceSearchResponse.body}');

//       if (priceSearchResponse.statusCode == 200) {
//         var responseJson = jsonDecode(priceSearchResponse.body);
//         final stripePriceList = List<StripePrice>.from(
//             responseJson['data'].map((x) => StripePrice.fromJson(x)));
//         appLogger.d(
//             '[STRIPE API STRIPE PRICE SEARCH] STRIPE PRICE SEARCH DATA : [${stripePriceList.length}] Items --> ${stripePriceList.map((e) => e.unitAmountDecimal)}');

//         List<StripePrice> reducedList = [];
//         if (productInfo != null) {
//           reducedList = stripePriceList
//               .where((item) =>
//                   item.product == productInfo.id &&
//                   item.unitAmountDecimal ==
//                       (priceToCheck * 100).toStringAsFixed(0))
//               .toList();
//         } else {
//           reducedList = stripePriceList
//               .where((item) =>
//                   item.unitAmountDecimal ==
//                   (priceToCheck * 100).toStringAsFixed(0))
//               .toList();
//         }
//         if (reducedList.isNotEmpty) {
//           appLogger.f(
//               '[STRIPE API STRIPE PRICE SEARCH] STRIPE PRICE REDUCED LIST: [${reducedList.length}] Items --> ${reducedList.map((e) => e.unitAmountDecimal)}');
//         } else {
//           appLogger.f(
//               '[STRIPE API STRIPE PRICE SEARCH] STRIPE PRICE REDUCED LIST IS EMPTY: [${reducedList.length}]');
//         }

//         existingStripePrice = reducedList.first;
//       }
//     } catch (e) {
//       Functions.sendErrorNotification(
//           error:
//               '[[ STRIPE API STRIPE PRICE SEARCH ]] ${testing ? 'TEST' : ''} STRIPE PRICE SEARCH ERROR: $e');
//     }

//     ///
//     return existingStripePrice;
//   }

//   static Future<String?> createStripePaymentLink({
//     // required bool liveProductOverride,
//     required AppUser appUser,
//     required StripeCustomer customer,
//     required PurchaserInfo purchaserInfo,
//     // required CustomerAddress shippingAddress,
//     // required SGAProduct product,
//     required GeneralProductInfo productInfo,
//     // required PriceCalculations priceCalculations,
//     // required double amount,
//   }) async {
//     appLogger.d(
//         '[[ STRIPE API CREATE PAYMENT LINK ]] ATTEMPTING TO CREATE WEB PAYMENT LINK');
//     final testing = appTestingNotifier.value; //  && !liveProductOverride;

//     // PackageInfo packageInfo = await Functions.getPackageInfo();

//     /// CHECK FOR PRICE ID
//     String? priceId;

//     var priceCalculations = priceCalculationsNotifier.value;

//     if (priceCalculations != null
//         // &&
//         // (priceCalculations.salePrice != null ||
//         //     priceCalculations.memberPrice != null)
//         ) {
//       appLogger.w(
//           '[STRIPE API CREATE PAYMENT LINK] ATTEMPTING TO CREATE ADJUSTED PRICE ID WITH NEWLY CALCULATED DATA...');
//       await getStripePrice(
//         productInfo: productInfo,
//         // product: product,
//         // priceAdjusted: true,
//       ).then((newPrice) {
//         if (newPrice != null) {
//           priceId = newPrice.id;
//         }
//       });
//     }
//     // else if (!testing && product.stripeLivePriceId != null) {
//     //   priceId = product.stripeLivePriceId;
//     // } else if (testing && product.stripeTestPriceId != null) {
//     //   priceId = product.stripeTestPriceId;
//     // }
//     // else {
//     //   appLogger.w(
//     //       '[STRIPE API CREATE PAYMENT LINK] PRICE ID IS NULL. ATTEMPTING TO CREATE NEW...');
//     //   await getStripePrice(
//     //     product: product,
//     //   ).then((newPrice) {
//     //     if (newPrice != null) {
//     //       priceId = newPrice.id;
//     //     }
//     //   });
//     // }

//     /// CHECK FOR SHIPPING ID
//     String? shippingId;
//     // if (!testing && product.stripeLiveProductShippingId != null) {
//     //   shippingId = product.stripeLiveProductShippingId;
//     // } else if (testing && product.stripeTestProductShippingId != null) {
//     //   shippingId = product.stripeTestProductShippingId;
//     // } else {
//     appLogger.d('[STRIPE API CREATE PAYMENT LINK] CREATING STRIPE SHIPPING ID');
//     await createStripeProductShippingIds(
//       productInfo: productInfo,
//       // product: product,
//       // product: product,
//       // shippingPrice: product.shippingAndHandling,
//       createLiveShippingId: !testing,
//       createTestShippingId: testing,
//     ).then((newShippingIds) {
//       if (newShippingIds.isNotEmpty) {
//         shippingId = testing ? newShippingIds[1]?.id : newShippingIds.first?.id;
//       } else {
//         appLogger.e(
//             '[STRIPE API CREATE PAYMENT LINK] UNABLE TO GENERATE SHIPPING ID. ATTEMPTING TO CREATE NEW...');
//       }
//     });
//     // }

//     if (shippingId != null && priceId != null) {
//       /// CREATE PURCHASE PAYMENT LINK
//       final body = <String, String>{
//         "line_items[0][price]": priceId!,
//         "line_items[0][quantity]": "1",
//         "shipping_options[0][shipping_rate]": shippingId!,
//         "billing_address_collection": "required",
//         "shipping_address_collection[allowed_countries][0]": "US",
//         //? "shipping_address_collection[allowed_countries][1]": "CA",
//         // "after_completion[type]": "redirect",
//         // "after_completion[redirect][url]": Application.paymentSuccessUrl,
//         "after_completion[type]": "hosted_confirmation",
//         "after_completion[hosted_confirmation][custom_message]":
//             "Your transaction is complete. You may now close this window.",
//         "allow_promotion_codes": "true",
//         // "automatic_tax[enabled]": "true",
//         "metadata[app_user_id]": appUser.appUserId,
//         // "metadata[app_version]":
//         //     "${packageInfo.version} : ${packageInfo.buildNumber}",
//       };

//       final paymentLinkResponse = await http.post(
//         Uri.parse('https://api.stripe.com/v1/payment_links'),
//         headers: {
//           'Authorization': 'Bearer ${testing ? privateTestKey : privateKey}',
//           'Content-Type': 'application/x-www-form-urlencoded'
//         },
//         body: body,
//       );

//       appLogger.d(
//           '[STRIPE API CREATE PAYMENT LINK] PAYMENT LINK RESPONSE: ${paymentLinkResponse.body}');

//       if (paymentLinkResponse.statusCode == 200) {
//         var responseJson = jsonDecode(paymentLinkResponse.body);
//         final String rootPaymentLink = responseJson['url'];
//         appLogger.d(
//             '[STRIPE API CREATE PAYMENT LINK] PAYMENT LINK ROOT: $rootPaymentLink');
//         final String paymentLinkId = responseJson["id"];

//         /// Get coupon and promo-code
//         PromoCode? promoCode;
//         // if (product.onSalePercent.value > 0) {
//         await getCouponAndPromoCode(
//                 productInfo: productInfo,
//                 // product: product,
//                 percentOff: priceCalculations!.totalPercentOff)
//             .then((val) {
//           if (val != null) {
//             promoCode = val.promoCode;
//           }
//         });
//         // }

//         /// Create final payment link
//         final String customerPaymentLink = promoCode != null
//             ? "$rootPaymentLink?prefilled_email=${purchaserInfo.email}&client_reference_id=${appUser.appUserId}&prefilled_promo_code=${promoCode!.code}"
//             : "$rootPaymentLink?prefilled_email=${purchaserInfo.email}&client_reference_id=${appUser.appUserId}";

//         // /// Create final payment link
//         // final String customerPaymentLink = promoCode != null
//         //     ? "$rootPaymentLink?prefilled_email=${shippingAddress.email}&client_reference_id=${appUser.appUserId}&prefilled_promo_code=${promoCode!.code}"
//         //     : "$rootPaymentLink?prefilled_email=${shippingAddress.email}&client_reference_id=${appUser.appUserId}";

//         appLogger.d(
//             '[STRIPE API CREATE PAYMENT LINK] PAYMENT LINK RETURNED: $customerPaymentLink');
//         return "$paymentLinkId${Delimiters.standard}$customerPaymentLink";
//       } else {
//         appLogger.e(
//             '[STRIPE API CREATE PAYMENT LINK] CREATE PAYMENT LINK API CALL ERROR: ${paymentLinkResponse.statusCode}');
//         return null;
//       }
//     } else {
//       appLogger.e(
//           '[STRIPE API CREATE PAYMENT LINK] FAILED TO CREATE PAYMENT LINK. UNABLE TO CREATE SHIPPING ID OR PRICE ID IS NULL');
//       return null;
//     }
//   }

//   static Future<List<StripeShippingId?>> createStripeProductShippingIds({
//     // required SGAProduct product,
//     required GeneralProductInfo productInfo,
//     // required double shippingPrice,
//     bool createLiveShippingId = true,
//     bool createTestShippingId = true,
//   }) async {
//     // final testing = appTestingNotifier.value;
//     StripeShippingId? liveShippingId;
//     StripeShippingId? testShippingId;
//     double shippingAndHandling = productInfo.defaultHandlingPrice +
//         (productInfo.retailPrice * productInfo.defaultShippingMultiplier);
//     try {
//       appLogger.d(
//           '[[ STRIPE API CREATE SHIPPING ID ]] ATTEMPTING TO CREATE SHIPPING IDS');

//       //Request body
//       Map<String, dynamic> body = {
//         "display_name": "Shipping & Handling",
//         "type": "fixed_amount",
//         "fixed_amount[amount]": "${(shippingAndHandling * 100).toInt()}",
//         "fixed_amount[currency]": "usd",
//         // "metadata[cost_string]": "${(product.cost * 100).toInt()}",
//         // "metadata[retail_price_string]":
//         //     "${(product.retailPrice * 100).toInt()}",
//       };

//       /// CREATE LIVE SHIPPING ID
//       if (createLiveShippingId) {
//         var liveResponse = await http.post(
//           Uri.parse('https://api.stripe.com/v1/shipping_rates'),
//           headers: {
//             'Authorization': 'Bearer $privateKey',
//             'Content-Type': 'application/x-www-form-urlencoded'
//           },
//           body: body,
//         );
//         appLogger.d(
//             '[[ STRIPE API CREATE SHIPPING ID ]] LIVE SHIPPING ID RESPONSE: ${liveResponse.body}');
//         var newLiveShippingId = stripeShippingIdFromJson(liveResponse.body);
//         liveShippingId = newLiveShippingId;
//       }

//       /// CREATE TEST SHIPPING ID
//       if (createTestShippingId) {
//         var testResponse = await http.post(
//           Uri.parse('https://api.stripe.com/v1/shipping_rates'),
//           headers: {
//             'Authorization': 'Bearer $privateTestKey',
//             'Content-Type': 'application/x-www-form-urlencoded'
//           },
//           body: body,
//         );
//         appLogger.d(
//             '[[ STRIPE API CREATE SHIPPING ID ]] TEST SHIPPING ID RESPONSE: ${testResponse.body}');
//         var newTestShippingId = stripeShippingIdFromJson(testResponse.body);
//         testShippingId = newTestShippingId;
//       }

//       // product.updateStripeShippingId(
//       //     newShippingId: testing ? testShippingId!.id : liveShippingId!.id,
//       //     isTestShipping: testing);
//     } catch (err) {
//       Functions.sendErrorNotification(
//           error:
//               // appLogger.d(
//               '[[ STRIPE API CREATE SHIPPING ID ]] CREATE SHIPPING ID ERROR: $err');
//     }
//     return [liveShippingId, testShippingId];
//   }

//   /// VERIFICATION METHOD => https://stripe.com/docs/api/payment_intents/search?lang=curl
//   static Future<(bool, CheckoutSessionsDatum?, PriceCalculations?)>
//       verifyStripePayment({
//     // required SGAProduct product,
//     required GeneralProductInfo productInfo,
//     // required String stripeProductId,
//     required String customerId,
//     required String paymentLink,
//   }) async {
//     /// RETRIEVE RECENT CHECKOUT SESSIONS
//     bool verified = false;
//     PriceCalculations? newPriceCalculations;
//     PriceCalculations? currentPriceCalculations =
//         priceCalculationsNotifier.value;
//     CheckoutSessionsDatum? checkoutSession;
//     List<CheckoutSessionsDatum> checkoutSessionsList =
//         await getRecentCheckoutSessions(
//       customerId: customerId,
//       paymentLink: paymentLink,
//     );
//     appLogger.d(
//         '[STRIPE API PURCHASE VERIFICATION] ${checkoutSessionsList.length} CHECKOUT SESSIONS RECEIVED');

//     /// START PURCHASE VERIFICATION
//     if (checkoutSessionsList.isNotEmpty) {
//       appLogger.d(
//           '[STRIPE API PURCHASE VERIFICATION] THIS PRODUCT: ${productInfo.title} - ${checkoutSessionsList.length} CHECKOUT SESSIONS');

//       final bool purchaseIsValid = checkoutSessionsList.any(
//         (element) =>
//             element.status == "complete" && element.paymentStatus == "paid",
//       );

//       if (purchaseIsValid) {
//         purchaseSuccessfulNotifier.value = true;
//         verified = true;
//         checkoutSession = checkoutSessionsList.firstWhere((element) =>
//             element.status == "complete" && element.paymentStatus == "paid");

//         /// CHECK FOR DISCREPANCIES IN LOCAL PRICES VS. FINAL STRIPE PRICES
//         var currentOrderFinalPrice = double.parse(
//             currentPriceCalculations!.totalForThisSale.toStringAsFixed(2));

//         var checkoutSessionFinalPrice = double.parse(
//             (checkoutSession.amountTotal! / 100).toStringAsFixed(2));

//         appLogger.w(
//             "[STRIPE API PURCHASE VERIFICATION] CHECKING FOR FINAL ORDER PRICE EQUALITY. LOCAL APP PRICE:$currentOrderFinalPrice VS. $checkoutSessionFinalPrice");

//         if (currentOrderFinalPrice != checkoutSessionFinalPrice) {
//           appLogger.f(
//               "[STRIPE API PURCHASE VERIFICATION] PRICE COMPARISON DISCREPANCY FOUND. UPDATING PRICE CALCULATIONS TO FINAL VALUES...");

//           ///
//           double checkoutSessionFinalPercentOff =
//               (checkoutSession.totalDetails.amountDiscount /
//                       checkoutSession.amountSubtotal!) *
//                   100;
//           double checkoutSessionFinalSubtotal =
//               (checkoutSession.amountSubtotal! -
//                       checkoutSession.totalDetails.amountDiscount) /
//                   100;

//           ///
//           newPriceCalculations = PriceCalculations(
//             retailPrice: currentPriceCalculations.retailPrice,
//             salePrice: currentPriceCalculations.salePrice,
//             memberPrice: currentPriceCalculations.memberPrice,
//             finalBuyPrice: currentPriceCalculations.finalBuyPrice,
//             totalPercentOff: checkoutSessionFinalPercentOff,
//             shippingPrice: currentPriceCalculations.shippingPrice,
//             subtotal: checkoutSessionFinalSubtotal,
//             totalForThisSale: checkoutSessionFinalPrice,
//           );

//           /// UPDATE NOTIFIEER
//           priceCalculationsNotifier.value = newPriceCalculations;
//         }
//       }
//     }
//     return (
//       verified,
//       checkoutSession,
//       newPriceCalculations ?? currentPriceCalculations
//     );
//   }

//   /// GET RECENT CHECKOUT SESSIONS
//   static Future<List<CheckoutSessionsDatum>> getRecentCheckoutSessions({
//     required String customerId,
//     required String paymentLink,
//   }) async {
//     final testing = appTestingNotifier.value;
//     var localData = localDataNotifier.value;
//     List<CheckoutSessionsDatum> sessionsList = [];

//     try {
//       appLogger.d(
//           '[STRIPE API GET CHECKOUT SESSIONS] FETCHING CHECKOUT SESSIONS...');
//       final checkoutSessionsResponse = await http.get(
//         Uri.parse('https://api.stripe.com/v1/checkout/sessions'),
//         headers: {
//           'Authorization': 'Bearer ${testing ? privateTestKey : privateKey}',
//           'Content-Type': 'application/x-www-form-urlencoded'
//         },
//       );

//       if (checkoutSessionsResponse.statusCode == 200) {
//         appLogger.d(
//             '[STRIPE API GET CHECKOUT SESSIONS] CHECKOUT SESSIONS STATUS CODE: ${checkoutSessionsResponse.statusCode}');

//         final checkoutSessions =
//             checkoutSessionsFromJson(checkoutSessionsResponse.body);

//         List<CheckoutSessionsDatum> stripeCheckoutSessionsList =
//             checkoutSessions.data;

//         appLogger.d(
//             '[STRIPE API GET CHECKOUT SESSIONS] ${stripeCheckoutSessionsList.length} CHECKOUT SESSIONS RETRIEVED');

//         appLogger.d(
//             '[STRIPE API GET CHECKOUT SESSIONS] FIRST ${testing ? 'TEST' : ''} CHECKOUT SESSIONS RESPONSE DATA PAYMENT LINK : ${stripeCheckoutSessionsList.first.paymentLink} VS. COMPARABLE PAYMENT LINK: $paymentLink');
//         stripeCheckoutSessionsList
//             .retainWhere((element) => element.paymentLink == paymentLink);
//         appLogger.d(
//             '[STRIPE API GET CHECKOUT SESSIONS] ${stripeCheckoutSessionsList.length} CHECKOUT SESSION REMAIN AFTER PRUNING FOR PAYMENT-LINK');

//         if (stripeCheckoutSessionsList.isNotEmpty &&
//             stripeCheckoutSessionsList.first.customerDetails != null &&
//             stripeCheckoutSessionsList.first.shippingDetails != null) {
//           ///! SAVE SESSION SHIPPING ADDRESS TO LOCAL DATABASE
//           var thisCheckoutSession = stripeCheckoutSessionsList.first;
//           var custDet = thisCheckoutSession.customerDetails;
//           var shipDet = thisCheckoutSession.shippingDetails;

//           ///
//           // ignore: unused_local_variable
//           var orderAddress = CustomerAddress(
//             city: shipDet!.address.city,
//             country: shipDet.address.country,
//             line1: shipDet.address.line1,
//             line2: shipDet.address.line2,
//             postalCode: shipDet.address.postalCode,
//             state: shipDet.address.state,
//             fullName: shipDet.name,
//             email: custDet!.email,
//             phone: custDet.phone ?? "",
//           );

//           var userAddress = UserShippingAddress(
//               fullName: shipDet.name,
//               addressLine1: shipDet.address.line1,
//               addressLine2: shipDet.address.line2 ?? "",
//               city: shipDet.address.city,
//               state: shipDet.address.state,
//               postalCode: shipDet.address.postalCode,
//               phone: custDet.phone ?? "",
//               email: custDet.email,
//               country: shipDet.address.country);

//           localData.appUser!.updateUserAddress(newAddress: userAddress);
//         }

//         sessionsList = stripeCheckoutSessionsList;
//       } else {
//         appLogger.d(
//             '[STRIPE API GET CHECKOUT SESSIONS] NO ${testing ? 'TEST' : ''} CHECKOUT SESSIONS FOUND: STATUS CODE = ${checkoutSessionsResponse.statusCode}');
//       }
//     } catch (e) {
//       Functions.sendErrorNotification(
//           error:
//               '[STRIPE API GET CHECKOUT SESSIONS] ${testing ? 'TEST' : ''} CHECKOUT SESSIONS RETRIEVAL ERROR: $e');
//     }
//     return sessionsList;
//   }

//   static Future<CouponAndPromoCode?> getCouponAndPromoCode({
//     GeneralProductInfo? productInfo,
//     // SGAProduct? product,
//     String? couponName,
//     double? percentOff,
//     int? maxRedemptions,
//   }) async {
//     Coupon? newCoupon;
//     PromoCode? newPromoCode;
//     bool memberLoggedIn = firebaseUserCredentialsNotifier.value != null;

//     if (productInfo != null) {
//       var priceCalculations = await PriceCalculations.calculatePrices(
//         memberLoggedIn: memberLoggedIn,
//         memberPercentOff: memberLoggedIn ? productInfo.memberPercentOff : null,
//         retailPrice: productInfo.retailPrice,
//         salePercentOff: productInfo.salePercentOff,
//         defaultProductHandlingPrice: productInfo.defaultHandlingPrice,
//         shippingPriceMultiplier: productInfo.defaultShippingMultiplier,
//       );

//       appLogger.w(
//           '[STRIPE API CREATE COUPON WITH PROMO CODE] FINAL PERCENT OFF TO BE USED ==> ${priceCalculations.totalPercentOff}%');

//       if ((percentOff != null && percentOff > 0.01) ||
//           priceCalculations.totalPercentOff > 0.01) {
//         await getCoupon(
//           productInfo: productInfo,
//           // product: product,
//           couponName: couponName,
//           maxRedemptions: maxRedemptions,
//         ).then((coupon) async {
//           if (coupon != null) {
//             appLogger.i(
//                 '[STRIPE API CREATE COUPON WITH PROMO CODE] COUPON TO BE USED ==> ${coupon.id}');
//             newCoupon = coupon;
//             await getPromoCode(coupon: coupon).then((promoCode) {
//               if (promoCode != null) {
//                 appLogger.i(
//                     '[STRIPE API CREATE COUPON WITH PROMO CODE] PROMO CODE TO BE USED ==> ${promoCode.code}');
//                 newPromoCode = promoCode;
//               }
//             });
//           } else {
//             appLogger.e(
//                 '[STRIPE API CREATE COUPON WITH PROMO CODE] COUPON RETURNED NULL. PROMO CODE NOT CREATED.');
//           }
//         });
//       } else {
//         appLogger.w(
//             '[STRIPE API CREATE COUPON WITH PROMO CODE] DISCOUNT PERCENT IS ${priceCalculations.totalPercentOff}. COUPON NOT REQUIRED.');
//       }
//     }
//     return newCoupon == null || newPromoCode == null
//         ? null
//         : CouponAndPromoCode(coupon: newCoupon!, promoCode: newPromoCode!);
//   }

//   static Future<Coupon?> getCoupon({
//     // SGAProduct? product,
//     GeneralProductInfo? productInfo,
//     String? couponName,
//     int? maxRedemptions,
//   }) async {
//     final testing = appTestingNotifier.value;
//     var priceCalculations = priceCalculationsNotifier.value;
//     Coupon? coupon;

//     ///
//     try {
//       if (productInfo?.salePercentOff != null) {
//         await checkForExistingCoupon(
//                 percentOff: priceCalculations?.totalPercentOff ??
//                     productInfo!.salePercentOff!)
//             .then((value) {
//           if (value != null) {
//             coupon = value;
//           }
//         });
//       }
//     } catch (e) {
//       Functions.sendErrorNotification(
//           error:
//               // appLogger.e(
//               '[[ STRIPE API CREATE COUPON ]] GET${testing ? ' TEST' : ''} EXISTING COUPON RETRIEVAL ERROR. ATTEMPTING TO CREATE NEW...\n ERROR: $e');
//     }

//     ///
//     if (coupon == null) {
//       try {
//         appLogger.d(
//             '[[ STRIPE API CREATE COUPON ]] ATTEMPTING TO GET${testing ? ' TEST' : ''} COUPON');

//         //Request body
//         Map<String, String>? couponBody;

//         if (priceCalculations != null) {
//           // if (product != null) {
//           // if (couponName != null) {
//           couponBody = {
//             "name": couponName ??
//                 "${priceCalculations.totalPercentOff.toStringAsFixed(2)}% OFF",
//             "percent_off": priceCalculations.totalPercentOff.toStringAsFixed(2),
//             "currency": "usd",
//             "duration": "forever",
//           };

//           if (maxRedemptions != null) {
//             couponBody.addAll({
//               "max_redemptions": maxRedemptions.toString(),
//             });
//           }
//           // } else {
//           //   couponBody = {
//           //     "name":
//           //         "${priceCalculations.totalPercentOff.toStringAsFixed(2)}% OFF",
//           //     "percent_off":
//           //         priceCalculations.totalPercentOff.toStringAsFixed(2),
//           //     "currency": "usd",
//           //     "duration": "once",
//           //     "max_redemptions": "${maxRedemptions ?? 1}",
//           //     // "redeem_by":
//           //     //     "${DateTime.now().add(const Duration(minutes: 30)).millisecondsSinceEpoch}",
//           //     // "metadata[cost_string]": "${(product.cost * 100).toInt()}",
//           //     // "metadata[retail_price_string]":
//           //     //     "${(product.retailPrice * 100).toInt()}",
//           //   };
//           // }
//         }

//         if (couponBody != null) {
//           //Make post request to Stripe
//           var couponResponse = await http.post(
//             Uri.parse('https://api.stripe.com/v1/coupons'),
//             headers: {
//               'Authorization':
//                   'Bearer ${testing ? privateTestKey : privateKey}',
//               'Content-Type': 'application/x-www-form-urlencoded'
//             },
//             body: couponBody,
//           );
//           appLogger.i(
//               '[[ STRIPE API GET COUPON ]]${testing ? ' TEST' : ''} RESPONSE: ${couponResponse.body}');
//           var newCoupon = Coupon.fromJson(jsonDecode(couponResponse.body));
//           coupon = newCoupon;
//         }
//       } catch (err) {
//         Functions.sendErrorNotification(
//             error:
//                 '[[ STRIPE API GET COUPON ]] GET${testing ? ' TEST' : ''} COUPON/PROMO-CODE ERROR: $err');
//       }
//     }

//     ///
//     return coupon;
//   }

//   static Future<Coupon?> checkForExistingCoupon(
//       {required double percentOff}) async {
//     final testing = appTestingNotifier.value;
//     Coupon? existingCoupon;

//     try {
//       ///
//       await getAllCoupons().then((coupons) {
//         if (coupons.isNotEmpty &&
//             coupons.map((e) => e.percentOff).any((element) =>
//                 element.toStringAsFixed(2) == percentOff.toStringAsFixed(2))) {
//           var possibleCoupon = coupons.firstWhere((coupon) =>
//               coupon.percentOff.toStringAsFixed(2) ==
//               percentOff.toStringAsFixed(2));

//           ///
//           if (possibleCoupon.livemode == !testing &&
//               possibleCoupon.valid &&
//               (possibleCoupon.maxRedemptions == null ||
//                   (possibleCoupon.maxRedemptions != null &&
//                       possibleCoupon.timesRedeemed <
//                           possibleCoupon.maxRedemptions))) {
//             existingCoupon = possibleCoupon;
//           }
//         }
//       });
//     } catch (e) {
//       Functions.sendErrorNotification(
//           error:
//               '[[ STRIPE API CHECK FOR EXISTING COUPON ]] ${testing ? 'TEST' : ''} EXISTING COUPON RETRIEVAL ERROR: $e');
//     }

//     ///
//     return existingCoupon;
//   }

//   static Future<List<Coupon>> getAllCoupons() async {
//     final testing = appTestingNotifier.value; //  && !liveProductOverride;
//     List<Coupon> coupons = [];

//     try {
//       appLogger.d(
//           '[[ STRIPE PAYMENT API COUPONS ]] ATTEMPTING TO RETRIEVE${testing ? ' TEST' : ''} COUPONS');

//       //Make post request to Stripe
//       var response = await http.get(
//         Uri.parse('https://api.stripe.com/v1/coupons'),
//         headers: {
//           'Authorization': 'Bearer ${testing ? privateTestKey : privateKey}',
//           'Content-Type': 'application/x-www-form-urlencoded',
//           // 'Stripe-Version': '2022-11-15',
//         },
//       );
//       appLogger.d(
//           '[[ STRIPE PAYMENT API COUPONS ]]${testing ? ' TEST' : ''} RESPONSE: ${response.body}');

//       if (response.statusCode == 200) {
//         var stripeCouponList =
//             StripeCouponList.fromJson(jsonDecode(response.body));
//         coupons = stripeCouponList.coupons;
//         appLogger.d(
//             '[[ STRIPE PAYMENT API COUPONS ]]${testing ? ' TEST' : ''} COUPONS RETRIEVE: ${coupons.map((e) => e.id).join(",\n")}');
//       } else {
//         appLogger.d(
//             '[[ STRIPE PAYMENT API COUPONS ]] RETRIEVE${testing ? ' TEST' : ''} COUPONS JSON DECODE ERROR: ${response.statusCode}');
//       }
//     } catch (err) {
//       Functions.sendErrorNotification(
//           error:
//               '[[ STRIPE PAYMENT API COUPONS ]] RETRIEVE${testing ? ' TEST' : ''} COUPONS RETRIEVAL ERROR: $err');
//       throw Exception(err.toString());
//     }
//     return coupons;
//   }

//   static Future<PromoCode?> getPromoCode({
//     required Coupon coupon,
//     StripeCustomer? customer,
//   }) async {
//     final testing = appTestingNotifier.value;
//     PromoCode? promotionCode;

//     ///
//     try {
//       await checkForExistingPromoCode(coupon: coupon).then((value) {
//         if (value != null) {
//           promotionCode = value;
//         }
//       });
//     } catch (e) {
//       Functions.sendErrorNotification(
//           error:
//               // appLogger.e(
//               '[[ STRIPE API CREATE PROMO CODE ]] GET${testing ? ' TEST' : ''} EXISTING PROMO CODE RETRIEVAL ERROR. ATTEMPTING TO CREATE NEW...\n ERROR: $e');
//     }

//     ///
//     if (promotionCode == null) {
//       try {
//         appLogger.d(
//             '[[ STRIPE API CREATE PROMO CODE ]] ATTEMPTING TO CREATE${testing ? ' TEST' : ''} PROMO CODE');

//         //Request body
//         Map<String, String> promoCodeBody = {
//           "coupon": coupon.id,
//         };

//         if (coupon.maxRedemptions != null) {
//           promoCodeBody.addAll({
//             "max_redemptions": coupon.maxRedemptions,
//           });
//         }

//         var promoCodeResponse = await http.post(
//           Uri.parse('https://api.stripe.com/v1/promotion_codes'),
//           headers: {
//             'Authorization': 'Bearer ${testing ? privateTestKey : privateKey}',
//             'Content-Type': 'application/x-www-form-urlencoded'
//           },
//           body: promoCodeBody,
//         );
//         appLogger.i(
//             '[[ STRIPE API CREATE PROMO CODE ]]${testing ? ' TEST' : ''} RESPONSE: ${promoCodeResponse.body}');
//         PromoCode newPromoCode =
//             PromoCode.fromJson(jsonDecode(promoCodeResponse.body));
//         appLogger.i(
//             '[[ STRIPE API CREATE PROMO CODE ]]${testing ? ' TEST' : ''} PROMO CODE: ${newPromoCode.code}');
//         promotionCode = newPromoCode;
//       } catch (err) {
//         Functions.sendErrorNotification(
//             error:
//                 // appLogger.e(
//                 '[[ STRIPE API CREATE PROMO CODE ]] CREATE${testing ? ' TEST' : ''} PROMO-CODE ERROR: $err');
//       }
//     }
//     return promotionCode;
//   }

//   static Future<PromoCode?> checkForExistingPromoCode(
//       {required Coupon coupon}) async {
//     final testing = appTestingNotifier.value;
//     appLogger.d(
//         '[[ STRIPE PAYMENT API CHECK FOR EXISTING PROMO CODE ]] ATTEMPTING TO FIND EXISTING${testing ? ' TEST' : ''} PROMO CODE');

//     ///
//     PromoCode? existingPromoCode;

//     try {
//       ///
//       await getAllPromoCodes().then((promoCodes) {
//         if (promoCodes.isNotEmpty &&
//             promoCodes.map((e) => e.coupon.id).contains(coupon.id)) {
//           PromoCode retrievedPromoCode =
//               promoCodes.firstWhere((c) => c.coupon.id == coupon.id);

//           if (retrievedPromoCode.active &&
//               (retrievedPromoCode.maxRedemptions == null ||
//                   (retrievedPromoCode.maxRedemptions != null &&
//                       retrievedPromoCode.timesRedeemed <
//                           retrievedPromoCode.maxRedemptions))) {
//             existingPromoCode = retrievedPromoCode;
//           }
//         }
//       });
//     } catch (e) {
//       Functions.sendErrorNotification(
//           error:
//               '[[ STRIPE API CHECK FOR EXISTING PROMO CODE ]] ${testing ? 'TEST' : ''} EXISTING PROMO CODE RETRIEVAL ERROR: $e');
//     }

//     ///
//     return existingPromoCode;
//   }

//   static Future<List<PromoCode>> getAllPromoCodes() async {
//     final testing = appTestingNotifier.value; //  && !liveProductOverride;
//     List<PromoCode> promoCodes = [];

//     try {
//       appLogger.d(
//           '[[ STRIPE PAYMENT API PROMO CODES ]] ATTEMPTING TO RETRIEVE${testing ? ' TEST' : ''} PROMO CODES');

//       //Make post request to Stripe
//       var response = await http.get(
//         Uri.parse('https://api.stripe.com/v1/promotion_codes'),
//         headers: {
//           'Authorization': 'Bearer ${testing ? privateTestKey : privateKey}',
//           'Content-Type': 'application/x-www-form-urlencoded',
//           // 'Stripe-Version': '2022-11-15',
//         },
//       );
//       appLogger.d(
//           '[[ STRIPE PAYMENT API PROMO CODES ]]${testing ? ' TEST' : ''} RESPONSE: ${response.body}');

//       if (response.statusCode == 200) {
//         var stripePromoCodeList =
//             StripePromoCodeList.fromJson(jsonDecode(response.body));
//         promoCodes = stripePromoCodeList.data;
//         appLogger.d(
//             '[[ STRIPE PAYMENT API PROMO CODES ]]${testing ? ' TEST' : ''} PROMO CODES RETRIEVE: ${promoCodes.map((e) => e.id).join(",\n")}');
//       } else {
//         appLogger.d(
//             '[[ STRIPE PAYMENT API PROMO CODES ]] RETRIEVE${testing ? ' TEST' : ''} PROMO CODES JSON DECODE ERROR: ${response.statusCode}');
//       }
//     } catch (err) {
//       appLogger.e(
//           '[[ STRIPE PAYMENT API PROMO CODES ]] RETRIEVE${testing ? ' TEST' : ''} PROMO CODES RETRIEVAL ERROR: $err');
//       throw Exception(err.toString());
//     }
//     return promoCodes;
//   }
// }

// class CouponAndPromoCode {
//   Coupon? coupon;
//   PromoCode? promoCode;

//   CouponAndPromoCode({
//     required this.coupon,
//     required this.promoCode,
//   });
// }

// class StripeError {
//   String code;
//   String docUrl;
//   String message;
//   String param;
//   String requestLogUrl;
//   String type;

//   StripeError({
//     required this.code,
//     required this.docUrl,
//     required this.message,
//     required this.param,
//     required this.requestLogUrl,
//     required this.type,
//   });

//   factory StripeError.fromJson(Map<String, dynamic> json) => StripeError(
//         code: json["code"],
//         docUrl: json["doc_url"],
//         message: json["message"],
//         param: json["param"],
//         requestLogUrl: json["request_log_url"],
//         type: json["type"],
//       );

//   Map<String, dynamic> toJson() => {
//         "code": code,
//         "doc_url": docUrl,
//         "message": message,
//         "param": param,
//         "request_log_url": requestLogUrl,
//         "type": type,
//       };
// }

// class GeneralProductInfo {
//   String id;
//   String title;
//   String description;
//   List<String> imageUrls;
//   double retailPrice;
//   double? salePercentOff;
//   double? memberPercentOff;
//   double defaultHandlingPrice;
//   double defaultShippingMultiplier;

//   GeneralProductInfo({
//     required this.id,
//     required this.title,
//     required this.description,
//     required this.imageUrls,
//     required this.retailPrice,
//     required this.salePercentOff,
//     required this.memberPercentOff,
//     required this.defaultHandlingPrice,
//     required this.defaultShippingMultiplier,
//   });
// }

// class PriceCalculations {
//   double retailPrice;
//   double? salePrice;
//   double? memberPrice;
//   double finalBuyPrice;
//   double totalPercentOff;
//   double shippingPrice;
//   double subtotal;
//   double totalForThisSale;

//   PriceCalculations({
//     required this.retailPrice,
//     required this.salePrice,
//     required this.memberPrice,
//     required this.finalBuyPrice,
//     required this.totalPercentOff,
//     required this.shippingPrice,
//     required this.subtotal,
//     required this.totalForThisSale,
//   });

//   factory PriceCalculations.fromJson(Map<String, dynamic> json) =>
//       PriceCalculations(
//         retailPrice: json["retail_price"],
//         salePrice: json["sale_price"],
//         memberPrice: json["member_price"],
//         finalBuyPrice: json["final_price"],
//         totalPercentOff: json["total_percent"],
//         shippingPrice: json["shipping_price"],
//         subtotal: json["subtotal"],
//         totalForThisSale: json["total_sale"],
//       );

//   Map<String, dynamic> toJson() => {
//         "retail_price": retailPrice,
//         "sale_price": salePrice,
//         "member_price": memberPrice,
//         "final_price": finalBuyPrice,
//         "total_percent": totalPercentOff,
//         "shipping_price": shippingPrice,
//         "subtotal": subtotal,
//         "total_sale": totalForThisSale,
//       };

//   List<String> toGSheetsList() => [
//         retailPrice.toStringAsFixed(2),
//         salePrice == null ? "" : salePrice!.toStringAsFixed(2),
//         memberPrice == null ? "" : memberPrice!.toStringAsFixed(2),
//         finalBuyPrice.toStringAsFixed(2),
//         totalPercentOff.toStringAsFixed(2),
//         shippingPrice.toStringAsFixed(2),
//         subtotal.toStringAsFixed(2),
//         totalForThisSale.toStringAsFixed(2),
//       ];

//   factory PriceCalculations.fromGSheetsList(List<String> thisOrder) =>
//       PriceCalculations(
//         retailPrice: double.parse(thisOrder[0]),
//         salePrice: thisOrder[1].isEmpty ? null : double.parse(thisOrder[1]),
//         memberPrice: thisOrder[2].isEmpty ? null : double.parse(thisOrder[2]),
//         finalBuyPrice: double.parse(thisOrder[3]),
//         totalPercentOff: double.parse(thisOrder[4]),
//         shippingPrice: double.parse(thisOrder[5]),
//         subtotal: double.parse(thisOrder[6]),
//         totalForThisSale: double.parse(
//           thisOrder[7],
//         ),
//       );

//   @override
//   toString() => toGSheetsList().join(priceCalcDelimiter);

//   toDisplayString() =>
//       "Buy Price: \$${finalBuyPrice.toStringAsFixed(2)}  Discount: ${totalPercentOff.round()}%  Shipping: \$${shippingPrice.toStringAsFixed(2)}";

//   factory PriceCalculations.fromString(String string) =>
//       PriceCalculations.fromGSheetsList(string.split(priceCalcDelimiter));

//   static Future<PriceCalculations> calculatePrices({
//     required bool memberLoggedIn,
//     required double retailPrice,
//     required double? salePercentOff,
//     required double? memberPercentOff,
//     required double defaultProductHandlingPrice,
//     required double shippingPriceMultiplier,
//   }) async {
//     ///
//     // bool memberLoggedIn = firebaseUserCredentialsNotifier.value != null;
//     bool onSale = salePercentOff != null && salePercentOff > 0;
//     // bool onSale = product.onSalePercent.value > 0;

//     ///
//     // double retailPrice = product.retailPrice;
//     double? salePrice; // = product.retailPrice;
//     double? memberPrice; // = product.retailPrice;
//     double finalBuyPrice = retailPrice;
//     // double finalBuyPrice = product.retailPrice;
//     double totalPercentOff = 0;
//     // double totalPercentOff = 0;
//     double shippingPrice =
//         defaultProductHandlingPrice + (retailPrice * shippingPriceMultiplier);
//     // double shippingPrice = Application.defaultProductHandling +
//     //     (product.retailPrice * Application.shippingMultiplier);
//     double subtotal = finalBuyPrice - (finalBuyPrice * (totalPercentOff / 100));
//     double totalForThisSale;

//     ///
//     if (onSale) {
//       salePrice = retailPrice - (retailPrice * (salePercentOff / 100));
//       // salePrice = product.retailPrice -
//       //     (product.retailPrice * (product.onSalePercent.value / 100));

//       totalPercentOff = totalPercentOff + salePercentOff;
//       // totalPercentOff = totalPercentOff + product.onSalePercent.value;
//       finalBuyPrice = salePrice;
//       subtotal = finalBuyPrice - (finalBuyPrice * (totalPercentOff / 100));

//       if (memberLoggedIn && memberPercentOff != null && memberPercentOff > 0) {
//         memberPrice = salePrice - (salePrice * (memberPercentOff / 100));

//         double additionalPercentOff =
//             ((salePrice - memberPrice) / ((salePrice + memberPrice) / 2) * 100);

//         totalPercentOff = totalPercentOff + additionalPercentOff;
//         finalBuyPrice = memberPrice;
//         subtotal = finalBuyPrice - (finalBuyPrice * (totalPercentOff / 100));
//       }
//     } else if (!onSale &&
//         memberLoggedIn &&
//         memberPercentOff != null &&
//         memberPercentOff > 0) {
//       memberPrice = retailPrice - ((retailPrice * memberPercentOff) / 100);

//       totalPercentOff = memberPercentOff;
//       finalBuyPrice = memberPrice;
//       subtotal = finalBuyPrice - (finalBuyPrice * (totalPercentOff / 100));
//     }

//     totalForThisSale = subtotal + shippingPrice;

//     ///
//     appLogger.w(
//         '[[ CALCULATE PRICES FUNCTION ]] RETAIL PRICE ==> \$$retailPrice\n[[ CALCULATE PRICES FUNCTION ]] SALE PRICE ==> ${salePrice == null ? "Not on sale" : "\$$salePrice"}\n[[ CALCULATE PRICES FUNCTION ]] MEMBER PRICE ==> ${memberPrice == null ? "Not a member" : "\$$memberPrice"}\n[[ CALCULATE PRICES FUNCTION ]] FINAL BUY PRICE ==> \$$finalBuyPrice\n[[ CALCULATE PRICES FUNCTION ]] TOTAL %OFF ==> $totalPercentOff%\n[[ CALCULATE PRICES FUNCTION ]] SUBTOTAL ==> \$$subtotal\n[[ CALCULATE PRICES FUNCTION ]] SHIPPING PRICE ==> \$$shippingPrice\n[[ CALCULATE PRICES FUNCTION ]] TOTAL THIS SALE ==> \$$totalForThisSale');

//     var priceCalculations = PriceCalculations(
//         retailPrice: retailPrice,
//         salePrice: salePrice,
//         memberPrice: memberPrice,
//         totalPercentOff: totalPercentOff,
//         shippingPrice: shippingPrice,
//         finalBuyPrice: finalBuyPrice,
//         subtotal: subtotal,
//         totalForThisSale: totalForThisSale);

//     priceCalculationsNotifier.value = priceCalculations;

//     return priceCalculations;
//   }
// }
