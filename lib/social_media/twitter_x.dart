import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:twitter_api_v2/twitter_api_v2.dart' as x;
import '../constants.dart';

/// DATA NOTIFIER
ValueNotifier<x.TweetData?> xTweetDataNotifier = ValueNotifier(null);
ValueNotifier<AppTweetData?> appTweetDataNotifier = ValueNotifier(null);

class TwitterSecrets {
  TwitterSecrets(
      {required this.consumerKey,
      required this.consumerSecret,
      required this.bearerToken,
      required this.accessToken,
      required this.accessTokenSecret});

  /// TWITTER ACCOUNT KEYS
  final String consumerKey; // Env.twitterApiKey
  final String consumerSecret; // Env.twitterSecretKey
  final String?
      bearerToken; // Env.twitterBearerToken //? Leave 'null' if using v1
  final String accessToken; // Env.twitterAccessToken
  final String accessTokenSecret; // Env.twitterAccessTokenSecret

  // /// TWITTER ACCOUNT KEYS
  // static final String twitterConsumerKey = Env.twitterApiKey;
  // static final String twitterConsumerSecret = Env.twitterSecretKey;
  // static final String twitterBearerToken = Env.twitterBearerToken;
  // static final String twitterAccessToken = Env.twitterAccessToken;
  // static final String twitterAccessTokenSecret = Env.twitterAccessTokenSecret;
}

class TwitterXApi {
  /// TWITTER
  static Future<(x.TweetData?, AppTweetData?)> twitterPost({
    required TwitterSecrets twitterSecrets,
    required String message,
    String? urlLink,
    String? imageUrl,
    List<String>? hashtags,
    File? mediaFile,
    String? altText,
    bool testOverride = false,
  }) async {
    /// You need to get keys and tokens at https://developer.twitter.com
    x.TweetData? tweetResponseData;
    AppTweetData? appTweetData;

    ///
    if (!kIsWeb) {
      appLogger.d('[[ TWITTER API ]] ATTEMPTING TWEET POST PROCESS');
      var twitter = await getTwitterApi(twitterSecrets: twitterSecrets);
      // //! Get the authenticated user's profile.
      final me = await twitter.users.lookupMe();

      appLogger
          .i('[TWITTER API :: GET USER TEST] I AM ===>\n${me.data.toJson()}');

      try {
        if (mediaFile != null) {
          //! You can upload media such as image, gif and video.
          final uploadedMedia = await twitter.media.uploadMedia(
            file: mediaFile,
            altText: altText ?? "Uploaded Media",
            category: x.MediaCategory.tweet,
            additionalOwners: null,

            //! You can check the upload progress.
            onProgress: (event) {
              switch (event.state) {
                case x.UploadState.preparing:
                  appLogger.d('[[ TWITTER API ]] Upload is preparing...');
                  break;
                case x.UploadState.inProgress:
                  appLogger
                      .d('[[ TWITTER API ]] ${event.progress}% completed...');
                  break;
                case x.UploadState.completed:
                  appLogger.d('[[ TWITTER API ]] Upload has completed!');
                  break;
              }
            },
            onFailed: (error) => appLogger
                .d('[[ TWITTER API ]] Upload failed due to "${error.message}"'),
          );

          //! You can easily post a tweet with uploaded media.
          var tweetResponse = await twitter.tweets.createTweet(
              text: "$message\n$hashtags${urlLink == null ? '' : '\n$urlLink'}",
              media: x.TweetMediaParam(mediaIds: [uploadedMedia.data.id]));

          tweetResponseData = tweetResponse.data;
        } else {
          //! You can easily post a x.
          appLogger.d('[[ TWITTER API ]] ATTEMPTING TEXT ONLY TWEET POST');
          var tweetResponse = await twitter.tweets.createTweet(
            text: "$message\n$hashtags${urlLink == null ? '' : '\n$urlLink'}",
          );
          tweetResponseData = tweetResponse.data;

          appLogger.i(
              '[[ TWITTER API ]] TWEET RESPONSE ===>\nTEXT: ${tweetResponse.data.text}\n\nFULL RESPONSE: ${tweetResponse.data.toJson()}');
        }
      } on TimeoutException catch (e) {
        appLogger.d(e);
      } on x.UnauthorizedException catch (e) {
        appLogger.d(e);
      } on x.RateLimitExceededException catch (e) {
        appLogger.d(e);
      } on x.DataNotFoundException catch (e) {
        appLogger.d(e);
      } on x.TwitterUploadException catch (e) {
        appLogger.d(e);
      } on x.TwitterException catch (e) {
        appLogger.d(e.response.headers);
        appLogger.d(e.body);
        appLogger.d(e);
      }
      appLogger.d('[[ TWITTER API ]] POST TWEET PROCESS ENDED');
    } else {
      appLogger.w(
          '[[ TWITTER API ]] APPLICATION IS RUNNING ON THE WEB. TWEET METHOD NOT YET IMPLEMENTED.');
    }

    if (tweetResponseData != null) {
      appTweetData = AppTweetData(
        id: tweetResponseData.id,
        text: tweetResponseData.text,
        authorId: tweetResponseData.authorId,
        conversationId: tweetResponseData.conversationId,
        createdAt: tweetResponseData.createdAt ?? DateTime.now(),
        editHistoryTweetIds: tweetResponseData.editHistoryTweetIds,
        coordinates: tweetResponseData.geo?.coordinates?.coordinates ?? [],
        inReplyToUserId: tweetResponseData.inReplyToUserId,
        isPossiblySensitive: tweetResponseData.isPossiblySensitive,
        source: tweetResponseData.source,
        imageUrl: imageUrl,
        linkUrl: urlLink,
        linkToTweet:
            "https://x.com/scapegoatsusa/status/${tweetResponseData.id}",
      );
    }

    return (tweetResponseData, appTweetData);
  }

