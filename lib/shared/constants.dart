import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

/// COMMON PACKAGES
final Logger appLogger = Logger();

/// API CONSTANTS
const int appApiResponseTimeoutSeconds = 15;

/// GENERAL CONSTANTS
const double maxContentWidth = 800;

/// PRODUCT CONSTANTS
const double defaultShippingMultiplier = 0.1;
const double defaultMemberPercentOff = 5;
const double defaultProductHandling = 4.99;
const double productEvaluationDays = 14;
const double firstPurchaseDiscountPercent = 10;

/// LAYOUT CONSTANTS
const SizedBox spaceWidth5 = SizedBox(width: 5);
const SizedBox spaceWidth10 = SizedBox(width: 10);
const SizedBox spaceHeight10 = SizedBox(height: 10);
const SizedBox spaceHeight5 = SizedBox(height: 5);

/// THEME CONSTANTS
List<Color> festive = [
  Colors.orange,
  Colors.pink,
  Colors.purple,
  Colors.teal,
  Colors.lime,
  // Colors.indigo,
  Colors.cyan,
  const Color(0xFF28ce00)
];

List<Color> primaries = Colors.primaries;
Color black = const Color(0xFF000000);
Color white = const Color(0xFFFFFFFF);
Color neonGreen = const Color(0xFF59FF2F);
Color brightGreen = const Color(0xFF28ce00);
Color mediumGreen = const Color(0xFF1D9100);
Color darkGreen = const Color(0xFF115300);
Color heartRed = const Color(0xFFFF3300);
Color yellow = const Color(0xFFFFFF00);

/// DELIMITERS
const addressDelimiter = "<|address|>";
const attributeDelimiter = "<|attribute|>";
const categoryDelimiter = "<|category|>";
const colorDelimiter = "<|color|>";
const companyDelimiter = "<|company|>";
const customerDelimiter = "<|customer|>";
const dimensionDelimiter = "<|dimension|>";
const emailListDelimiter = "<|email_data|>";
const imageDelimiter = "<|image|>";
const likeDelimiter = "<|like|>";
const orderDelimiter = "<|order|>";
const orderDataDelimiter = "<|order_data|>";
const optionDelimiter = "<|option|>";
const priceCalcDelimiter = "<|price_calculation|>";
const productDelimiter = "<|product|>";
const productListDelimiter = "<|product_list|>";
const productReviewDelimiter = "<|review|>";
const productReviewListDelimiter = "<|review_list|>";
const purchaserInfoDelimiter = "<|purchase_info|>";
const sessionDelimiter = "<|session|>";
const sizeDelimiter = "<|size|>";
const socialDelimiter = "<|social|>";
const socialItemDelimiter = "<|social_item|>";
const standardDelimiter = "<|:|>";
const stripeCustomerDelimiter = "<|stripe_customer|>";
const typeDelimiter = "<|type|>";
const userDelimiter = "<|user|>";
const weightDelimiter = "<|weight|>";
