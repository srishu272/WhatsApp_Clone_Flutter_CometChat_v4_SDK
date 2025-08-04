import 'dart:convert';

import 'package:cometchat_calls_sdk/builder/call_settings.dart';
import 'package:cometchat_calls_sdk/helper/cometchatcalls_exception.dart';
import 'package:cometchat_calls_sdk/main/cometchatcalls.dart';
import 'package:cometchat_calls_sdk/model/generate_token.dart';
import 'package:cometchat_sdk/exception/cometchat_exception.dart';
import 'package:cometchat_sdk/main/cometchat.dart';
import 'package:cometchat_sdk/models/call.dart';
import 'package:cometchat_sdk/utils/constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:my_first_app/main.dart';

import '../listeners/defaultCallEventListener.dart';
import '../screens/calling/ongoingCallScreen.dart';
import 'localNotificationService.dart';

/// Background message handler (must be a top-level function)
@pragma('vm:entry-point')
Future<void> backgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("🔕 Srishu Background message: ${message.data}");

  PushNotificationsService.handleNotification(message.data);
}

class PushNotificationsService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  Future<void> init() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("📬 Foreground Notification: ${message.data}");
      final notificationData = message.data;

      if (message.notification != null) {
        handleNotification(notificationData);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("📲 Notification tapped: ${message.data}");
      final notificationData = message.data;
      handleNotification(notificationData);
    });

    // When the app was terminated and launched via a notification
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint("🚀 App launched via notification: ${initialMessage.data}");
      handleNotification(initialMessage.data);
    }
  }

  static Future<void> handleNotification(
    Map<String, dynamic> notificationData,
  ) async {
    final notificationType = notificationData['type'];

    if (notificationType == "chat") {
      final senderName = notificationData['senderName'];
      final senderId = notificationData['sender'];
      final notificationTitle = notificationData['title'];
      final notificationBody = notificationData['body'];

      debugPrint("Chat notification received");
      debugPrint("Title: $notificationTitle");
      debugPrint("Body: $notificationBody");

      LocalNotificationService.showNotification(
        title: notificationData['title'],
        body: notificationData['body'],
        payload: jsonEncode(notificationData),
      );
    } else if (notificationType == "call") {
      debugPrint("Call notification received");
      showIncomingCallNotification(notificationData);
    }
  }

  static Future<void> showIncomingCallNotification(
    Map<String, dynamic> notificationData,
  ) async {
    final params = CallKitParams.fromJson({
      'id': notificationData['sessionId'],
      'nameCaller': notificationData['senderName'] ?? "Unknown",
      'avatar': notificationData['senderAvatar'] ?? '',
      // 'handle': notificationData['callerId'] ?? '',
      'type': notificationData['callType'] == 'video' ? 1 : 0,
      // 0 = audio, 1 = video
      // 'duration': 30000, // (optional) auto-decline after 30 seconds
      'textAccept': 'Accept',
      'textDecline': 'Decline',
      'textMissedCall': 'Missed Call',
      'textCallback': 'Call Back',
      // 'extra': <String, dynamic>{'customData': 'extra info if needed'},
      'android': <String, dynamic>{
        'isCustomNotification': true,
        'isShowLogo': false,
        'ringtonePath': 'system_ringtone_default',
        'backgroundColor': '#0955fa',
        'backgroundUrl': '',
        'actionColor': '#4CAF50',
      },
      'ios': <String, dynamic>{
        'handleType': 'generic',
        'supportsVideo': true,
        'maximumCallGroups': 2,
        'maximumCallsPerCallGroup': 1,
        'audioSessionMode': 'default',
        'audioSessionActive': true,
        'supportsDTMF': true,
        'supportsHolding': true,
        'supportsGrouping': false,
        'supportsUngrouping': false,
        'ringtonePath': 'system_ringtone_default',
      },
    });

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  void acceptCall(String sessionId, String callType) {
    CometChat.acceptCall(
      sessionId,
      onSuccess: (Call call) async {
        debugPrint("Call accepted");

        String? userAuthToken =
            await CometChat.getUserAuthToken(); //Logged in user auth token

        CometChatCalls.generateToken(
          call.sessionId!,
          userAuthToken!,
          onSuccess: (GenerateToken generateToken) {
            debugPrint("Success generate token: ${generateToken.token}");
            DefaultCallEventListener ongoingCallEventListener =
                DefaultCallEventListener(
                  sessionId: call.sessionId!,
                  isDefaultCall:
                      call.receiverType == CometChatReceiverType.user,
                );
            CallSettings callSettings =
                (CallSettingsBuilder()
                      ..setAudioOnlyCall = callType == "audio" ? true : false
                      ..listener = ongoingCallEventListener)
                    .build();

            CometChatCalls.startSession(
              generateToken.token!,
              callSettings,
              onSuccess: (Widget? callingWidget) {
                debugPrint("Success Start Session: ${call.sessionId!}");
                debugPrint("Contextttt --- ${navigatorKey.currentContext}");

                if (navigatorKey.currentContext!.mounted) {
                  debugPrint("navigator key is not null");
                  /*Navigator.push(
                    navigatorKey.currentContext!,
                    MaterialPageRoute(
                      builder:
                          (context) => CometChatOngoingCall(
                            callSettingsBuilder:
                                CallSettingsBuilder()
                                  ..setAudioOnlyCall =
                                      callType == "audio" ? true : false
                                  ..listener = ongoingCallEventListener,
                            sessionId: sessionId,
                          ),
                    ),
                  );*/
                  Navigator.push(
                    navigatorKey.currentContext!,
                    MaterialPageRoute(
                      builder:
                          (context) => OngoingCallScreen(
                            callingWidget: callingWidget,
                            sessionId: sessionId,
                            isDefaultCall:
                                call.receiverType == CometChatReceiverType.user,
                          ),
                    ),
                  );
                }
              },
              onError: (CometChatCallsException e) {
                debugPrint("Error: $e");
              },
            );
          },
          onError: (CometChatCallsException e) {
            debugPrint("Error: $e");
          },
        );
      },
      onError: (CometChatException e) {
        debugPrint("Call acceptance failed: ${e.message}");
      },
    );
  }

  void rejectCall(String sessionId) {
    CometChat.rejectCall(
      sessionId,
      "rejected",
      onSuccess: (Call call) {
        debugPrint("Call rejected successfully");
        navigatorKey.currentState?.pop();
      },
      onError: (CometChatException e) {
        debugPrint("Call rejection failed: ${e.message}");
      },
    );
  }

  void setupCallKitListeners() {
    FlutterCallkitIncoming.onEvent.listen((event) async {
      debugPrint('📞 CallKit event: ${event!.event}');

      switch (event.event) {
        case Event.actionCallAccept:
          debugPrint('User accepted the call.');
          debugPrint('Session ID: ${event.body['id']}');
          // Give time for app to come into foreground
          /*Future.delayed(Duration(milliseconds: 100), () {*/
            acceptCall(
              event.body['id'],
              event.body['type'] == 0 ? "audio" : "video",
            );
          break;
        case Event.actionCallDecline:
          debugPrint('User declined the call.${event.body['id']}');
          rejectCall(event.body['id']);
          break;
        case Event.actionCallEnded:
          debugPrint('Call ended.');
          await FlutterCallkitIncoming.endCall(event.body['id']);
          break;
        default:
          break;
      }
    });
  }
}
