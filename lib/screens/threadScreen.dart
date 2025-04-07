/*
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
        receiverUid =
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
                ? Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.teal.shade100,
                borderRadius:
                BorderRadius.circular(10)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.parentMessage is TextMessage? widget.parentMessage: "",
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.black,
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
            )
                : */
/*MediaMessageWidget(
                  isMe: false,
                  isGroupChat: false,
                  message: widget.parentMessage as MediaMessage,
                  formattedTimestamp: widget.formatedTimestamp,
                  getMessageStatusIcon: widget.getMessageStatusIcon,
                )*/ /*
 SizedBox(),
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
*/

import 'package:cometchat_sdk/builders/messages_request.dart';
import 'package:cometchat_sdk/exception/cometchat_exception.dart';
import 'package:cometchat_sdk/helpers/cometchat_helper.dart';
import 'package:cometchat_sdk/main/cometchat.dart';
import 'package:cometchat_sdk/models/base_message.dart';
import 'package:cometchat_sdk/models/reaction.dart';
import 'package:cometchat_sdk/models/reaction_count.dart';
import 'package:cometchat_sdk/models/text_message.dart';
import 'package:cometchat_sdk/models/user.dart';
import 'package:cometchat_sdk/notification/models/reaction_event.dart';
import 'package:cometchat_sdk/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:my_first_app/listeners/threadMessageListener.dart';

class ThreadScreen extends StatefulWidget {
  final BaseMessage parentMessage;
  final bool isMe;
  final bool isGroupChat;
  final String formatedTimestamp;
  final Widget getMessageStatusIcon;

  ThreadScreen({
    required this.parentMessage,
    required this.formatedTimestamp,
    required this.isMe,
    required this.isGroupChat,
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

    CometChat.addMessageListener(
        "THREAD_MESSAGE_LISTENER_${widget.parentMessage.id}",
        ThreadMessageListener(activeParentMessageId: widget.parentMessage.id,
            onMessageReceived: (BaseMessage message){
              setState(() {
                threadMessages.insert(threadMessages.length, message);
              });
            },
          onMessageEditedFunc: (BaseMessage editedMessage){
            setState(() {
              int index = threadMessages.indexWhere((msg) => msg.id == editedMessage.id);
              if (index != -1) {
                threadMessages[index] = editedMessage; // Update the message
              }
            });
          },
          onMessageDeletedFunc: (BaseMessage deletedMessage){
            setState(() {
              int index = threadMessages.indexWhere((msg) => msg.id == deletedMessage.id);
              if (index != -1) {
                threadMessages[index] = TextMessage(
                  id: deletedMessage.id,
                  text: "This message was deleted",
                  sender: threadMessages[index].sender,
                  receiverUid: threadMessages[index].receiverUid,
                  receiverType: threadMessages[index].receiverType,
                  type: CometChatMessageType.text,
                  sentAt: threadMessages[index].sentAt,
                );
              }
            });
          },
          onMessageReactionAddedFunc: (ReactionEvent reactionEvent) {
            debugPrint(
              "onMessageReactionAddition called MessageID: ${reactionEvent.reaction!.messageId}",
            );
            updateMessageReactions(
              reactionEvent.reaction!.messageId!,
              reactionEvent,
              true,
            );
          },
          onMessageReactionRemovalFunc: (ReactionEvent reactionEvent) {
            debugPrint("onMessageReactionRemoval calledd");
            updateMessageReactions(
              reactionEvent.reaction!.messageId!,
              reactionEvent,
              false,
            );
          },
        ));
  }

  Future<void> fetchLoggedInUser() async {
    try {
      User? user = await CometChat.getLoggedInUser();
      setState(() {
        loggedInUserId = user?.uid;
      });
    } catch (e) {
      debugPrint("Error retrieving logged-in user: $e");
    }
  }

  void markMessagesAsRead(List<BaseMessage> msgs) {
    for (var message in msgs) {
      if (message.sender?.uid != loggedInUserId) {
        CometChat.markAsRead(
          message,
          onSuccess: (_) {
            debugPrint("Message marked as read: ${message.id}");
            setState(() {});
          },
          onError: (CometChatException e) {
            debugPrint("Error marking message as read");
          },
        );
      }
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
          threadMessages = messages.map((msg) {
            if (msg.deletedAt != null) {
              return TextMessage(
                id: msg.id,
                text: "This message was deleted",
                sender: msg.sender,
                receiverUid: msg.receiverUid,
                receiverType: msg.receiverType,
                type: CometChatMessageType.text,
                sentAt: msg.sentAt,
              );
            }
            return msg;
          }).toList();
        });
        markMessagesAsRead(messages);
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
        receiverUid =
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

  Widget getMessageStatusIcon(BaseMessage message) {
    if (message.readAt != null) {
      return Icon(Icons.done_all, color: Colors.blue);
    } else if (message.deliveredAt != null) {
      return Icon(Icons.done_all, color: Colors.grey);
    } else {
      return Icon(Icons.done, color: Colors.grey);
    }
  }

  String formatTimestamp(DateTime date) {
    DateTime now = DateTime.now();

    // If the message is from today, showing only the time (HH:mm)
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return "Yesterday";
    }
    // If the message is from a different day, showing date
    else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }

