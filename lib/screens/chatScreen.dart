import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:cometchat_sdk/cometchat_sdk.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:my_first_app/screens/threadScreen.dart';
import 'package:my_first_app/screens/videoPlayerScreen.dart';
import 'package:cometchat_calls_sdk/cometchat_calls_sdk.dart';

class Chatscreen extends StatefulWidget {
  const Chatscreen({super.key, required this.conversation});

  final Conversation conversation;

  @override
  State<Chatscreen> createState() => _ChatscreenState();
}

class _ChatscreenState extends State<Chatscreen> {
  String? loggedInUserId;
  List<BaseMessage> messages = [];
  TextEditingController enteredMsgController = TextEditingController();
  int messageLimit = 50;
  bool isLoadingMore = false;
  bool hasMoreMessages = true;
  String? typingUser;
  Timer? typingTimer;
  bool isUserOnline = false;

  late MessagesRequest request;

  void startTyping() {
    if (widget.conversation.conversationWith is User) {
      CometChat.startTyping(
        receiverUid: (widget.conversation.conversationWith as User).uid,
        receiverType: CometChatReceiverType.user,
      );
    } else if (widget.conversation.conversationWith is Group) {
      CometChat.startTyping(
        receiverUid: (widget.conversation.conversationWith as Group).guid,
        receiverType: CometChatReceiverType.group,
      );
    }

    typingTimer?.cancel();
    // Set a timer to stop typing after a delay
    typingTimer = Timer(Duration(seconds: 3), () {
      endTyping();
    });
  }

  void endTyping() {
    if (widget.conversation.conversationWith is User) {
      CometChat.endTyping(
        receiverUid: (widget.conversation.conversationWith as User).uid,
        receiverType: CometChatReceiverType.user,
      );
    } else if (widget.conversation.conversationWith is Group) {
      CometChat.endTyping(
        receiverUid: (widget.conversation.conversationWith as Group).guid,
        receiverType: CometChatReceiverType.group,
      );
    }
  }

