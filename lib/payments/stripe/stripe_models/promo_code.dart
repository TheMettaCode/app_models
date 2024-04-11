// To parse this JSON data, do
//
//     final stripePromoCodeList = stripePromoCodeListFromJson(jsonString);

import 'dart:convert';
import 'coupon.dart';

StripePromoCodeList stripePromoCodeListFromJson(String str) =>
    StripePromoCodeList.fromJson(json.decode(str));

String stripePromoCodeListToJson(StripePromoCodeList data) =>
    json.encode(data.toJson());

class StripePromoCodeList {
  final String object;
  final String url;
  final bool hasMore;
  final List<PromoCode> data;

  StripePromoCodeList({
    required this.object,
    required this.url,
    required this.hasMore,
    required this.data,
  });

  factory StripePromoCodeList.fromJson(Map<String, dynamic> json) =>
      StripePromoCodeList(
        object: json["object"],
        url: json["url"],
        hasMore: json["has_more"],
        data: List<PromoCode>.from(
            json["data"].map((x) => PromoCode.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "object": object,
        "url": url,
        "has_more": hasMore,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
      };
}

class PromoCode {
  final String id;
  final String object;
  final bool active;
  final String code;
  final Coupon coupon;
  final int created;
  final dynamic customer;
  final dynamic expiresAt;
  final bool livemode;
  final dynamic maxRedemptions;
  final Metadata metadata;
  final Restrictions restrictions;
  final int timesRedeemed;

  PromoCode({
    required this.id,
    required this.object,
    required this.active,
    required this.code,
    required this.coupon,
    required this.created,
    required this.customer,
    required this.expiresAt,
    required this.livemode,
    required this.maxRedemptions,
    required this.metadata,
    required this.restrictions,
    required this.timesRedeemed,
  });

  factory PromoCode.fromJson(Map<String, dynamic> json) => PromoCode(
        id: json["id"],
        object: json["object"],
        active: json["active"],
        code: json["code"],
        coupon: Coupon.fromJson(json["coupon"]),
        created: json["created"],
        customer: json["customer"],
        expiresAt: json["expires_at"],
        livemode: json["livemode"],
        maxRedemptions: json["max_redemptions"],
        metadata: Metadata.fromJson(json["metadata"]),
        restrictions: Restrictions.fromJson(json["restrictions"]),
        timesRedeemed: json["times_redeemed"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "object": object,
        "active": active,
        "code": code,
        "coupon": coupon.toJson(),
        "created": created,
        "customer": customer,
        "expires_at": expiresAt,
        "livemode": livemode,
        "max_redemptions": maxRedemptions,
        "metadata": metadata.toJson(),
        "restrictions": restrictions.toJson(),
        "times_redeemed": timesRedeemed,
      };
}

// class Coupon {
//   final String id;
//   final String object;
//   final dynamic amountOff;
//   final int created;
//   final dynamic currency;
//   final String duration;
//   final int durationInMonths;
//   final bool livemode;
//   final dynamic maxRedemptions;
//   final Metadata metadata;
//   final dynamic name;
//   final double percentOff;
//   final dynamic redeemBy;
//   final int timesRedeemed;
//   final bool valid;

//   Coupon({
//     required this.id,
//     required this.object,
//     required this.amountOff,
//     required this.created,
//     required this.currency,
//     required this.duration,
//     required this.durationInMonths,
//     required this.livemode,
//     required this.maxRedemptions,
//     required this.metadata,
//     required this.name,
//     required this.percentOff,
//     required this.redeemBy,
//     required this.timesRedeemed,
//     required this.valid,
//   });

//   factory Coupon.fromJson(Map<String, dynamic> json) => Coupon(
//         id: json["id"],
//         object: json["object"],
//         amountOff: json["amount_off"],
//         created: json["created"],
//         currency: json["currency"],
//         duration: json["duration"],
//         durationInMonths: json["duration_in_months"],
//         livemode: json["livemode"],
//         maxRedemptions: json["max_redemptions"],
//         metadata: Metadata.fromJson(json["metadata"]),
//         name: json["name"],
//         percentOff: json["percent_off"]?.toDouble(),
//         redeemBy: json["redeem_by"],
//         timesRedeemed: json["times_redeemed"],
//         valid: json["valid"],
//       );

//   Map<String, dynamic> toJson() => {
//         "id": id,
//         "object": object,
//         "amount_off": amountOff,
//         "created": created,
//         "currency": currency,
//         "duration": duration,
//         "duration_in_months": durationInMonths,
//         "livemode": livemode,
//         "max_redemptions": maxRedemptions,
//         "metadata": metadata.toJson(),
//         "name": name,
//         "percent_off": percentOff,
//         "redeem_by": redeemBy,
//         "times_redeemed": timesRedeemed,
//         "valid": valid,
//       };
// }

class Metadata {
  Metadata();

  factory Metadata.fromJson(Map<String, dynamic> json) => Metadata();

  Map<String, dynamic> toJson() => {};
}

class Restrictions {
  final bool firstTimeTransaction;
  final dynamic minimumAmount;
  final dynamic minimumAmountCurrency;

  Restrictions({
    required this.firstTimeTransaction,
    required this.minimumAmount,
    required this.minimumAmountCurrency,
  });

  factory Restrictions.fromJson(Map<String, dynamic> json) => Restrictions(
        firstTimeTransaction: json["first_time_transaction"],
        minimumAmount: json["minimum_amount"],
        minimumAmountCurrency: json["minimum_amount_currency"],
      );

  Map<String, dynamic> toJson() => {
        "first_time_transaction": firstTimeTransaction,
        "minimum_amount": minimumAmount,
        "minimum_amount_currency": minimumAmountCurrency,
      };
}


// class PromoCode {
//   String id;
//   String object;
//   bool active;
//   String code;
//   Coupon coupon;
//   int created;
//   String? customer;
//   dynamic expiresAt;
//   bool liveMode;
//   dynamic maxRedemptions;
//   // Metadata metadata;
//   // Restrictions restrictions;
//   int timesRedeemed;

//   PromoCode({
//     required this.id,
//     required this.object,
//     required this.active,
//     required this.code,
//     required this.coupon,
//     required this.created,
//     required this.customer,
//     required this.expiresAt,
//     required this.liveMode,
//     required this.maxRedemptions,
//     // required this.metadata,
//     // required this.restrictions,
//     required this.timesRedeemed,
//   });

//   factory PromoCode.fromJson(Map<String, dynamic> json) => PromoCode(
//         id: json["id"],
//         object: json["object"],
//         active: json["active"],
//         code: json["code"],
//         coupon: Coupon.fromJson(json["coupon"]),
//         created: json["created"],
//         customer: json["customer"],
//         expiresAt: json["expires_at"],
//         liveMode: json["livemode"],
//         maxRedemptions: json["max_redemptions"],
//         // metadata: Metadata.fromJson(json["metadata"]),
//         // restrictions: Restrictions.fromJson(json["restrictions"]),
//         timesRedeemed: json["times_redeemed"],
//       );

//   Map<String, dynamic> toJson() => {
//         "id": id,
//         "object": object,
//         "active": active,
//         "code": code,
//         "coupon": coupon.toJson(),
//         "created": created,
//         "customer": customer,
//         "expires_at": expiresAt,
//         "livemode": liveMode,
//         "max_redemptions": maxRedemptions,
//         // "metadata": metadata.toJson(),
//         // "restrictions": restrictions.toJson(),
//         "times_redeemed": timesRedeemed,
//       };
// }