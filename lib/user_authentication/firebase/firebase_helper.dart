import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../shared/constants.dart';

ValueNotifier<UserCredential?> firebaseUserCredentialsNotifier =
    ValueNotifier(null);

class FirebaseHelper {
  static Future<FirebaseApp?> initialize({required bool isInit}) async {
    FirebaseApp? firebaseApp;
    if (kIsWeb || Platform.isAndroid) {
      /// INITIALIZE FIREBASE INTEGRATION
      firebaseApp = isInit
          ? await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform
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
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAaNyJeFTrkDQqbqV3BQp6gfN_cWh8juOs',
    appId: '1:862477657621:web:b0b2d7978e0db1b93c901c',
    messagingSenderId: '862477657621',
    projectId: 'scapegoats-apparel',
    storageBucket: 'scapegoats-apparel.appspot.com',
    authDomain: 'scapegoats-apparel.firebaseapp.com',
    measurementId: 'G-4QQRBH30EE',

    /// Added 9/6
    trackingId: null,
    iosBundleId: null,
    appGroupId: null,
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBag5D35gead9DZz0qYFqnR-nBSFGueNBU',
    appId: '1:862477657621:android:c617ed49c1771c603c901c',
    messagingSenderId: '862477657621',
    projectId: 'scapegoats-apparel',
    storageBucket: 'scapegoats-apparel.appspot.com',

    /// Added 9/6
    authDomain: 'scapegoats-apparel.firebaseapp.com',
    measurementId: 'G-4QQRBH30EE',
    trackingId: null,
    iosBundleId: null,
    appGroupId: null,
  );
}