  void addReaction(int messageId, String reaction) {
    CometChat.addReaction(
      messageId,
      reaction,
      onSuccess: (message) {
        debugPrint("Successfully Reaction added");
        setState(() {
          int index = messages.indexWhere((msg) => msg.id == message.id);
          if (index != -1) {
            messages[index] = message;
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
          int index = messages.indexWhere((msg) => msg.id == message.id);
          if (index != -1) {
            messages[index] = message;
          }
        });
      },
      onError: (message) {
        debugPrint("Error in Reaction removal");
      },
    );
  }

  void toggleReaction(int messageId, String newReaction) {
    int index = messages.indexWhere((msg) => msg.id == messageId);
    if (index == -1) return; // Message not found

    BaseMessage message = messages[index];

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
  ) async {
    debugPrint("Update Reaction called");
    int index = messages.indexWhere((msg) => msg.id == messageId);
    if (index == -1) return; // Message not found

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
            messages[index], // Existing message
            reaction, // Extracted reaction object
            isAddReaction
                ? ReactionAction.reactionAdded
                : ReactionAction
                    .reactionRemoved, // REACTION_ADDED or REACTION_REMOVED
          );

      if (updatedMessage != null) {
        setState(() {
          messages[index] = updatedMessage;
        });
      }
    } catch (e) {
      debugPrint("Error updating message reactions: $e");
    }
  }

  void fetchUserPresence() {
    if (widget.conversation.conversationWith is User) {
      String userId = (widget.conversation.conversationWith as User).uid;

      CometChat.getUser(
        userId,
        onSuccess: (User user) {
          setState(() {
            isUserOnline = user.status == CometChatUserStatus.online;
          });
        },
        onError: (CometChatException e) {
          debugPrint("Failed to get user presence: ${e.message}");
        },
      );
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

  void fetchMessages({bool loadMore = false}) {
    if (isLoadingMore || !hasMoreMessages) return; // Prevent multiple calls

    setState(() {
      isLoadingMore = true;
    });

    if (!loadMore) {
      request =
          (MessagesRequestBuilder()
                ..uid =
                    widget.conversation.conversationWith is User
                        ? (widget.conversation.conversationWith as User).uid
                        : null
                ..guid =
                    widget.conversation.conversationWith is Group
                        ? (widget.conversation.conversationWith as Group).guid
                        : null
                ..limit = messageLimit)
              .build();
    }

    request.fetchPrevious(
      onSuccess: (List<BaseMessage> msgs) {
        setState(() {
          if (msgs.isEmpty) {
            hasMoreMessages = false;
          } else {
            messages.clear();
            messages.addAll(
              msgs.reversed.where((msg) => msg.parentMessageId == 0).map((msg) {
                print(msg.deletedAt);
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
              }).toList(),
            );
          }
          isLoadingMore = false;
        });
        markMessagesAsRead(msgs);
        debugPrint("Fetched messages: $msgs");
      },
      onError: (CometChatException e) {
        debugPrint("Message fetching failed with exception: ${e.message}");
        setState(() {
          isLoadingMore = false;
        });
      },
    );
  }

  Future<void> sendMessage() async {
    String receiverID =
        widget.conversation.conversationWith is User
            ? (widget.conversation.conversationWith as User).uid
            : (widget.conversation.conversationWith as Group).guid;

    String messageText = enteredMsgController.text.trim();
    String receiverType =
        widget.conversation.conversationWith is User
            ? CometChatConversationType.user
            : CometChatConversationType.group;
    String type = CometChatMessageType.text;

    TextMessage textMessage = TextMessage(
      text: messageText,
      receiverUid: receiverID,
      type: type,
      receiverType: receiverType,
    );

    try {
      await CometChat.sendMessage(
        textMessage,
        onSuccess: (TextMessage message) {
          debugPrint("Message sent successfully:  $message");
          setState(() {
            messages.insert(0, message);
          });

          enteredMsgController.clear();
        },
        onError: (CometChatException e) {
          debugPrint("Message sending failed with exception:  ${e.message}");
        },
      );
    } catch (e) {
      print("Message sending failed: $e");
    }
  }

  void sendMediaMessage(bool isGroup) async {
    String receiverID =
        widget.conversation.conversationWith is User
            ? (widget.conversation.conversationWith as User).uid
            : (widget.conversation.conversationWith as Group).guid;

    String receiverType =
        isGroup ? CometChatReceiverType.group : CometChatReceiverType.user;

    // Open File Picker
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      String filePath = file.path;
      String fileExtension = filePath.split('.').last.toLowerCase();

      // Determine the message type based on file extension
      String messageType;
      if (["mp4", "mov", "avi", "mkv"].contains(fileExtension)) {
        messageType = CometChatMessageType.video;
      } else if (["mp3", "wav", "aac", "ogg"].contains(fileExtension)) {
        messageType = CometChatMessageType.audio;
      } else if (["jpg", "jpeg", "png", "gif"].contains(fileExtension)) {
        messageType = CometChatMessageType.image;
      } else {
        messageType = CometChatMessageType.file; // For other file types
      }

      MediaMessage mediaMessage = MediaMessage(
        receiverType: receiverType,
        type: messageType,
        receiverUid: receiverID,
        file: file.path,
      );

      CometChat.sendMediaMessage(
        mediaMessage,
        onSuccess: (MediaMessage message) {
          debugPrint("Media message sent successfully: $message");
          setState(() {
            messages.insert(0, message);
          });
        },
        onError: (CometChatException e) {
          debugPrint("Media message sending failed: ${e.message}");
        },
      );
    } else {
      debugPrint("File selection cancelled.");
    }
  }

  void deleteMessage(int messageId) {
    CometChat.deleteMessage(
      messageId,
      onSuccess: (BaseMessage deletedMessage) {
        debugPrint("Message deleted successfully: ${deletedMessage.id}");
        setState(() {
          // Find the index of the message to be deleted
          int index = messages.indexWhere((msg) => msg.id == deletedMessage.id);
          if (index != -1) {
            // Replace the deleted message with a "This message was deleted" message
            messages[index] = TextMessage(
              id: deletedMessage.id,
              text: "This message was deleted",
              sender: messages[index].sender,
              receiverUid: messages[index].receiverUid,
              receiverType: messages[index].receiverType,
              type: CometChatMessageType.text,
              sentAt: messages[index].sentAt,
              deletedAt: DateTime.now(), // Mark the time of deletion
            );
          }
        });
      },
      onError: (CometChatException e) {
        debugPrint("Message deletion failed: ${e.message}");
      },
    );
  }

  void showDeleteMessageDialog(BaseMessage message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Message", style: TextStyle(color: Colors.black)),
          content: Text("Are you sure you want to delete this message?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                deleteMessage(message.id);
                Navigator.pop(context);
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void editMessage(TextMessage oldMessage, String updatedText) {
    TextMessage updatedMessage = TextMessage(
      text: updatedText,
      receiverUid: oldMessage.receiverUid,
      receiverType: oldMessage.receiverType,
      type: oldMessage.type,
    );

    updatedMessage.id = oldMessage.id;

    CometChat.editMessage(
      updatedMessage,
      onSuccess: (BaseMessage message) {
        // debugPrint("Message edited successfully: ${message.text}");
        setState(() {
          int index = messages.indexWhere((msg) => msg.id == message.id);
          if (index != -1) {
            messages[index] = message;
          }
        });
      },
      onError: (CometChatException e) {
        debugPrint("Message editing failed: ${e.message}");
      },
    );
  }

  void showEditDialog(BaseMessage message) {
    if (message is TextMessage) {
      TextEditingController controller = TextEditingController(
        text: message.text,
      );

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Edit Message"),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: "Edit your message"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    editMessage(message, controller.text);
                    Navigator.pop(context);
                  }
                },
                child: Text("Save"),
              ),
            ],
          );
        },
      );
    }
  }

  void showOptionsForMessage(
    BaseMessage message,
    bool isMe,
    bool isGroupChat,
    String formatedTimestamp,
    Widget getMessageStatusIcon,
  ) {
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
            ListTile(
              leading: Icon(Icons.reply_rounded),
              title: Text("Reply"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ThreadScreen(
                          parentMessage: message,
                          isMe: isMe,
                          isGroupChat: isGroupChat,
                          formatedTimestamp: formatedTimestamp,
                          getMessageStatusIcon: getMessageStatusIcon,
                        ),
                  ),
                );
              },
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
                  showDeleteMessageDialog(message);
                },
              ),
          ],
        );
      },
    );
  }

  void markMessagesAsRead(List<BaseMessage> msgs) {
    for (var message in msgs) {
      if (message.sender?.uid != loggedInUserId) {
        CometChat.markAsRead(
          message,
          onSuccess: (_) {},
          onError: (CometChatException e) {
            debugPrint("Error marking message as read");
          },
        );
      }
    }
  }



  @override
  void initState() {
    super.initState();

    CometChat.getLoggedInUser().then((User? user) {
      setState(() {
        loggedInUserId = user?.uid; // Save logged-in user UID
      });
    });

    fetchUserPresence();
    fetchMessages();
    markMessagesAsRead(messages);
    CometChat.addMessageListener(
      "CHAT_SCREEN_LISTENER",
      ChatMessageListener(
        onNewTextMessage: (TextMessage message) {
          if ((widget.conversation.conversationWith is User &&
                  message.sender?.uid ==
                      (widget.conversation.conversationWith as User).uid) ||
              (widget.conversation.conversationWith is Group &&
                  message.receiverUid ==
                      (widget.conversation.conversationWith as Group).guid)) {
            setState(() {
              messages.insert(0, message);
            });

            markMessagesAsRead([message]);
          }
        },
        onNewMediaMessage: (MediaMessage message) {
          if ((widget.conversation.conversationWith is User &&
                  message.sender?.uid ==
                      (widget.conversation.conversationWith as User).uid) ||
              (widget.conversation.conversationWith is Group &&
                  message.receiverUid ==
                      (widget.conversation.conversationWith as Group).guid)) {
            setState(() {
              messages.insert(0, message);
            });
            markMessagesAsRead([message]);
          }
        },
        onMessageDelivered: (int messageId) {
          setState(() {
            for (var msg in messages) {
              if (msg.id == messageId) {
                msg.deletedAt = DateTime.now();
              }
            }
          });
        },
        onMessageRead: (int messageId) {
          setState(() {
            for (var msg in messages) {
              if (msg.id == messageId) {
                msg.readAt = DateTime.now();
              }
            }
          });
        },
        onTypingStartedFunc: (TypingIndicator typingIndicator) {
          if ((widget.conversation.conversationWith is User &&
                  typingIndicator.sender.uid ==
                      (widget.conversation.conversationWith as User).uid) ||
              (widget.conversation.conversationWith is Group &&
                  typingIndicator.sender.uid ==
                      (widget.conversation.conversationWith as Group).guid)) {
            setState(() {
              typingUser = typingIndicator.sender.name;
            });
          }
        },
        onTypingEndedFunc: (TypingIndicator typingIndicator) {
          if ((widget.conversation.conversationWith is User &&
                  typingIndicator.sender.uid ==
                      (widget.conversation.conversationWith as User).uid) ||
              (widget.conversation.conversationWith is Group &&
                  typingIndicator.sender.uid ==
                      (widget.conversation.conversationWith as Group).guid)) {
            setState(() {
              typingUser = null;
            });
          }
        },
        onMessageDelete: (BaseMessage deletedMessage) {
          setState(() {
            for (int i = 0; i < messages.length; i++) {
              if (messages[i].id == deletedMessage.id) {
                messages[i] = TextMessage(
                  id: deletedMessage.id,
                  text: "This message was deleted",
                  sender: messages[i].sender,
                  receiverUid: messages[i].receiverUid,
                  receiverType: messages[i].receiverType,
                  type: CometChatMessageType.text,
                  sentAt: messages[i].sentAt,
                );
                break;
              }
            }
          });
        },
        onMessageEdit: (BaseMessage editedMessage) {
          setState(() {});
        },
        onMessageReactionAddition: (ReactionEvent reactionEvent) {
          debugPrint("onMessageReactionAddition");
          updateMessageReactions(
            reactionEvent.parentMessageId!,
            reactionEvent,
            true,
          );
        },
        onMessageReactionRemoval: (ReactionEvent reactionEvent) {
          debugPrint("onMessageReactionRemoval");
          updateMessageReactions(
            reactionEvent.parentMessageId!,
            reactionEvent,
            false,
          );
        },
      ),
    );

    CometChat.addUserListener(
      "CHAT_SCREEN_USER_PRESENCE_LISTENER",
      ChatScreen_UserPresenceListener(
        onUserOnlineFunc: (User user) {
          if (user.uid == (widget.conversation.conversationWith as User).uid) {
            setState(() {
              isUserOnline = true;
            });
          }
        },
        onUserOfflineFunc: (User user) {
          if (user.uid == (widget.conversation.conversationWith as User).uid) {
            setState(() {
              isUserOnline = false;
            });
          }
        },
      ),
    );
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

  @override
  void dispose() {
    super.dispose();
    CometChat.removeMessageListener("CHAT_SCREEN_LISTENER");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade900,
        title: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage:
                        widget.conversation.conversationWith is User &&
                                (widget.conversation.conversationWith as User)
                                        .avatar !=
                                    null
                            ? NetworkImage(
                              (widget.conversation.conversationWith as User)
                                  .avatar!,
                            )
                            : null,
                    child:
                        widget.conversation.conversationWith is Group
                            ? Icon(Icons.group, color: Colors.teal.shade500)
                            : null,
                  ),
                ],
              ),
              SizedBox(width: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversation.conversationWith is User
                        ? (widget.conversation.conversationWith as User).name
                        : (widget.conversation.conversationWith as Group).name,
                    style: TextStyle(fontSize: 25, color: Colors.white),
                  ),
                  if (typingUser != null) ...[
                    Text(
                      widget.conversation.conversationWith is User
                          ? "Typing...."
                          : "${typingUser} is Typing...",
                      style: TextStyle(color: Colors.green, fontSize: 18),
                    ),
                  ] else if (isUserOnline) ...[
                    Row(
                      children: [
                        Text(
                          "Online",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      "last seen ${formatTimestamp((widget.conversation.conversationWith as User).lastActiveAt!)}",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: (){

            },
            icon: Icon(Icons.call, color: Colors.white),
          ),
          IconButton(
            onPressed: () {

            },
            icon: Icon(Icons.video_call_rounded, color: Colors.white),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/8c98994518b575bfd8c949e91d20548b.jpg"),
            fit: BoxFit.fill,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child:
                  messages.isEmpty
                      ? Center(
                        child: Text(
                          "No messages...",
                          style: TextStyle(color: Colors.white, fontSize: 22),
                        ),
                      )
                      : NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (scrollInfo.metrics.pixels ==
                              scrollInfo.metrics.maxScrollExtent) {
                            fetchMessages(loadMore: true);
                          }
                          return false;
                        },
                        child: ListView.builder(
                          reverse: true,
                          itemCount: messages.length + 1,
                          itemBuilder: (context, index) {
                            if (index == messages.length) {
                              return isLoadingMore
                                  ? Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.teal.shade900,
                                    ),
                                  )
                                  : SizedBox(); // Loading indicator
                            }
                            BaseMessage message = messages[index];
                            bool isMe = message.sender?.uid == loggedInUserId;
                            bool isGroupChat =
                                widget.conversation.conversationWith is Group;

                            if (message is TextMessage) {
                              return GestureDetector(
                                onLongPress: () {
                                  showOptionsForMessage(
                                    message,
                                    isMe,
                                    isGroupChat,
                                    formatTimestamp(message.sentAt!),
                                    getMessageStatusIcon(message),
                                  );
                                },
                                child: TextMessageWidget(
                                  isMe: isMe,
                                  isGroupChat: isGroupChat,
                                  message: message,
                                  formatedTimestamp: formatTimestamp(
                                    message.sentAt!,
                                  ),
                                  getMessageStatusIcon: getMessageStatusIcon(
                                    message,
                                  ),
                                ),
                              );
                            }
                            if (message is MediaMessage) {
                              return GestureDetector(
                                onLongPress: () {
                                  showOptionsForMessage(
                                    message,
                                    isMe,
                                    isGroupChat,
                                    formatTimestamp(message.sentAt!),
                                    getMessageStatusIcon(message),
                                  );
                                },
                                child: MediaMessageWidget(
                                  isMe: isMe,
                                  isGroupChat: isGroupChat,
                                  message: message,
                                  formattedTimestamp: formatTimestamp(
                                    message.sentAt!,
                                  ),
                                  getMessageStatusIcon: getMessageStatusIcon(
                                    message,
                                  ),
                                ),
                              );
                            }
                            if (message is Action) {
                              return SizedBox();
                            }

                            return Center(child: Text("No Messages...."));
                          },
                        ),
                      ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: enteredMsgController,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          startTyping();
                        } else {
                          endTyping();
                        }
                      },
                      // maxLines: 5,
                      decoration: InputDecoration(
                        suffixIcon: IconButton(
                          onPressed: () {
                            sendMediaMessage(
                              widget.conversation.conversationWith is Group?,
                            );
                          },
                          icon: Icon(Icons.attach_file_rounded),
                        ),
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
                      if (enteredMsgController.text.isNotEmpty) {
                        print("Msg not empty");
                        sendMessage();
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
          if (message.replyCount > 0)
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ThreadScreen(
                          parentMessage: message,
                          isMe: isMe,
                          isGroupChat: isGroupChat,
                          formatedTimestamp: formatedTimestamp,
                          getMessageStatusIcon: getMessageStatusIcon,
                        ),
                  ),
                );
              },
              child: Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment:
                      isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    Icon(Icons.reply_rounded),
                    SizedBox(width: 5),
                    message.replyCount > 1
                        ? Text("${message.replyCount} Replies")
                        : Text("${message.replyCount} Reply"),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class VideoMessageWidget extends StatelessWidget {
  final String fileUrl;
  final bool isMe;

  const VideoMessageWidget({
    super.key,
    required this.fileUrl,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(videoUrl: fileUrl),
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              // color: Colors.black,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(color: Colors.black),
            ),
          ),

          Icon(Icons.play_circle_fill, size: 50, color: Colors.white),
        ],
      ),
    );
  }
}