  static Future<x.TwitterApi> getTwitterApi(
      {required TwitterSecrets twitterSecrets}) async {
    //! You need to get keys and tokens at https://developer.twitter.com
    return x.TwitterApi(
      //! Authentication with OAuth2.0 is the default.
      //!
      //! Note that to use endpoints that require certain user permissions,
      //! such as Tweets and Likes, you need a token issued by OAuth2.0 PKCE.
      //!
      //! The easiest way to achieve authentication with OAuth 2.0 PKCE is
      //! to use [twitter_oauth2_pkce](https://pub.dev/packages/twitter_oauth2_pkce)!
      bearerToken: twitterSecrets.bearerToken ?? "",

      //! Or perhaps you would prefer to use the good old OAuth1.0a method
      //! over the OAuth2.0 PKCE method. Then you can use the following code
      //! to set the OAuth1.0a tokens.
      //!
      //! However, note that some endpoints cannot be used for OAuth 1.0a method
      //! authentication.
      oauthTokens: x.OAuthTokens(
        consumerKey: twitterSecrets.consumerKey,
        consumerSecret: twitterSecrets.consumerSecret,
        accessToken: twitterSecrets.accessToken,
        accessTokenSecret: twitterSecrets.accessTokenSecret,
      ),

      //! Automatic retry is available when a TimeoutException occurs when
      //! communicating with the API.
      retryConfig: x.RetryConfig(
        maxAttempts: 5,
        onExecute: (event) => appLogger.d(
          '[[ TWITTER API ]] Retry after ${event.intervalInSeconds} seconds... [${event.retryCount} times]',
        ),
      ),

      //! The default timeout is 10 seconds.
      timeout: const Duration(seconds: 20),
    );
  }
}

