// To parse this JSON data, do
//
//     final stripeCustomer = stripeCustomerFromJson(jsonString);

import 'dart:convert';

import 'package:app_models/constants.dart';

StripeCustomer stripeCustomerFromJson(String str) =>
    StripeCustomer.fromJson(json.decode(str));

String stripeCustomerToJson(StripeCustomer data) => json.encode(data.toJson());

class StripeCustomer {
  StripeCustomer({
    required this.id,
    required this.object,
    required this.address,
    // required this.balance,
    required this.created,
    required this.currency,
    // required this.defaultSource,
    // required this.delinquent,
    required this.description,
    // required this.discount,
    required this.email,
    // required this.invoicePrefix,
    // required this.invoiceSettings,
    // required this.livemode,
    required this.metadata,
    required this.name,
    // required this.nextInvoiceSequence,
    required this.phone,
    // required this.preferredLocales,
    // required this.shipping,
    // required this.taxExempt,
    // required this.testClock,
  });

  final String id;
  final String object;
  final CustomerAddress? address;
  // final int balance;
  final int created;
  final String currency;
  // final String defaultSource;
  // final bool delinquent;
  final String description;
  // final dynamic discount;
  final String email;
  // final String invoicePrefix;
  // final CustomerInvoiceSettings invoiceSettings;
  // final bool livemode;
  final CustomerMetadata? metadata;
  final String name;
  // final int nextInvoiceSequence;
  final String phone;
  // final List<dynamic> preferredLocales;
  // final dynamic shipping;
  // final String taxExempt;
  // final dynamic testClock;

  factory StripeCustomer.fromJson(Map<String, dynamic> json) => StripeCustomer(
        id: json["id"],
        object: json["object"],
        address: json["address"] == null
            ? null
            : CustomerAddress.fromJson(json["address"]),
        // balance: json["balance"],
        created: json["created"] ?? DateTime.now().millisecondsSinceEpoch,
        currency: json["currency"] ?? "usd",
        // defaultSource: json["default_source"],
        // delinquent: json["delinquent"],
        description: json["description"] ?? "",
        // discount: json["discount"],
        email: json["email"] ?? "",
        // invoicePrefix: json["invoice_prefix"],
        // invoiceSettings:
        //     CustomerInvoiceSettings.fromJson(json["invoice_settings"]),
        // livemode: json["livemode"],
        metadata: json["metadata"] == null
            ? null
            : CustomerMetadata.fromJson(json["metadata"]),
        name: json["name"] ?? "",
        // nextInvoiceSequence: json["next_invoice_sequence"],
        phone: json["phone"] ?? "",
        // preferredLocales:
        //     List<dynamic>.from(json["preferred_locales"].map((x) => x)),
        // shipping: json["shipping"],
        // taxExempt: json["tax_exempt"],
        // testClock: json["test_clock"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "object": object,
        "address": address?.toJson(),
        // "balance": balance,
        "created": created,
        "currency": currency,
        // "default_source": defaultSource,
        // "delinquent": delinquent,
        "description": description,
        // "discount": discount,
        "email": email,
        // "invoice_prefix": invoicePrefix,
        // "invoice_settings": invoiceSettings.toJson(),
        // "livemode": livemode,
        "metadata": metadata?.toJson(),
        "name": name,
        // "next_invoice_sequence": nextInvoiceSequence,
        "phone": phone,
        // "preferred_locales": preferredLocales.isEmpty
        //     ? []
        //     : List<dynamic>.from(preferredLocales.map((x) => x)),
        // "shipping": shipping,
        // "tax_exempt": taxExempt,
        // "test_clock": testClock,
      };

  @override
  toString() =>
      "$id$stripeCustomerDelimiter$object$stripeCustomerDelimiter${address.toString()}$stripeCustomerDelimiter$created$stripeCustomerDelimiter$currency$stripeCustomerDelimiter$description$stripeCustomerDelimiter$email$stripeCustomerDelimiter${metadata?.toString()}$stripeCustomerDelimiter$name$stripeCustomerDelimiter$phone";

  factory StripeCustomer.fromString(String x) {
    var cust = x.split(stripeCustomerDelimiter);
    return StripeCustomer(
      id: cust.first,
      object: cust.length > 1 ? cust[1] : "",
      address: cust.length > 2 ? CustomerAddress.fromString(cust[2]) : null,
      created: cust.length > 3 ? int.parse(cust[3]) : 0,
      description: cust.length > 4 ? cust[4] : "",
      currency: cust.length > 5 ? cust[5] : "",
      email: cust.length > 6 ? cust[6] : "",
      metadata: cust.length > 7 ? CustomerMetadata.fromString(cust[7]) : null,
      name: cust.length > 8 ? cust[8] : "",
      phone: cust.length > 9 ? cust[9] : "",
    );
  }
}

class CustomerAddress {
  CustomerAddress({
    required this.city,
    required this.country,
    required this.line1,
    required this.line2,
    required this.postalCode,
    required this.state,
    required this.fullName,
    required this.email,
    required this.phone,
  });

  final String city;
  final String country;
  final String line1;
  final String? line2;
  final String postalCode;
  final String state;
  final String fullName;
  final String email;
  final String? phone;