class AudioMessageWidget extends StatefulWidget {
  final String fileUrl;
  final bool isMe;

  const AudioMessageWidget({
    super.key,
    required this.fileUrl,
    required this.isMe,
  });

  @override
  State<AudioMessageWidget> createState() => _AudioMessageWidgetState();
}

class _AudioMessageWidgetState extends State<AudioMessageWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onDurationChanged.listen((Duration d) {
      setState(() {
        _duration = d;
      });
    });

    _audioPlayer.onPositionChanged.listen((Duration p) {
      setState(() {
        _position = p;
      });
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  void _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(widget.fileUrl));
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.7,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _togglePlayPause,
            child: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
              color: widget.isMe ? Colors.grey.shade300 : Colors.teal.shade800,
              size: 32,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Slider(
              value: _position.inSeconds.toDouble(),
              min: 0,
              max: _duration.inSeconds.toDouble(),
              onChanged: (value) async {
                await _audioPlayer.seek(Duration(seconds: value.toInt()));
              },
              activeColor:
                  widget.isMe ? Colors.grey.shade300 : Colors.teal.shade800,
              inactiveColor: Colors.grey,
            ),
          ),
          SizedBox(width: 5),
          Text(
            "${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}",
            style: TextStyle(
              fontSize: 12,
              color: widget.isMe ? Colors.grey.shade300 : Colors.teal.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

class MediaMessageWidget extends StatefulWidget {
  const MediaMessageWidget({
    super.key,
    required this.isMe,
    required this.isGroupChat,
    required this.message,
    required this.formattedTimestamp,
    required this.getMessageStatusIcon,
  });

  final bool isMe;
  final bool isGroupChat;
  final MediaMessage message;
  final String formattedTimestamp;
  final Widget getMessageStatusIcon;

  @override
  State<MediaMessageWidget> createState() => _MediaMessageWidgetState();
}

class _MediaMessageWidgetState extends State<MediaMessageWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Column(
        children: [
          Align(
            alignment:
                widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    widget.isMe ? Colors.teal.shade800 : Colors.grey.shade300,
                borderRadius:
                    widget.isMe
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
              child: _buildMediaPreview(),
            ),
          ),
          if (widget.message.reactions.isNotEmpty)
            Align(
              alignment:
                  widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                padding: EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color:
                      widget.isMe ? Colors.teal.shade800 : Colors.grey.shade300,
                  borderRadius:
                      widget.isMe
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
                      widget.message.reactions.map((reactionCount) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Row(
                            children: [
                              Text(
                                reactionCount.reaction!,
                                style: TextStyle(fontSize: 20),
                              ),
                              widget.isGroupChat
                                  ? SizedBox(width: 4)
                                  : SizedBox(),
                              widget.isGroupChat
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
          if (widget.message.replyCount > 0)
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ThreadScreen(
                          parentMessage: widget.message,
                          isMe: widget.isMe,
                          isGroupChat: widget.isGroupChat,
                          formatedTimestamp: widget.formattedTimestamp,
                          getMessageStatusIcon: widget.getMessageStatusIcon,
                        ),
                  ),
                );
              },
              child: Align(
                alignment: Alignment.bottomRight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.reply_rounded),
                    SizedBox(width: 5),
                    widget.message.replyCount > 1
                        ? Text("${widget.message.replyCount} Replies")
                        : Text("${widget.message.replyCount} Reply"),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.isGroupChat && !widget.isMe)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 10,
                backgroundImage:
                    widget.message.sender?.avatar != null
                        ? NetworkImage(widget.message.sender!.avatar!)
                        : null,
                backgroundColor: Colors.teal,
                child:
                    widget.message.sender?.avatar == null
                        ? Icon(Icons.person, color: Colors.white)
                        : null,
              ),
              SizedBox(width: 10),
              Text(
                widget.message.sender?.name ?? "Unknown",
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        SizedBox(height: 5),
        // Media preview
        _buildMediaContent(widget.isMe),
        SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.formattedTimestamp,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(width: 5),
            widget.isMe ? widget.getMessageStatusIcon : SizedBox(),
          ],
        ),
      ],
    );
  }

  Widget _buildMediaContent(bool isMe) {
    String fileUrl = widget.message.attachment!.fileUrl;
    String fileType = widget.message.type;

    if (fileType == CometChatMessageType.image) {
      return _buildImageMessage(fileUrl);
    } else if (fileType == CometChatMessageType.video) {
      return _buildVideoMessage(fileUrl, isMe);
    } else if (fileType == CometChatMessageType.audio) {
      return _buildAudioMessage(fileUrl, isMe);
    } else {
      return SizedBox();
    }
  }

  Widget _buildImageMessage(String fileUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        fileUrl,
        width: MediaQuery.of(context).size.width * 0.7,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildVideoMessage(String fileUrl, bool isMe) {
    return VideoMessageWidget(fileUrl: fileUrl, isMe: isMe);
  }

  Widget _buildAudioMessage(String fileUrl, bool isMe) {
    return AudioMessageWidget(fileUrl: fileUrl, isMe: isMe);
  }
}

