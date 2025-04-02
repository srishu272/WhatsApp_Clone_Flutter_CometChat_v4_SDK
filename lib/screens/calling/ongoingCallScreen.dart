import 'package:cometchat_calls_sdk/main/cometchatcalls.dart';
import 'package:cometchat_sdk/main/cometchat.dart';
import 'package:flutter/material.dart';
import 'package:my_first_app/listeners/ongoingCallEventListener.dart';

class OngoingCallScreen extends StatefulWidget {
  final Widget? callingWidget;
  final String sessionId;
  final bool isCaller;
  final bool isDefaultCall;

  const OngoingCallScreen({
    super.key,
    required this.callingWidget,
    required this.sessionId,
    required this.isCaller,
    required this.isDefaultCall,
  });

  @override
  State<OngoingCallScreen> createState() => _OngoingCallScreenState();
}

class _OngoingCallScreenState extends State<OngoingCallScreen> {
  @override
  void initState() {
    super.initState();
    CometChatCalls.addCallsEventListeners(
      "ONGOING_CALL_LISTENER",
      OngoingCallEventListener(sessionId: widget.sessionId,isDefaultCall: widget.isDefaultCall),
    );
  }

  @override
  void dispose() {
    super.dispose();
    CometChatCalls.removeCallsEventListeners("ONGOING_CALL_LISTENER");
  }

  @override
  Widget build(BuildContext context) {
    return widget.callingWidget!;
  }
}
