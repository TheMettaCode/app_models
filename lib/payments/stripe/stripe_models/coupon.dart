// To parse this JSON data, do
//
//     final stripeCoupons = stripeCouponsFromJson(jsonString);

import 'dart:convert';

StripeCouponList stripeCouponsFromJson(String str) =>
    StripeCouponList.fromJson(json.decode(str));

String stripeCouponsToJson(StripeCouponList data) => json.encode(data.toJson());

class StripeCouponList {
  String object;
  String url;
  bool hasMore;
  List<Coupon> coupons;

  StripeCouponList({
    required this.object,
    required this.url,
    required this.hasMore,
    required this.coupons,
  });

  factory StripeCouponList.fromJson(Map<String, dynamic> json) =>
      StripeCouponList(
        object: json["object"],
        url: json["url"],
        hasMore: json["has_more"],
        coupons: List<Coupon>.from(json["data"].map((x) => Coupon.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "object": object,
        "url": url,
        "has_more": hasMore,
        "data": List<dynamic>.from(coupons.map((x) => x.toJson())),
      };
}

class Coupon {
  String id;
  String object;
  dynamic amountOff;
  int created;
  dynamic currency;
  String duration;
  dynamic durationInMonths;
  bool livemode;
  dynamic maxRedemptions;
  // Metadata metadata;
  String name;
  double percentOff;
  dynamic redeemBy;
  int timesRedeemed;
  bool valid;

  Coupon({
    required this.id,
    required this.object,
    required this.amountOff,
    required this.created,
    required this.currency,
    required this.duration,
    required this.durationInMonths,
    required this.livemode,
    required this.maxRedemptions,
    // required this.metadata,
    required this.name,
    required this.percentOff,
    required this.redeemBy,
    required this.timesRedeemed,
    required this.valid,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) => Coupon(
        id: json["id"],
        object: json["object"],
        amountOff: json["amount_off"],
        created: json["created"],
        currency: json["currency"],
        duration: json["duration"],
        durationInMonths: json["duration_in_months"],
        livemode: json["livemode"],
        maxRedemptions: json["max_redemptions"],
        // metadata: Metadata.fromJson(json["metadata"]),
        name: json["name"],
        percentOff: json["percent_off"]?.toDouble(),
        redeemBy: json["redeem_by"],
        timesRedeemed: json["times_redeemed"],
        valid: json["valid"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "object": object,
        "amount_off": amountOff,
        "created": created,
        "currency": currency,
        "duration": duration,
        "duration_in_months": durationInMonths,
        "livemode": livemode,
        "max_redemptions": maxRedemptions,
        // "metadata": metadata.toJson(),
        "name": name,
        "percent_off": percentOff,
        "redeem_by": redeemBy,
        "times_redeemed": timesRedeemed,
        "valid": valid,
      };
}