  void addReaction(int messageId, String reaction) {
    CometChat.addReaction(
      messageId,
      reaction,
      onSuccess: (message) {
        debugPrint("Successfully Reaction added");
        setState(() {
          int index = threadMessages.indexWhere((msg) => msg.id == message.id);
          if (index != -1) {
            threadMessages[index] = message;
          }
        });
      },
      onError: (message) {
        debugPrint("Error in Reaction added");
      },
    );
  }

  void removeReaction(int messageId, String reaction) {
    CometChat.removeReaction(
      messageId,
      reaction,
      onSuccess: (message) {
        debugPrint("Successfully Reaction removed");
        setState(() {
          int index = threadMessages.indexWhere((msg) => msg.id == message.id);
          if (index != -1) {
            threadMessages[index] = message;
          }
        });
      },
      onError: (message) {
        debugPrint("Error in Reaction removal");
      },
    );
  }

  void toggleReaction(int messageId, String newReaction) {
    int index = threadMessages.indexWhere((msg) => msg.id == messageId);
    if (index == -1) return; // Message not found

    BaseMessage message = threadMessages[index];

    // Find the reaction already added by the logged-in user
    String? existingReaction;
    for (ReactionCount reactionCount in message.reactions) {
      if (reactionCount.reactedByMe!) {
        existingReaction = reactionCount.reaction;
        break;
      }
    }

    if (existingReaction == newReaction) {
      // If clicking the same reaction, remove it
      removeReaction(messageId, newReaction);
    } else {
      // If a different reaction exists, remove it first
      if (existingReaction != null) {
        CometChat.removeReaction(
          messageId,
          existingReaction,
          onSuccess: (updatedMessage) {
            debugPrint("Previous reaction removed");

            // Now add the new reaction
            addReaction(messageId, newReaction);
          },
          onError: (error) {
            debugPrint("Error removing previous reaction: ${error.message}");
          },
        );
      } else {
        // No existing reaction, just add the new one
        addReaction(messageId, newReaction);
      }
    }
  }

  void updateMessageReactions(
      int messageId,
      ReactionEvent reactionEvent,
      bool isAddReaction,
      ) async
  {
    int index = threadMessages.indexWhere((msg) => msg.id == messageId);

    if (index == -1) {
      return; // Message not found
    }

    try {
      if (reactionEvent.reaction == null) {
        debugPrint("Reaction is null in ReactionEvent");
        return;
      }

      // Extract the Reaction object from the event
      Reaction reaction = reactionEvent.reaction!;

      // Update the message with the latest reaction info
      BaseMessage? updatedMessage =
      await CometChatHelper.updateMessageWithReactionInfo(
        threadMessages[index], // Existing message
        reaction, // Extracted reaction object
        isAddReaction
            ? ReactionAction.reactionAdded
            : ReactionAction
            .reactionRemoved, // REACTION_ADDED or REACTION_REMOVED
      );

      if (updatedMessage != null) {
        debugPrint("🔄 Updated message received: ${updatedMessage.toJson()}");

        setState(() {
          threadMessages[index] = updatedMessage;
        });
      }
    } catch (e) {
      debugPrint("Error updating message reactions: $e");
    }
  }

