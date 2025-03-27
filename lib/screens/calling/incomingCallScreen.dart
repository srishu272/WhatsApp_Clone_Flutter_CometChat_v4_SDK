import 'package:cometchat_sdk/exception/cometchat_exception.dart';
import 'package:cometchat_sdk/main/cometchat.dart';
import 'package:cometchat_sdk/models/call.dart';
import 'package:cometchat_sdk/models/conversation.dart';
import 'package:cometchat_sdk/models/user.dart';
import 'package:flutter/material.dart';
import 'package:my_first_app/listeners/callListerner.dart';
import 'package:my_first_app/screens/calling/ongoingCallScreen.dart';

class IncomingCallScreen extends StatefulWidget {
  const IncomingCallScreen({
    super.key,
    required this.user,
    required this.sessionID,
  });

  final User user;
  final String sessionID;

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  // User? user;

  @override
  void initState() {
    super.initState();
  }

  void acceptCall(String sessionId) {
    CometChat.acceptCall(
      sessionId,
      onSuccess: (Call call) {
        debugPrint("Call accepted");
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
