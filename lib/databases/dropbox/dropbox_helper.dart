import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../shared/constants.dart';

ValueNotifier<String?> dropboxAccessTokenNotifier = ValueNotifier(null);

class DropboxSecrets {
  DropboxSecrets({
    required this.appKey,
    required this.appSecret,
    required this.refreshToken,
  });

  final String appKey;
  final String appSecret;
  final String refreshToken;
}

class DropboxHelper {
  static Future<String?> generateAccessToken(
      {required DropboxSecrets secrets}) async {
    String? accessToken;
    try {
      debugPrint
          // Utilities.logger.i
          ("[[ DROPBOX HELPER :: UPLOAD IMAGE ]] SETTING REFRESH TOKEN HEADERS...");

      Map<String, String> tokenData = {
        "grant_type": "refresh_token",
        "refresh_token": secrets.refreshToken,
        "client_id": secrets.appKey,
        "client_secret": secrets.appSecret
      };

      appLogger.i(
          "[[ DROPBOX HELPER :: UPLOAD IMAGE ]] STARTING REFRESH TOKEN HTTP POST...");

      final tokenResp = await http.post(
        Uri.parse("https://api.dropbox.com/oauth2/token"),
        body: tokenData,
        // headers: tokenHeaders,
      );

      final tokenResponseData = tokenResp.body;

      appLogger.d(
          // Utilities.logger.i(
          "[[ DROPBOX HELPER :: UPLOAD IMAGE ]] REFRESH TOKEN RESPONSE BODY: ====> $tokenResponseData");

      var tokenJson = jsonDecode(tokenResponseData);
      accessToken = tokenJson["access_token"];
      dropboxAccessTokenNotifier.value = accessToken;
    } catch (e) {
      appLogger.e(
          "[[ DROPBOX HELPER :: UPLOAD IMAGE ]] ERROR WHILE RETRIEVING REFRESH TOKEN: $e");
    }
    return accessToken;
  }

  ///
  static Future<(String?, String?)> uploadImage({
    required bool isNotification,
    File? imageFile,
    Uint8List? webImageDataList,
    required String filenameWithExt,
  }) async {
    String? uploadedFilePath;
    String? dropboxUrl;
    String? raw1Url;
    Uint8List? uploadData;
    if ((kIsWeb && webImageDataList != null) || imageFile != null) {
      try {
        // Create a reference to "file.ext"
        final imageRef =
            "/applications/scapegoats/apparel/${isNotification ? 'notification' : 'product'}_images/$filenameWithExt";

        debugPrint(
            "[[ DROPBOX HELPER :: UPLOAD IMAGE ]] DROPBOX IMAGE REFERENCE: $imageRef");

        if (kIsWeb) {
          uploadData = webImageDataList;
        } else if (imageFile != null) {
          uploadData = await imageFile.readAsBytes();
        }

        ///
        if (uploadData != null) {
          debugPrint(
              "[[ DROPBOX HELPER :: UPLOAD IMAGE ]] SETTING UPLOAD HEADERS...");

          Map<String, String> uploadHeaders = {
            'Authorization': 'Bearer ${dropboxAccessTokenNotifier.value}',
            'Content-type': 'application/octet-stream',
            'Dropbox-API-Arg':
                '{\"path\": \"/apparel/${isNotification ? 'notification' : 'product'}_images/$filenameWithExt\", \"mode\": \"overwrite\"}',
          };

          debugPrint
              // Utilities.logger.i
              ("[[ DROPBOX HELPER :: UPLOAD IMAGE ]] STARTING UPLOAD HTTP POST...");

          final uploadResp = await http.post(
            Uri.parse("https://content.dropboxapi.com/2/files/upload"),
            body: uploadData,
            headers: uploadHeaders,
          );

          final fileUploadResponseData = uploadResp.body;

          appLogger.d(
              // Utilities.logger.i(
              "[[ DROPBOX HELPER :: UPLOAD IMAGE ]] IMAGE UPLOAD RESPONSE BODY: ====> $fileUploadResponseData");

          var fileJson = jsonDecode(fileUploadResponseData);
          uploadedFilePath = fileJson["path_lower"];
        }
      } catch (e) {
        appLogger.d(
            "[[ DROPBOX HELPER :: UPLOAD IMAGE ]] ERROR WHILE UPLOADING PRODUCT IMAGE: $e");
      }

      if (uploadedFilePath != null) {
        try {
          ///
          debugPrint
              // Utilities.logger.i
              ("[[ DROPBOX HELPER :: UPLOAD IMAGE ]] SETTING FILE LINK HEADERS...");

          Map<String, String> linkHeaders = {
            'Authorization': 'Bearer ${dropboxAccessTokenNotifier.value}',
            'Content-type': 'application/json',
          };

          Map<String, dynamic> linkData = {
            "path": uploadedFilePath,
            "settings": {
              "access": "viewer",
              "allow_download": true,
              "audience": "public",
              "requested_visibility": "public"
            }
          };

          debugPrint
              // Utilities.logger.i
              ("[[ DROPBOX HELPER :: UPLOAD IMAGE ]] STARTING FILE LINK HTTP POST...");

          final resp = await http.post(
            Uri.parse(
                "https://api.dropboxapi.com/2/sharing/create_shared_link_with_settings"),
            body: jsonEncode(linkData),
            headers: linkHeaders,
          );

          final linkResponseData = resp.body;

          appLogger.d(
              // Utilities.logger.i(
              "[[ DROPBOX HELPER :: UPLOAD IMAGE ]] IMAGE FILE LINK RESPONSE BODY: ====> $linkResponseData");

          var linkJson = jsonDecode(linkResponseData);
          String linkUrl = linkJson["url"];

          ///
          dropboxUrl = linkUrl;
          raw1Url = linkUrl.replaceFirst("&dl=0", "&raw=1");

          appLogger.d(
              "[[ DROPBOX HELPER :: UPLOAD IMAGE ]] IMAGE FILE LINKS TO RETURN... RETRIEVED URL: $dropboxUrl, RAW=1 URL: $raw1Url");
        } catch (e) {
          appLogger.e(
              "[[ DROPBOX HELPER :: UPLOAD IMAGE ]] ERROR WHILE UPLOADING PRODUCT IMAGE: $e");
        }
      }
    } else {
      appLogger
          .e("[[ DROPBOX HELPER :: UPLOAD IMAGE ]] NO IMAGE DATA PROVIDED");
    }

    return (dropboxUrl, raw1Url);
  }
}
