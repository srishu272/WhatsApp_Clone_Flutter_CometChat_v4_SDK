import 'dart:convert';

import 'package:cometchat_calls_sdk/builder/call_app_settings_request.dart';
import 'package:cometchat_calls_sdk/helper/cometchatcalls_exception.dart';
import 'package:cometchat_calls_sdk/main/cometchatcalls.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cometchat_sdk/cometchat_sdk.dart';
import 'package:my_first_app/screens/chatScreen.dart';
import 'package:my_first_app/screens/homeScreen.dart';
import 'package:my_first_app/screens/loginScreen.dart';
import 'package:my_first_app/services/localNotificationService.dart';
import 'package:my_first_app/services/pushNotificationsService.dart';

import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void initializeCometChat() {
  String region = "IN";
  String appId = "27153765695d4ed3";

  AppSettings appSettings =
      (AppSettingsBuilder()
            ..subscriptionType = CometChatSubscriptionType.allUsers
            ..region = region
            ..adminHost =
                "" //optional
            ..clientHost =
                "" //optional
            ..autoEstablishSocketConnection = true)
          .build();

  CometChat.init(
    appId,
    appSettings,
    onSuccess: (String successMessage) {
      debugPrint("Initialization completed successfully  $successMessage");
    },
    onError: (CometChatException excep) {
      debugPrint("Initialization failed with exception: ${excep.message}");
    },
  );
}

void initializeCometChatCalls() {
  CallAppSettings callAppSettings =
      (CallAppSettingBuilder()
            ..appId = "27153765695d4ed3"
            ..region = "IN")
          .build();

  CometChatCalls.init(
    callAppSettings,
    onSuccess: (String successMessage) {
      debugPrint("Initialization completed successfully  $successMessage");
    },
    onError: (CometChatCallsException e) {
      debugPrint("Initialization failed with exception: ${e.message}");
    },
  );
}

Future<void> initializeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //Initializing Firebase
  initializeFirebase();

  LocalNotificationService.initialize(
    onNotificationClick: (payload) {
      debugPrint("🔔 Notification tappedin mainnnnn: $payload-----there it is");
      if (payload == null) return;
      Map<String, dynamic> data = jsonDecode(payload);

      var conversationWith;
      if (data["receiverType"] == "user") {
        conversationWith = User(
          uid: data[""],
          name: data["receiverName"],
          avatar: data["receiverAvatar"],
        );
      } else if (data["receiverType"] == "group") {
        conversationWith = Group(
          guid: data["receiver"],
          name: data["receiverName"],
          icon: data["receiverAvatar"],
          type: CometChatGroupType.public,
        );
      } else {
        return;
      }

      Conversation conversation = Conversation(
        conversationId: data["conversationId"],
        conversationType: data["receiverType"],
        conversationWith: conversationWith,
        unreadMessageCount: 0,
        lastMessage: null,
      );

      Navigator.of(navigatorKey.currentContext!).push(
        MaterialPageRoute(
          builder:
              (context) => Chatscreen(
                conversation: conversation,
                onNewMessageSent: (BaseMessage newMessage) {
                  debugPrint(
                    "New message sent from notification open: $newMessage",
                  );
                },
              ),
        ),
      );
    },
  );
  FirebaseMessaging.onBackgroundMessage(backgroundHandler);

  //Initializing the listeners for the incoming call kit
  // PushNotificationsService().setupCallKitListeners();

  initializeCometChat();
  initializeCometChatCalls();

  var user = await CometChat.getLoggedInUser();
  CometChat.getUnreadMessageCount(
    onSuccess: (success) {
      debugPrint("Unread message count: $success");
    },
  );

  runApp(MyApp(initialScreen: user != null ? Homescreen() : Loginscreen()));
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;

  const MyApp({super.key, required this.initialScreen});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: initialScreen,
    );
  }
}
