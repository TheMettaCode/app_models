// To parse this JSON data, do
//
//     final stripeShippingId = stripeShippingIdFromJson(jsonString);

import 'dart:convert';

StripeShippingPrice stripeShippingIdFromJson(String str) =>
    StripeShippingPrice.fromJson(json.decode(str));

String stripeShippingIdToJson(StripeShippingPrice data) =>
    json.encode(data.toJson());

class StripeShippingPrice {
  String id;
  String object;
  bool active;
  int created;
  dynamic deliveryEstimate;
  String displayName;
  FixedAmount fixedAmount;
  bool livemode;
  // Metadata metadata;
  String taxBehavior;
  dynamic taxCode;
  String type;

  StripeShippingPrice({
    required this.id,
    required this.object,
    required this.active,
    required this.created,
    required this.deliveryEstimate,
    required this.displayName,
    required this.fixedAmount,
    required this.livemode,
    // required this.metadata,
    required this.taxBehavior,
    required this.taxCode,
    required this.type,
  });

  factory StripeShippingPrice.fromJson(Map<String, dynamic> json) =>
      StripeShippingPrice(
        id: json["id"],
        object: json["object"],
        active: json["active"],
        created: json["created"],
        deliveryEstimate: json["delivery_estimate"],
        displayName: json["display_name"],
        fixedAmount: FixedAmount.fromJson(json["fixed_amount"]),
        livemode: json["livemode"],
        // metadata: Metadata.fromJson(json["metadata"]),
        taxBehavior: json["tax_behavior"],
        taxCode: json["tax_code"],
        type: json["type"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "object": object,
        "active": active,
        "created": created,
        "delivery_estimate": deliveryEstimate,
        "display_name": displayName,
        "fixed_amount": fixedAmount.toJson(),
        "livemode": livemode,
        // "metadata": metadata.toJson(),
        "tax_behavior": taxBehavior,
        "tax_code": taxCode,
        "type": type,
      };
}

class FixedAmount {
  int amount;
  String currency;

  FixedAmount({
    required this.amount,
    required this.currency,
  });

  factory FixedAmount.fromJson(Map<String, dynamic> json) => FixedAmount(
        amount: json["amount"],
        currency: json["currency"],
      );

  Map<String, dynamic> toJson() => {
        "amount": amount,
        "currency": currency,
      };
}

// class Metadata {
//   Metadata();

//   factory Metadata.fromJson(Map<String, dynamic> json) => Metadata();

//   Map<String, dynamic> toJson() => {};
// }
