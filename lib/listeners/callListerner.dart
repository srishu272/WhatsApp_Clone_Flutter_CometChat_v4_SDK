import 'package:cometchat_sdk/handlers/call_listener.dart';
import 'package:cometchat_sdk/main/cometchat.dart';
import 'package:cometchat_sdk/models/call.dart';
import 'package:flutter/material.dart';

class CallEventListener with CallListener {
  final String listenerId;
  final Function(Call call) onIncomingCallReceivedFunc;
  final Function(Call call) onIncomingCallCancelledFunc;
  final Function(Call call) onOutgoingCallAcceptedFunc;
  final Function(Call call) onOutgoingCallRejectedFunc;
  final Function(Call call) onCallEndedMessageReceivedFunc;

  CallEventListener({
    required this.listenerId,
    required this.onIncomingCallReceivedFunc,
    required this.onIncomingCallCancelledFunc,
    required this.onOutgoingCallAcceptedFunc,
    required this.onOutgoingCallRejectedFunc,
    required this.onCallEndedMessageReceivedFunc,
  });

  // void addListener() {
  //   CometChat.addCallListener(listenerId, this);
  // }
  //
  // void removeListener() {
  //   CometChat.removeCallListener(listenerId);
  // }

  @override
  void onIncomingCallCancelled(Call call) {
    debugPrint("Incoming call cancelled");
    onIncomingCallCancelledFunc(call);
  }

  @override
  void onIncomingCallReceived(Call call) {
    debugPrint("Incoming call received");
    onIncomingCallReceivedFunc(call);
  }

  @override
  void onOutgoingCallAccepted(Call call) {
    debugPrint("Outgoing call accepted");
    onOutgoingCallAcceptedFunc(call);
  }

  @override
  void onOutgoingCallRejected(Call call) {
    debugPrint("Outgoing call rejected");
    onOutgoingCallRejectedFunc(call);
  }

  @override
  void onCallEndedMessageReceived(Call call) {
    debugPrint("Call ended");
    onCallEndedMessageReceivedFunc(call);
  }
}