  void showEditDialog(TextMessage message) {
    TextEditingController editController = TextEditingController(
      text: message.text,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Message"),
          content: TextField(
            controller: editController,
            decoration: InputDecoration(hintText: "Edit your message"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (editController.text.isNotEmpty) {
                  // Call the API to update the message
                  message.text = editController.text; // Update locally
                  CometChat.editMessage(
                    message,
                    onSuccess: (updatedMessage) {
                      setState(() {
                        int index = threadMessages.indexWhere(
                              (msg) => msg.id == updatedMessage.id,
                        );
                        if (index != -1) {
                          threadMessages[index] =
                              updatedMessage; // Update the message in the list
                        }
                      });
                      Navigator.pop(context);
                    },
                    onError: (e) {
                      debugPrint("Error updating message: ${e.message}");
                    },
                  );
                }
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void showDeleteMessageDialog(TextMessage message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Message"),
          content: Text("Are you sure you want to delete this message?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                CometChat.deleteMessage(
                  message.id,
                  onSuccess: (BaseMessage deletedMessage) {
                    debugPrint(
                        "Message deleted successfully: ${deletedMessage.id}");
                    setState(() {
                      // Find the index of the message to be deleted
                      int index = threadMessages.indexWhere((msg) =>
                      msg.id == deletedMessage.id);
                      if (index != -1) {
                        // Replace the deleted message with a "This message was deleted" message
                        threadMessages[index] = TextMessage(
                          id: deletedMessage.id,
                          text: "This message was deleted",
                          sender: threadMessages[index].sender,
                          receiverUid: threadMessages[index].receiverUid,
                          receiverType: threadMessages[index].receiverType,
                          type: CometChatMessageType.text,
                          sentAt: threadMessages[index].sentAt,
                          deletedAt: DateTime
                              .now(), // Mark the time of deletion
                        );
                      }
                    });
                  },
                  onError: (CometChatException e) {
                    debugPrint("Message deletion failed: ${e.message}");
                  },
                );
              },
              child: Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  void showReactionOptions(BaseMessage message) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Text("😊", style: TextStyle(fontSize: 24)),
                    onPressed: () {
                      Navigator.pop(context);
                      toggleReaction(message.id, "😊");
                    },
                  ),
                  IconButton(
                    icon: Text("😂", style: TextStyle(fontSize: 24)),
                    onPressed: () {
                      Navigator.pop(context);
                      toggleReaction(message.id, "😂");
                    },
                  ),
                  IconButton(
                    icon: Text("😢", style: TextStyle(fontSize: 24)),
                    onPressed: () {
                      Navigator.pop(context);
                      toggleReaction(message.id, "😢");
                    },
                  ),
                  IconButton(
                    icon: Text("😴", style: TextStyle(fontSize: 24)),
                    onPressed: () {
                      Navigator.pop(context);
                      toggleReaction(message.id, "😴");
                    },
                  ),
                  IconButton(
                    icon: Text("😠", style: TextStyle(fontSize: 24)),
                    onPressed: () {
                      Navigator.pop(context);
                      toggleReaction(message.id, "😠");
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void showOptionsForMessage(BaseMessage message,
      bool isMe,
      String formatedTimestamp,
      Widget getMessageStatusIcon,) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Text("😊", style: TextStyle(fontSize: 24)),
                    onPressed: () {
                      Navigator.pop(context);
                      toggleReaction(message.id, "😊");
                    },
                  ),
                  IconButton(
                    icon: Text("😂", style: TextStyle(fontSize: 24)),
                    onPressed: () {
                      Navigator.pop(context);
                      toggleReaction(message.id, "😂");
                    },
                  ),
                  IconButton(
                    icon: Text("😢", style: TextStyle(fontSize: 24)),
                    onPressed: () {
                      Navigator.pop(context);
                      toggleReaction(message.id, "😢");
                    },
                  ),
                  IconButton(
                    icon: Text("😴", style: TextStyle(fontSize: 24)),
                    onPressed: () {
                      Navigator.pop(context);
                      toggleReaction(message.id, "😴");
                    },
                  ),
                  IconButton(
                    icon: Text("😠", style: TextStyle(fontSize: 24)),
                    // Angry emoji
                    onPressed: () {
                      Navigator.pop(context);
                      toggleReaction(message.id, "😠");
                    },
                  ),
                ],
              ),
            ),

            if (message is TextMessage &&
                (message.sender?.uid == loggedInUserId))
              ListTile(
                leading: Icon(Icons.edit),
                title: Text("Edit"),
                onTap: () {
                  Navigator.pop(context);
                  showEditDialog(message);
                },
              ),
            if (message.sender?.uid == loggedInUserId) SizedBox(height: 10),
            if (message.sender?.uid == loggedInUserId)
              ListTile(
                leading: Icon(Icons.delete, color: Colors.redAccent.shade700),
                title: Text(
                  "Delete",
                  style: TextStyle(color: Colors.redAccent.shade700),
                ),
                onTap: () {
                  Navigator.pop(context);
                  showDeleteMessageDialog(message as TextMessage);
                },
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Thread")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                  widget.isMe ? Colors.teal.shade800 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      (widget.parentMessage as TextMessage).text,
                      style: TextStyle(
                        fontSize: 17,
                        color: widget.isMe ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.formatedTimestamp,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        SizedBox(width: 5),
                        widget.isMe ? widget.getMessageStatusIcon : SizedBox(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              "${threadMessages.length} Replies",
              style: TextStyle(fontSize: 12),
            ),
            Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: threadMessages.length,
                // Your list of thread messages
                itemBuilder: (context, index) {
                  BaseMessage message = threadMessages[index];
                  bool isMe = message.sender?.uid == loggedInUserId;

                  return GestureDetector(
                    onLongPress: () {
                      showOptionsForMessage(
                        message,
                        isMe,
                        formatTimestamp(message.sentAt!),
                        getMessageStatusIcon(message),
                      );
                    },
                    child: TextMessageWidget(
                      isMe: message.sender?.uid == loggedInUserId,
                      // Check if the sender is the current user
                      isGroupChat: false,
                      // Thread messages are part of a conversation, but not a group
                      message: message as TextMessage,
                      formatedTimestamp: formatTimestamp(message.sentAt!),
                      // Convert timestamp to a readable format
                      getMessageStatusIcon: getMessageStatusIcon(
                        message,
                      ), // You can replace this with the actual status icon logic
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: "Enter Your Text....",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 15),
                  InkWell(
                    onTap: sendThreadMessage,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.send, color: Colors.white),
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
      child: Column(
        children: [
          Align(
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
            ),
          ),
          if (message.reactions.isNotEmpty)
            Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                padding: EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: isMe ? Colors.teal.shade800 : Colors.grey.shade300,
                  borderRadius:
                  isMe
                      ? BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.zero,
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.zero,
                  )
                      : BorderRadius.only(
                    topLeft: Radius.zero,
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.zero,
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,

                  children:
                  message.reactions.map((reactionCount) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Row(
                        children: [
                          Text(
                            reactionCount.reaction!,
                            style: TextStyle(fontSize: 20),
                          ),
                          isGroupChat ? SizedBox(width: 4) : SizedBox(),
                          isGroupChat
                              ? Text(
                            "${reactionCount.count}",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          )
                              : SizedBox(),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
