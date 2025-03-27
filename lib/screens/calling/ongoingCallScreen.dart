import 'dart:async';
import 'package:cometchat_calls_sdk/helper/cometchatcalls_exception.dart';
import 'package:cometchat_calls_sdk/main/cometchatcalls.dart';
import 'package:flutter/material.dart';
import 'package:cometchat_sdk/cometchat_sdk.dart';

class OngoingCallScreen extends StatefulWidget {
  final String? sessionID;
  final User user;

  const OngoingCallScreen({super.key, required this.sessionID, required this.user});

  @override
  State<OngoingCallScreen> createState() => _OngoingCallScreenState();
}

class _OngoingCallScreenState extends State<OngoingCallScreen> {
  Timer? _callTimer;
  int _callDuration = 0; // in seconds

  @override
  void initState() {
    super.initState();
    _startCallTimer();
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration++;
      });
    });
  }

  void _stopCallTimer() {
    _callTimer?.cancel();
  }

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  void endCall() {
    if (widget.sessionID != null) {
      CometChat.endCall(
        widget.sessionID!,
        onSuccess: (Call call) {
          debugPrint("Call ended successfully");
          CometChatCalls.endSession(
            onSuccess: (String successMsg) {
              debugPrint("Session ended successfully: $successMsg");
              CometChat.clearActiveCall();
              Navigator.pop(context); // Navigate back
            },
            onError: (CometChatCallsException e) {
              debugPrint("Error ending session: ${e.message}");
            },
          );
        },
        onError: (CometChatException e) {
          debugPrint("Error ending call: ${e.message}");
        },
      );
    }

  }

  @override
  void dispose() {
    _stopCallTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
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
                  const SizedBox(height: 10),
                  Text(
                    widget.user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                ],
              ),
              InkWell(
                onTap: (){},
                child: const CircleAvatar(
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
      ),
    );
  }
}
