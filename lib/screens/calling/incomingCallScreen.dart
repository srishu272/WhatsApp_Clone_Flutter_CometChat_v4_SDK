import 'package:cometchat_calls_sdk/builder/call_app_settings_request.dart';
import 'package:cometchat_calls_sdk/builder/call_settings.dart';
import 'package:cometchat_calls_sdk/constants/cometchatcalls_constants.dart';
import 'package:cometchat_calls_sdk/helper/cometchatcalls_exception.dart';
import 'package:cometchat_calls_sdk/main/cometchatcalls.dart';
import 'package:cometchat_calls_sdk/model/generate_token.dart';
import 'package:cometchat_sdk/exception/cometchat_exception.dart';
import 'package:cometchat_sdk/main/cometchat.dart';
import 'package:cometchat_sdk/models/call.dart';
import 'package:cometchat_sdk/models/conversation.dart';
import 'package:cometchat_sdk/models/user.dart';
import 'package:cometchat_sdk/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:my_first_app/listeners/callListerner.dart';
import 'package:my_first_app/screens/calling/ongoingCallScreen.dart';

import '../../listeners/ongoingCallEventListener.dart';

class IncomingCallScreen extends StatefulWidget {
  const IncomingCallScreen({
    super.key,
    required this.user,
    required this.sessionID,
    required this.callType,
  });

  final User user;
  final String sessionID;
  final String callType;

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  // User? user;

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

  @override
  void initState() {
    super.initState();

    initializeCometChatCalls();
  }

  void acceptCall(String sessionId) {
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
            OngoingCallEventListener ongoingCallEventListener =
                OngoingCallEventListener(
                  sessionId: call.sessionId!,
                  isDefaultCall:
                      call.receiverType == CometChatReceiverType.user,
                );
            CallSettings callSettings =
                (CallSettingsBuilder()
                      ..setAudioOnlyCall =
                          widget.callType == "audio" ? true : false
                      ..listener = ongoingCallEventListener)
                    .build();

            CometChatCalls.startSession(
              generateToken.token!,
              callSettings,
              onSuccess: (Widget? callingWidget) {
                debugPrint("Success Start Session: ${call.sessionId!}");
                // Force enable speaker mode
                CometChatCalls.setAudioMode(
                  "AUDIO_MODE_SPEAKER",
                  onSuccess: (success) {
                    debugPrint("Audio mode set to Speaker");
                  },
                  onError: (error) {
                    debugPrint("Error setting audio mode: $error");
                  },
                );

                // Unmute the microphone
                CometChatCalls.muteAudio(
                  false,
                  onSuccess: (success) {
                    debugPrint("Microphone unmuted");
                  },
                  onError: (error) {
                    debugPrint("Error unmuting microphone: $error");
                  },
                );
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder:
                        (context) => OngoingCallScreen(
                          callingWidget: callingWidget,
                          sessionId: widget.sessionID,
                          isDefaultCall:
                              call.receiverType == CometChatReceiverType.user,
                          isCaller: false,
                        ),
                  ),
                );
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
        Navigator.pop(context);
      },
      onError: (CometChatException e) {
        debugPrint("Call rejection failed: ${e.message}");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/8c98994518b575bfd8c949e91d20548b.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 200, bottom: 250),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundImage:
                        widget.user.avatar != null
                            ? NetworkImage(widget.user.avatar!)
                            : null,
                    radius: 80,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "${widget.user.name} Calling..",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 100, right: 100),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        acceptCall(widget.sessionID);
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.green,
                        radius: 35,
                        child: Icon(
                          Icons.call_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        rejectCall(widget.sessionID);
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.redAccent,
                        radius: 35,
                        child: Icon(
                          Icons.call_end_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
