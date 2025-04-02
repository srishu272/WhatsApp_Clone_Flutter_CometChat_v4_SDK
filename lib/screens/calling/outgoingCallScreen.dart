import 'package:cometchat_sdk/cometchat_sdk.dart';
import 'package:cometchat_calls_sdk/cometchat_calls_sdk.dart';
import 'package:flutter/material.dart';
import 'package:my_first_app/screens/calling/ongoingCallScreen.dart';

import '../../listeners/callListerner.dart';

class OutgoingCallScreen extends StatefulWidget {
  const OutgoingCallScreen({
    super.key,
    required this.conversation,
    required this.callType,
  });

  final Conversation conversation;
  final String callType;

  @override
  State<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends State<OutgoingCallScreen> {
  User? user;
  String? sessionID;

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

  void startCall() {

    String callType = widget.callType;
    String receiverUid;
    String receiverType;

    if (widget.conversation.conversationWith is User) {
      receiverUid = (widget.conversation.conversationWith as User).uid;
      receiverType = "user";
    } else if (widget.conversation.conversationWith is Group) {
      receiverUid = (widget.conversation.conversationWith as Group).guid;
      receiverType = "group";
    } else {
      debugPrint("Invalid receiver type.");
      return;
    }

    Call call = Call(
      receiverType: receiverType,
      type: callType,
      receiverUid: receiverUid,
    );

    CometChat.initiateCall(
      call,
      onSuccess: (Call call) {
        debugPrint("Call is Initiated");
        setState(() {
          sessionID = call.sessionId;
        });
      },
      onError: (CometChatException e) {
        debugPrint("Call Initiation failed : $e");
      },
    );
  }

  void cancelCall() {
    if (sessionID != null) {
      CometChat.rejectCall(
        sessionID!,
        "cancelled",
        onSuccess: (Call call) {
          debugPrint("Call cancelled successfully");
          Navigator.pop(context);
        },
        onError: (CometChatException e) {
          debugPrint("Call cancellation failed: ${e.message}");
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();
    initializeCometChatCalls();
    startCall();
    if (widget.conversation.conversationWith is User) {
      user = widget.conversation.conversationWith as User;
    }
  }

  @override
  void dispose() {
    super.dispose();
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
                        user?.avatar != null
                            ? NetworkImage(user!.avatar!)
                            : null,
                    radius: 80,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Calling..",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  cancelCall();
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
      ),
    );
  }
}