class ChatMessageListener with MessageListener {
  final Function(TextMessage) onNewTextMessage;
  final Function(MediaMessage) onNewMediaMessage;
  final Function(int messageId) onMessageRead;
  final Function(int messageId) onMessageDelivered;
  final Function(TypingIndicator) onTypingStartedFunc;
  final Function(TypingIndicator) onTypingEndedFunc;
  final Function(BaseMessage) onMessageDelete;
  final Function(BaseMessage) onMessageEdit;
  final Function(ReactionEvent) onMessageReactionAddition;
  final Function(ReactionEvent) onMessageReactionRemoval;

  ChatMessageListener({
    required this.onNewTextMessage,
    required this.onNewMediaMessage,
    required this.onMessageRead,
    required this.onMessageDelivered,
    required this.onTypingStartedFunc,
    required this.onTypingEndedFunc,
    required this.onMessageDelete,
    required this.onMessageEdit,
    required this.onMessageReactionAddition,
    required this.onMessageReactionRemoval,
  });

  //CometChat.addMessageListener("listenerId", this);
  @override
  void onTextMessageReceived(TextMessage textMessage) {
    debugPrint("Text message received successfully: $textMessage");
    onNewTextMessage(textMessage);
  }

  @override
  void onMediaMessageReceived(MediaMessage mediaMessage) {
    debugPrint("Media message received successfully: $mediaMessage");
    onNewMediaMessage(mediaMessage);
  }

