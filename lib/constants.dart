import 'package:logger/logger.dart';

/// COMMON PACKAGES
final Logger appLogger = Logger();

/// API CONSTANTS
const int appApiResponseTimeoutSeconds = 15;

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
