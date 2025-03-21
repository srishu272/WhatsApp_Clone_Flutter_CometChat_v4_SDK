import 'package:cometchat_sdk/builders/messages_request.dart';
import 'package:cometchat_sdk/exception/cometchat_exception.dart';
import 'package:cometchat_sdk/main/cometchat.dart';
import 'package:cometchat_sdk/models/base_message.dart';
import 'package:cometchat_sdk/models/media_message.dart';
import 'package:cometchat_sdk/models/text_message.dart';
import 'package:cometchat_sdk/models/user.dart';
import 'package:cometchat_sdk/utils/constants.dart';
import 'package:flutter/material.dart';

class ThreadScreen extends StatefulWidget {
  final BaseMessage parentMessage;
  final bool isMe;
  final bool isGroupChat;
  final String formatedTimestamp;
  final Widget getMessageStatusIcon;

  ThreadScreen({
    required this.parentMessage,
    required this.isMe,
    required this.isGroupChat,
    required this.formatedTimestamp,
    required this.getMessageStatusIcon,
  });

  @override
  _ThreadScreenState createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  List<BaseMessage> threadMessages = [];
  TextEditingController messageController = TextEditingController();

  String? loggedInUserId;

  @override
  void initState() {
    super.initState();
    fetchLoggedInUser();
    fetchThreadMessages();
  }

  Future<void> fetchLoggedInUser() async {
    try {
      User? user = await CometChat.getLoggedInUser();
      if (user != null) {
        setState(() {
          loggedInUserId = user.uid;
        });
      }
    } catch (e) {
      debugPrint("Error retrieving logged-in user: $e");
    }
  }

  void fetchThreadMessages() {
    MessagesRequest messageRequest =
        (MessagesRequestBuilder()
              ..uid = widget.parentMessage.sender?.uid
              ..parentMessageId = widget.parentMessage.id
              ..limit = 50)
            .build();

    messageRequest.fetchPrevious(
      onSuccess: (List<BaseMessage> messages) {
        debugPrint("Thread messages fetchedddd ----- ${threadMessages.length}");
        setState(() {
          threadMessages = messages;
        });
      },
      onError: (CometChatException e) {
        debugPrint("Fetching thread messages failed: ${e.message}");
      },
    );
  }

  void sendThreadMessage() {
    if (messageController.text.isNotEmpty) {
      String? receiverUid;
      String receiverType = widget.parentMessage.receiverType; // User or Group

      // Determine receiverUid dynamically
      if (receiverType == CometChatReceiverType.user) {
        // If it's a one-on-one chat, ensure the receiver is not the sender
        receiverUid = /*widget.parentMessage.receiverUid;*/
            widget.parentMessage.sender?.uid == loggedInUserId
                ? widget.parentMessage.receiverUid
                : widget.parentMessage.sender?.uid;
      } else {
        // If it's a group chat, use the group GUID
        receiverUid = widget.parentMessage.receiverUid;
      }

      debugPrint("$receiverUid");

      TextMessage textMessage = TextMessage(
        text: messageController.text,
        receiverUid: receiverUid!,
        receiverType: CometChatConversationType.user,
        type: CometChatMessageType.text,
      );
      textMessage.parentMessageId = widget.parentMessage.id;
      debugPrint("${widget.parentMessage.id}");

      CometChat.sendMessage(
        textMessage,
        onSuccess: (TextMessage message) {
          setState(() {
            threadMessages.add(message);
          });
          messageController.clear();
        },
        onError: (CometChatException e) {
          debugPrint("Message sending failed: $e");
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Thread")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Parent Message
            widget.parentMessage is TextMessage
                ? TextMessageWidget(
                  isMe: false,
                  isGroupChat: false,
                  message: widget.parentMessage as TextMessage,
                  formatedTimestamp: widget.formatedTimestamp,
                  getMessageStatusIcon: widget.getMessageStatusIcon,
                )
                : /*MediaMessageWidget(
                  isMe: false,
                  isGroupChat: false,
                  message: widget.parentMessage as MediaMessage,
                  formattedTimestamp: widget.formatedTimestamp,
                  getMessageStatusIcon: widget.getMessageStatusIcon,
                )*/ SizedBox(),
            SizedBox(height: 10),
            Text(
              "${threadMessages.length} Replies",
              style: TextStyle(fontSize: 12),
            ),
            Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: threadMessages.length,
                itemBuilder: (context, index) {
                  var message = threadMessages[index];
                  return message is TextMessage
                      ? TextMessageWidget(
                        isMe: true,
                        isGroupChat: false,
                        message: message,
                        formatedTimestamp: widget.formatedTimestamp,
                        getMessageStatusIcon: widget.getMessageStatusIcon,
                      )
                      : SizedBox();
                },
              ),
            ),
            // Message Input Field
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: messageController,
                      decoration: InputDecoration(
                        // suffixIcon: IconButton(
                        //   onPressed: () {
                        //     sendMediaMessage(
                        //       widget.conversation.conversationWith is Group?,
                        //     );
                        //   },
                        //   icon: Icon(Icons.attach_file_rounded),
                        // ),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        hintText: "Enter Your Text....",
                      ),
                    ),
                  ),
                  SizedBox(width: 15),
                  InkWell(
                    onTap: () {
                      if (messageController.text.isNotEmpty) {
                        print("Msg not empty");
                        sendThreadMessage();
                      } else {
                        print("Msg Empty");
                      }
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.send, color: Colors.teal),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TextMessageWidget extends StatelessWidget {
  const TextMessageWidget({
    super.key,
    required this.isMe,
    required this.isGroupChat,
    required this.message,
    required this.formatedTimestamp,
    required this.getMessageStatusIcon,
  });

  final bool isMe;
  final bool isGroupChat;
  final TextMessage message;
  final String formatedTimestamp;
  final Widget getMessageStatusIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isMe ? Colors.teal.shade800 : Colors.grey.shade300,
            borderRadius:
                isMe
                    ? BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.zero,
                    )
                    : BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                      bottomLeft: Radius.zero,
                      bottomRight: Radius.circular(10),
                    ),
          ),
          child: Column(
            children: [
              if (isGroupChat && !isMe)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundImage:
                          message.sender?.avatar != null
                              ? NetworkImage(message.sender!.avatar!)
                              : null,
                      backgroundColor: Colors.teal,
                      child:
                          message.sender?.avatar == null
                              ? Icon(Icons.person, color: Colors.white)
                              : null,
                    ),
                    SizedBox(width: 10),
                    Text(
                      message.sender?.name ?? "Unknown",
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 17,
                      color: isMe ? Colors.white : Colors.black,
                      fontStyle:
                          message.text == "This message was deleted"
                              ? FontStyle.italic
                              : FontStyle.normal,
                    ),
                  ),
                  SizedBox(height: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatedTimestamp,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      SizedBox(width: 5),
                      isMe ? getMessageStatusIcon : SizedBox(),
                    ],
                  ),
                  SizedBox(height: 2),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
