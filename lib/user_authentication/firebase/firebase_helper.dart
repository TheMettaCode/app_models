import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../shared/constants.dart';

ValueNotifier<UserCredential?> firebaseUserCredentialsNotifier =
    ValueNotifier(null);

class FirebaseHelper {
  static Future<FirebaseApp?> initialize({
    required bool isInit,
    // required ApplicationConfigurationData configData,
    required ApplicationConfigParameters configParameters,
  }) async {
    FirebaseApp? firebaseApp;
    if (kIsWeb || Platform.isAndroid) {
      /// INITIALIZE FIREBASE INTEGRATION
      firebaseApp = isInit
          ? await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform(
              webConfig: configParameters.webConfig,
              androidConfig: configParameters.androidConfig,
            )
              // options: DefaultFirebaseOptions.currentPlatform
              // kIsWeb //  || Platform.isWindows
              //     ? DefaultFirebaseOptions.web
              //     : DefaultFirebaseOptions.currentPlatform,
              )
          : null;

      appLogger.i(
          "[[ FIREBASE INIT ]] App Data: ${firebaseApp?.options.asMap.entries.join("\n")}");
    }
    return firebaseApp;
  }

  static Future<void> signOut() async {
    if (kIsWeb || Platform.isAndroid) {
      await FirebaseAuth.instance
          .signOut()
          .then((_) => firebaseUserCredentialsNotifier.value = null);
    }
  }

  /// GET CREDENTIALS
  static Future<UserCredential?> signIn(
      {required String emailAddress, required String password}) async {
    UserCredential? credentials;
    if (kIsWeb || Platform.isAndroid) {
      appLogger.d(
          "[[ FIREBASE HELPER :: INIT ]] INITIALIZING FIREBASE TOOLS ON ${kIsWeb ? 'WEB' : Platform.operatingSystem.toUpperCase()} PLATFORM...");

      try {
        final userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailAddress,
          password: password,
        );
        appLogger
            .i("Signed in with user account: ${userCredential.user?.uid}.");

        /// SET RETURNED USER CREDENTIAL VALUE
        credentials = userCredential;

        /// SET NOTIFICATION VALUE
        firebaseUserCredentialsNotifier.value = userCredential;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          appLogger.e('No user found for that email.');
        } else if (e.code == 'wrong-password') {
          appLogger.e('Wrong password provided for that user.');
        }
      }

      appLogger.i(
          "[[ FIREBASE HELPER :: SIGN IN ]] RETURNING CREDENTIALS AS => $credentials");
    } else {
      appLogger.i(
          "[[ FIREBASE HELPER :: INIT ]] FIREBASE TOOLS NOT AVAILABLE FOR ${Platform.operatingSystem.toUpperCase()} PLATFORM");
    }
    return credentials;
  }

  static Future<UserCredential?> createNewUser(
      {required String emailAddress, required String password}) async {
    // AppUser? appUser = localDataNotifier.value.appUser;
    UserCredential? credentials;
    if (kIsWeb || Platform.isAndroid) {
      appLogger.d(
          "[[ FIREBASE HELPER :: INIT ]] INITIALIZING FIREBASE TOOLS ON ${kIsWeb ? 'WEB' : Platform.operatingSystem.toUpperCase()} PLATFORM...");

      // if (emailAddress != null && password != null) {
      try {
        final userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailAddress,
          password: password,
        );
        appLogger
            .d("New user created... account: ${userCredential.user?.uid}.");
        credentials = userCredential;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          appLogger.e('The password provided is too weak.');
        } else if (e.code == 'email-already-in-use') {
          appLogger.e('The account already exists for that email.');
        }
      } catch (e) {
        appLogger.e("Unknown error: $e");
      }
    } else {
      appLogger.e(
          "[[ FIREBASE HELPER :: INIT ]] FIREBASE TOOLS NOT AVAILABLE FOR ${Platform.operatingSystem.toUpperCase()} PLATFORM");
      try {
        final userCredential = await FirebaseAuth.instance.signInAnonymously();
        appLogger
            .d("Signed in with user account: ${userCredential.user?.uid}.");
        credentials = userCredential;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          appLogger.e('The password provided is too weak.');
        } else if (e.code == 'email-already-in-use') {
          appLogger.e('The account already exists for that email.');
        }
      } catch (e) {
        appLogger.e("Unknown error: $e");
      }
    }
    return credentials;
  }

  static Future<void> updateUserEmail({required String newEmail}) async {
    if (kIsWeb || Platform.isAndroid) {
      var firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        try {
          appLogger.d(
              "[[ FIREBASE HELPER :: UPDATE USER EMAIL ]] UPDATING USER EMAIL TO $newEmail.");
          await firebaseUser.verifyBeforeUpdateEmail(
            newEmail,
            // ActionCodeSettings(url: ""),
          );
        } catch (e) {
          appLogger.e(
              "[[ FIREBASE HELPER :: UPDATE USER EMAIL ]] ERROR UPDATING USER EMAIL: $e");
        }
      } else {
        appLogger.e(
            "[[ FIREBASE HELPER :: UPDATE USER EMAIL ]] USER IS NOT LOGGED IN TO FIREBASE");
      }
    } else {
      appLogger.e(
          "[[ FIREBASE HELPER :: UPDATE USER EMAIL ]] PLATFORM IS ${Platform.operatingSystem.toUpperCase()} WITH NO FIREBASE METHOD CURRENTLY PROVIDED.");
    }
  }

  static Future<String?> sendPasswordResetEmail({required String email}) async {
    String? errorMessage;
    if (kIsWeb || Platform.isAndroid) {
      var instance = FirebaseAuth.instance;
      try {
        appLogger.d(
            "[[ FIREBASE HELPER :: PASSWORD RESET EMAIL ]] SENDING PASSWORD RESET EMAIL TO $email.");
        await instance.sendPasswordResetEmail(email: email);
      } on FirebaseException catch (e) {
        errorMessage = e.message;
      } catch (e) {
        appLogger.e(
            "[[ FIREBASE HELPER :: PASSWORD RESET EMAIL ]] ERROR SENDING PASSWORD RESET EMAIL: $e");
      }
    } else {
      appLogger.e(
          "[[ FIREBASE HELPER :: PASSWORD RESET EMAIL ]] PLATFORM IS ${Platform.operatingSystem.toUpperCase()} WITH NO FIREBASE METHOD CURRENTLY PROVIDED.");
    }
    return errorMessage;
  }
}

