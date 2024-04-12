//? To parse this JSON data, do
//?     final stripeProducts = stripeProductsFromJson(jsonString);

import 'dart:convert';

StripeProductsList stripeProductsListFromJson(String str) =>
    StripeProductsList.fromJson(json.decode(str));

String stripeProductsListToJson(StripeProductsList data) =>
    json.encode(data.toJson());

class StripeProductsList {
  StripeProductsList({
    required this.object,
    required this.products,
    required this.hasMore,
    required this.url,
  });

  final String object;
  final List<StripeProduct> products;
  final bool hasMore;
  final String url;

  factory StripeProductsList.fromJson(Map<String, dynamic> json) =>
      StripeProductsList(
        object: json["object"],
        products: List<StripeProduct>.from(
            json["data"].map((x) => StripeProduct.fromJson(x))),
        hasMore: json["has_more"],
        url: json["url"],
      );

  Map<String, dynamic> toJson() => {
        "object": object,
        "data": List<dynamic>.from(products.map((x) => x.toJson())),
        "has_more": hasMore,
        "url": url,
      };
}

// To parse this JSON data, do
//
//     final stripeProduct = stripeProductFromJson(jsonString);

StripeProduct stripeProductFromJson(String str) =>
    StripeProduct.fromJson(json.decode(str));

String stripeProductToJson(StripeProduct data) => json.encode(data.toJson());

class StripeProduct {
  StripeProduct({
    required this.id,
    required this.object,
    required this.active,
    required this.attributes,
    required this.created,
    required this.defaultPrice,
    required this.description,
    required this.images,
    required this.livemode,
    // required this.metadata,
    required this.name,
    required this.packageDimensions,
    required this.shippable,
    required this.statementDescriptor,
    required this.taxCode,
    required this.type,
    required this.unitLabel,
    required this.updated,
    required this.url,
  });

  final String id;
  final String object;
  final bool active;
  final List<dynamic> attributes;
  final int created;
  final String defaultPrice;
  final String description;
  final List<String> images;
  final bool livemode;
  // final StripeProductMetadata? metadata;
  final String name;
  final dynamic packageDimensions;
  final bool shippable;
  final String statementDescriptor;
  final dynamic taxCode;
  final String type;
  final String unitLabel;
  final int updated;
  final String url;

  factory StripeProduct.fromJson(Map<String, dynamic> json) => StripeProduct(
        id: json["id"] ?? "",
        object: json["object"] ?? "",
        active: json["active"] ?? false,
        attributes: json["attributes"] == null
            ? []
            : List<dynamic>.from(json["attributes"].map((x) => x)),
        created: json["created"] ?? 0,
        defaultPrice: json["default_price"] ?? "",
        description: json["description"] ?? "",
        images: List<String>.from(json["images"].map((x) => x)),
        livemode: json["livemode"] ?? false,
        // metadata: json["metadata"] == null
        //     ? null
        //     : StripeProductMetadata.fromJson(json["metadata"]),
        name: json["name"],
        packageDimensions: json["package_dimensions"] ?? "",
        shippable: json["shippable"] ?? false,
        statementDescriptor: json["statement_descriptor"] ?? "",
        taxCode: json["tax_code"] ?? "",
        type: json["type"] ?? "",
        unitLabel: json["unit_label"] ?? "",
        updated: json["updated"] ?? "",
        url: json["url"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "object": object,
        "active": active,
        "attributes": List<dynamic>.from(attributes.map((x) => x)),
        "created": created,
        "default_price": defaultPrice,
        "description": description,
        "images": List<dynamic>.from(images.map((x) => x)),
        "livemode": livemode,
        // "metadata": metadata?.toJson(),
        "name": name,
        "package_dimensions": packageDimensions,
        "shippable": shippable,
        "statement_descriptor": statementDescriptor,
        "tax_code": taxCode,
        "type": type,
        "unit_label": unitLabel,
        "updated": updated,
        "url": url,
      };
}

// class StripeProductMetadata {
//   StripeProductMetadata({
//     // required this.credits,
//     // required this.entitlements,
//     // required this.frequency,
//     // required this.productPrice,
//     // required this.productType,
//     required this.costString,
//     required this.retailPriceString,
//   });

//   final String costString;
//   final String retailPriceString;

//   factory StripeProductMetadata.fromJson(Map<String, dynamic> json) =>
//       StripeProductMetadata(
//         costString: json["cost"] ?? "",
//         retailPriceString: json["price"] ?? "100.00",
//       );

//   Map<String, dynamic> toJson() => {
//         "cost": costString,
//         "price": retailPriceString,
//       };
// }