  @override
  void onCustomMessageReceived(CustomMessage customMessage) {
    debugPrint("Custom message received successfully: $customMessage");
  }

  @override
  onInteractiveMessageReceived(InteractiveMessage message) {}

  @override
  void onMessageEdited(BaseMessage message) {
    onMessageEdit(message);
  }

  @override
  void onMessagesRead(MessageReceipt receipt) {
    debugPrint("Message read: ${receipt.messageId}");
    onMessageRead(receipt.messageId);
  }

  @override
  void onMessagesDelivered(MessageReceipt receipt) {
    debugPrint("Message delivered: ${receipt.messageId}");
    onMessageDelivered(receipt.messageId);
  }

  @override
  void onTypingStarted(TypingIndicator typingIndicator) {
    debugPrint("${typingIndicator.sender.name} is typing...");
    onTypingStartedFunc(typingIndicator);
  }

  @override
  void onTypingEnded(TypingIndicator typingIndicator) {
    debugPrint("${typingIndicator.sender.name} stopped typing...");
    onTypingEndedFunc(typingIndicator);
  }

  @override
  void onMessageDeleted(BaseMessage message) {
    onMessageDelete(message);
  }

  @override
  void onMessageReactionAdded(ReactionEvent reactionEvent) {
    onMessageReactionAddition(reactionEvent);
  }

  @override
  void onMessageReactionRemoved(ReactionEvent reactionEvent) {
    onMessageReactionRemoval(reactionEvent);
  }
}

class ChatScreen_UserPresenceListener with UserListener {
  final Function(User) onUserOnlineFunc;
  final Function(User) onUserOfflineFunc;

  ChatScreen_UserPresenceListener({
    required this.onUserOnlineFunc,
    required this.onUserOfflineFunc,
  });

  //CometChat.addUserListener("user_Listener_id", this);
  @override
  void onUserOnline(User user) {
    onUserOnlineFunc(user);
  }

  @override
  void onUserOffline(User user) {
    onUserOfflineFunc(user);
  }
}