class ApplicationConfigParameters {
  ApplicationConfigParameters(
      {required this.webConfig, required this.androidConfig});

  final ApplicationConfigurationData? webConfig;
  final ApplicationConfigurationData? androidConfig;
}

class ApplicationConfigurationData {
  ApplicationConfigurationData(
      {required this.apiKey,
      required this.appId,
      required this.messagingSenderId,
      required this.projectId,
      required this.storageBucket,
      required this.authDomain,
      required this.measurementId,
      required this.trackingId,
      required this.iosBundleId,
      required this.appGroupId});

  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;
  final String authDomain;
  final String measurementId;
  final String? storageBucket;
  final String? trackingId;
  final String? iosBundleId;
  final String? appGroupId;
}

// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
// show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions currentPlatform({
    required ApplicationConfigurationData? webConfig,
    required ApplicationConfigurationData? androidConfig,
  }) {
    if (kIsWeb && webConfig != null) {
      return FirebaseOptions(
        apiKey: webConfig.apiKey,
        appId: webConfig.appId,
        messagingSenderId: webConfig.messagingSenderId,
        projectId: webConfig.projectId,
        storageBucket: webConfig.storageBucket,
        authDomain: webConfig.authDomain,
        measurementId: webConfig.messagingSenderId,
        trackingId: webConfig.trackingId,
        iosBundleId: webConfig.iosBundleId,
        appGroupId: webConfig.appGroupId,
      );
    } else if (Platform.isAndroid && androidConfig != null) {
      return FirebaseOptions(
        apiKey: androidConfig.apiKey,
        appId: androidConfig.appId,
        messagingSenderId: androidConfig.messagingSenderId,
        projectId: androidConfig.projectId,
        storageBucket: androidConfig.storageBucket,
        authDomain: androidConfig.authDomain,
        measurementId: androidConfig.messagingSenderId,
        trackingId: androidConfig.trackingId,
        iosBundleId: androidConfig.iosBundleId,
        appGroupId: androidConfig.appGroupId,
      );
    }
    switch (defaultTargetPlatform) {
      // case TargetPlatform.android:
      //   return FirebaseOptions(
      //     apiKey: androidConfig.apiKey,
      //     appId: androidConfig.appId,
      //     messagingSenderId: androidConfig.messagingSenderId,
      //     projectId: androidConfig.projectId,
      //     storageBucket: androidConfig.storageBucket,
      //     authDomain: androidConfig.authDomain,
      //     measurementId: androidConfig.messagingSenderId,
      //     trackingId: androidConfig.trackingId,
      //     iosBundleId: androidConfig.iosBundleId,
      //     appGroupId: androidConfig.appGroupId,
      //   );
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
}