  factory CustomerAddress.fromJson(Map<String, dynamic> json) =>
      CustomerAddress(
        city: json["city"],
        country: json["country"],
        line1: json["line1"],
        line2: json["line2"],
        postalCode: json["postal_code"],
        state: json["state"],
        fullName: json["name"] ?? "",
        email: json["email"] ?? "",
        phone: json["phone"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "city": city,
        "country": country,
        "line1": line1,
        "line2": line2,
        "postal_code": postalCode,
        "state": state,
        "name": fullName,
        "email": email,
        "phone": phone,
      };

  @override
  toString() =>
      "$city$addressDelimiter$country$addressDelimiter$line1$addressDelimiter${line2 ?? ""}$addressDelimiter$postalCode$addressDelimiter$state$addressDelimiter$fullName$addressDelimiter$email$addressDelimiter${phone ?? ""}";

  toFormattedAddressString() =>
      "$fullName\n$line1${line2 == null || line2!.isEmpty ? "" : "\n$line2"}\n$city $state $postalCode $country";

  factory CustomerAddress.fromString(String x) {
    var item = x.split(addressDelimiter);
    return CustomerAddress(
      city: item.first,
      country: item.length > 1 ? item[1] : "",
      line1: item.length > 2 ? item[2] : "",
      line2: item.length > 3 ? item[3] : null,
      postalCode: item.length > 4 ? item[4] : "",
      state: item.length > 5 ? item[5] : "",
      fullName: item.length > 6 ? item[6] : "",
      email: item.length > 7 ? item[7] : "",
      phone: item.length > 8 ? item[8] : null,
    );
  }
}

class CustomerInvoiceSettings {
  CustomerInvoiceSettings({
    required this.customFields,
    required this.defaultPaymentMethod,
    required this.footer,
    required this.renderingOptions,
  });

  final dynamic customFields;
  final dynamic defaultPaymentMethod;
  final dynamic footer;
  final dynamic renderingOptions;

  factory CustomerInvoiceSettings.fromJson(Map<String, dynamic> json) =>
      CustomerInvoiceSettings(
        customFields: json["custom_fields"],
        defaultPaymentMethod: json["default_payment_method"],
        footer: json["footer"],
        renderingOptions: json["rendering_options"],
      );

  Map<String, dynamic> toJson() => {
        "custom_fields": customFields,
        "default_payment_method": defaultPaymentMethod,
        "footer": footer,
        "rendering_options": renderingOptions,
      };
}

class CustomerMetadata {
  CustomerMetadata({
    required this.appUserId,
    required this.appVersion,
    required this.application,
    required this.installerStore,
    required this.totalCredits,
  });

  final String appUserId;
  final String appVersion;
  final String application;
  final String installerStore;
  final int totalCredits;

  factory CustomerMetadata.fromJson(Map<String, dynamic> json) =>
      CustomerMetadata(
        appUserId: json["user_id"] ?? "",
        appVersion: json["app_version"] ?? "",
        application: json["application"] ?? "",
        installerStore: json["installer_store"] ?? "",
        totalCredits: int.parse(
          json["total_credits"] ?? "",
        ),
      );

  Map<String, dynamic> toJson() => {
        "user_id": appUserId,
        "app_version": appVersion,
        "application": application,
        "installer_store": installerStore,
        "total_credits": totalCredits,
      };

  @override
  toString() =>
      "$appUserId$standardDelimiter$appVersion$standardDelimiter$application$standardDelimiter$installerStore$standardDelimiter$totalCredits";

  factory CustomerMetadata.fromString(String x) {
    var item = x.split(standardDelimiter);
    return CustomerMetadata(
      appUserId: item.first,
      appVersion: item.length > 1 ? item[1] : "",
      application: item.length > 2 ? item[2] : "",
      installerStore: item.length > 3 ? item[3] : "",
      totalCredits: item.length > 4 ? int.parse(item[4]) : 0,
    );
  }
}

class CustomerTemporaryEphemeralKey {
  CustomerTemporaryEphemeralKey({
    required this.id,
    required this.object,
    required this.associatedObjects,
    required this.created,
    required this.expires,
    required this.liveMode,
    required this.secret,
  });

  final String id;
  final String object;
  final List<AssociatedObjects> associatedObjects;
  // final List<Map<String, dynamic>> associatedObjects;
  final int created;
  final int expires;
  final bool liveMode;
  final String secret;

  factory CustomerTemporaryEphemeralKey.fromJson(Map<String, dynamic> json) =>
      CustomerTemporaryEphemeralKey(
        id: json["id"] ?? "",
        object: json["object"] ?? "",
        associatedObjects: json["associated_objects"].isEmpty
            ? []
            // : List<Map<String, dynamic>>.from(json["associated_objects"]),
            : List<AssociatedObjects>.from(json["associated_objects"]
                .map((x) => AssociatedObjects.fromJson(x))),
        created: json["created"] ?? 0,
        expires: json["expires"] ?? 0,
        liveMode: json["live_mode"] ?? false,
        secret: json["secret"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "object": object,
        // "associated_objects": associatedObjects,
        "associated_objects":
            List<dynamic>.from(associatedObjects.map((x) => x.toJson())),
        "created": created,
        "expires": expires,
        "live_mode": liveMode,
        "secret": secret,
      };
}

class AssociatedObjects {
  AssociatedObjects({
    required this.id,
    required this.type,
  });

  final String id;
  final String type;

  factory AssociatedObjects.fromJson(Map<String, dynamic> json) =>
      AssociatedObjects(
        id: json["id"] ?? "",
        type: json["type"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "type": type,
      };
}