class AppTweetData {
  AppTweetData({
    required this.id,
    required this.text,
    required this.authorId,
    required this.conversationId,
    required this.createdAt,
    required this.editHistoryTweetIds,
    required this.coordinates,
    required this.inReplyToUserId,
    required this.source,
    required this.imageUrl,
    required this.linkUrl,
    required this.linkToTweet,
    required this.isPossiblySensitive,
  });

  final String id;
  final String text;
  final String? authorId;
  final String? conversationId;
  final DateTime? createdAt;
  final List<String>? editHistoryTweetIds;
  final List<double>? coordinates;
  final String? inReplyToUserId;
  final String? source;
  final String? imageUrl;
  final String? linkUrl;
  final String? linkToTweet;
  final bool? isPossiblySensitive;

  Map<String, dynamic> toJson() => {
        "id": id,
        "text": text,
        "author_id": authorId,
        "conversation_id": conversationId,
        "created": createdAt,
        "edit_history": editHistoryTweetIds,
        "coordinates": coordinates,
        "in_reply": inReplyToUserId,
        "source": source,
        "image": imageUrl,
        "link": linkUrl,
        "tweet_link": linkToTweet,
        "sensitive": isPossiblySensitive,
      };

  factory AppTweetData.fromJson(Map<String, dynamic> json) => AppTweetData(
        id: json["id"],
        text: json["text"],
        authorId: json['author_id'],
        conversationId: json['conversation_id'],
        createdAt: json['created'],
        editHistoryTweetIds: json['edit_history'],
        coordinates: json['coordinates'],
        inReplyToUserId: json['in_reply'],
        source: json['source'],
        imageUrl: json["image"],
        linkUrl: json["link"],
        linkToTweet: json["tweet_link"],
        isPossiblySensitive: json['sensitive'],
      );

  List<String> toGSheetsList() => [
        id,
        text,
        authorId ?? "",
        conversationId ?? "",
        createdAt == null
            ? DateTime.now().millisecondsSinceEpoch.toString()
            : createdAt!.millisecondsSinceEpoch.toString(),
        editHistoryTweetIds == null
            ? ""
            : editHistoryTweetIds!.join(TweetDelimiters.standard),
        coordinates == null
            ? ""
            : coordinates!
                .map((x) => x.toString())
                .join(TweetDelimiters.standard),
        inReplyToUserId ?? "",
        source ?? "",
        imageUrl ?? "",
        linkUrl ?? "",
        linkToTweet ?? "",
        isPossiblySensitive == null ? "false" : "true",
      ];

  factory AppTweetData.fromGSheetsList(List<String> tweet) => AppTweetData(
        id: tweet.first,
        text: tweet[1],
        authorId: tweet[2].isEmpty ? null : tweet[2],
        conversationId: tweet[3].isEmpty ? null : tweet[3],
        createdAt: DateTime.fromMillisecondsSinceEpoch(int.parse(tweet[4])),
        editHistoryTweetIds:
            tweet[5].isEmpty ? [] : tweet[5].split(TweetDelimiters.standard),
        coordinates: tweet[6].isEmpty
            ? []
            : tweet[6]
                .split(TweetDelimiters.standard)
                .map((x) => double.parse(x))
                .toList(),
        inReplyToUserId: tweet[7].isEmpty ? null : tweet[7],
        source: tweet[8].isEmpty ? null : tweet[8],
        imageUrl: tweet[9].isEmpty ? null : tweet[9],
        linkUrl: tweet[10].isEmpty ? null : tweet[10],
        linkToTweet: tweet[11].isEmpty ? null : tweet[11],
        isPossiblySensitive: tweet[12].toLowerCase() == "true" ? true : false,
      );

  @override
  toString() => toGSheetsList().join(TweetDelimiters.tweetData);

  factory AppTweetData.fromString(String string) =>
      AppTweetData.fromGSheetsList(string.split(TweetDelimiters.tweetData));
}

class TweetDelimiters {
  static const standard = "<|:|>";
  static const tweetData = "<|tweet_data|>";
}
