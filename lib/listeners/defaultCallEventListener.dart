import 'package:cometchat_sdk/cometchat_sdk.dart';
import 'package:cometchat_calls_sdk/cometchat_calls_sdk.dart';
import 'package:flutter/material.dart';
import 'package:my_first_app/main.dart';

class DefaultCallEventListener with CometChatCallsEventsListener {
  final String sessionId;
  final bool isDefaultCall;
  bool isCallEndedByMe = false;

  DefaultCallEventListener({required this.sessionId, required this.isDefaultCall});


  @override
  void onCallEndButtonPressed() {
    debugPrint("End call button pressed");
    if (isDefaultCall) {
      isCallEndedByMe = true;

    } else {
      CometChatCalls.endSession(
        onSuccess: (success) {
          debugPrint("Call session ended successfully 00");
          if (navigatorKey.currentState?.canPop() ?? false) {
            navigatorKey.currentState?.pop();
          }
           CometChat.clearActiveCall();

        },
        onError: (e) {
          debugPrint("Error ending session: ${e.message}");
        },
      );
    }
  }

  @override
  void onCallEnded() {
    debugPrint("Call ended event received");
    if (isDefaultCall) {
      if (isCallEndedByMe) {
        CometChat.endCall(
          sessionId,
          onSuccess: (Call call) {
            debugPrint("Call ended successfully");
            CometChatCalls.endSession(onSuccess: (onSuccess){
              debugPrint("End session successful 111111");
              CometChat.clearActiveCall();
              if (navigatorKey.currentState?.canPop() ?? false) {
                navigatorKey.currentState?.pop();
              }
            }, onError: (e){

            });
          },
          onError: (CometChatException e) {
            debugPrint("Error ending call: ${e.message}");
          },
        );
      } else {

        CometChatCalls.endSession(onSuccess: (onSuccess) {
          debugPrint("End session successful 11");
          CometChat.clearActiveCall();
          // if (navigatorKey.currentState?.canPop() ?? false) {
          //   navigatorKey.currentState?.pop();
          // }
        }, onError: (e) {
          debugPrint("End session failed with error ${e.toString()}");
        },);

      }
    } else {
      // If a group call has ended and only one user remains, end the session

      CometChatCalls.endSession(onSuccess: (onSuccess) {
        debugPrint("End session successful 22");
        CometChat.clearActiveCall();
        if (navigatorKey.currentState?.canPop() ?? false) {
          navigatorKey.currentState?.pop();
        }
      }, onError: (e) {
        debugPrint("End session failed with error ${e.toString()}");
      },);
    }
  }

  @override
  void onAudioModeChanged(List<AudioMode> devices) {
    debugPrint("Audio mode changed: ${devices.map((e) => e.mode).toList()}");
  }

  @override
  void onCallSwitchedToVideo(CallSwitchRequestInfo info) {
    debugPrint("Call switched to video mode");
  }

  @override
  void onError(CometChatCallsException ce) {
    debugPrint("Call error: ${ce.message}");
  }

  @override
  void onRecordingToggled(RTCRecordingInfo info) {
    debugPrint("Call recording toggled");
  }

  @override
  void onUserJoined(RTCUser user) {
    debugPrint("${user.uid} joined the call");
  }

  @override
  void onUserLeft(RTCUser user) {
    debugPrint("${user.uid} left the call");
  }

  @override
  void onUserListChanged(List<RTCUser> users) {
    debugPrint("User list updated: ${users.map((e) => e.uid).toList()}");
  }

  @override
  void onUserMuted(RTCMutedUser muteObj) {
    debugPrint("User muted: ${muteObj.mutedBy}");
  }
}
