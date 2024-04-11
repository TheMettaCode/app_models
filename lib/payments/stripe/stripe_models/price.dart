// To parse this JSON data, do
//
//     final stripePrice = stripePriceFromJson(jsonString);

import 'dart:convert';

StripePrice stripePriceFromJson(String str) =>
    StripePrice.fromJson(json.decode(str));

String stripePriceToJson(StripePrice data) => json.encode(data.toJson());

class StripePrice {
  String id;
  String object;
  bool active;
  String billingScheme;
  int created;
  String currency;
  dynamic customUnitAmount;
  bool livemode;
  dynamic lookupKey;
  // Metadata metadata;
  dynamic nickname;
  String product;
  // Recurring recurring;
  String taxBehavior;
  dynamic tiersMode;
  dynamic transformQuantity;
  String type;
  int unitAmount;
  String unitAmountDecimal;

  StripePrice({
    required this.id,
    required this.object,
    required this.active,
    required this.billingScheme,
    required this.created,
    required this.currency,
    required this.customUnitAmount,
    required this.livemode,
    required this.lookupKey,
    // required this.metadata,
    required this.nickname,
    required this.product,
    // required this.recurring,
    required this.taxBehavior,
    required this.tiersMode,
    required this.transformQuantity,
    required this.type,
    required this.unitAmount,
    required this.unitAmountDecimal,
  });

  factory StripePrice.fromJson(Map<String, dynamic> json) => StripePrice(
        id: json["id"],
        object: json["object"],
        active: json["active"],
        billingScheme: json["billing_scheme"],
        created: json["created"],
        currency: json["currency"],
        customUnitAmount: json["custom_unit_amount"],
        livemode: json["livemode"],
        lookupKey: json["lookup_key"],
        // metadata: Metadata.fromJson(json["metadata"]),
        nickname: json["nickname"],
        product: json["product"],
        // recurring: Recurring.fromJson(json["recurring"]),
        taxBehavior: json["tax_behavior"],
        tiersMode: json["tiers_mode"],
        transformQuantity: json["transform_quantity"],
        type: json["type"],
        unitAmount: json["unit_amount"],
        unitAmountDecimal: json["unit_amount_decimal"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "object": object,
        "active": active,
        "billing_scheme": billingScheme,
        "created": created,
        "currency": currency,
        "custom_unit_amount": customUnitAmount,
        "livemode": livemode,
        "lookup_key": lookupKey,
        // "metadata": metadata.toJson(),
        "nickname": nickname,
        "product": product,
        // "recurring": recurring.toJson(),
        "tax_behavior": taxBehavior,
        "tiers_mode": tiersMode,
        "transform_quantity": transformQuantity,
        "type": type,
        "unit_amount": unitAmount,
        "unit_amount_decimal": unitAmountDecimal,
      };
}

// class Metadata {
//     Metadata();

//     factory Metadata.fromJson(Map<String, dynamic> json) => Metadata(
//     );

//     Map<String, dynamic> toJson() => {
//     };
// }

// class Recurring {
//     dynamic aggregateUsage;
//     String interval;
//     int intervalCount;
//     String usageType;

//     Recurring({
//         required this.aggregateUsage,
//         required this.interval,
//         required this.intervalCount,
//         required this.usageType,
//     });

//     factory Recurring.fromJson(Map<String, dynamic> json) => Recurring(
//         aggregateUsage: json["aggregate_usage"],
//         interval: json["interval"],
//         intervalCount: json["interval_count"],
//         usageType: json["usage_type"],
//     );

//     Map<String, dynamic> toJson() => {
//         "aggregate_usage": aggregateUsage,
//         "interval": interval,
//         "interval_count": intervalCount,
//         "usage_type": usageType,
//     };
// }
