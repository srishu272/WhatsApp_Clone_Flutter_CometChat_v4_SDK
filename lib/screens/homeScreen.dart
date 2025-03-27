import 'dart:async';

import 'package:cometchat_calls_sdk/builder/call_settings.dart';
import 'package:cometchat_calls_sdk/helper/cometchatcalls_exception.dart';
import 'package:cometchat_calls_sdk/main/cometchatcalls.dart';
import 'package:cometchat_calls_sdk/model/generate_token.dart';
import 'package:cometchat_sdk/cometchat_sdk.dart';
import 'package:cometchat_sdk/exception/cometchat_exception.dart';
import 'package:cometchat_sdk/main/cometchat.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:my_first_app/listeners/callListerner.dart';
import 'package:my_first_app/screens/addUserScreen.dart';
import 'package:my_first_app/screens/calling/incomingCallScreen.dart';
import 'package:my_first_app/screens/chatScreen.dart';
import 'package:my_first_app/screens/loginScreen.dart';

import '../listeners/groupMembersListener.dart';
import 'calling/ongoingCallScreen.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  User? userData;
  List<Conversation> conversations = [];
  Timer? typingTimer;
  Map<String, String?> typingUsers = {};
  Map<String, bool> onlineUsers = {};
  bool isCallScreenOpen = false;
  bool isCallSessionStarted = false;

  Future<void> fetchConversations() async {
    ConversationsRequest request = ConversationsRequestBuilder().build();

    request.fetchNext(
      onSuccess: (List<Conversation> fetchedConversations) async {
        // Extract user IDs from the fetched conversations
        List<String> userIds = fetchedConversations
            .where((conv) => conv.conversationWith is User)
            .map((conv) => (conv.conversationWith as User).uid)
            .toList();

        // Create a temporary map to store fetched user statuses
        Map<String, bool> tempOnlineUsers = {};

        // Fetch user statuses in parallel
        if (userIds.isNotEmpty) {
          await Future.wait(userIds.map(
                (userId) => CometChat.getUser(
              userId,
              onSuccess: (User user) {
                tempOnlineUsers[user.uid] = user.status == "online";
              },
              onError: (CometChatException e) {
                debugPrint("Error fetching user status: ${e.message}");
              },
            ),
          ));
        }

        // Update UI in a single setState call
        setState(() {
          conversations = fetchedConversations;
          onlineUsers = tempOnlineUsers;
        });
      },
      onError: (CometChatException e) {
        debugPrint("Error fetching conversations: ${e.message}");
      },
    );
  }

  void updateLastMessage(BaseMessage message) {
    setState(() {
      for (var conversation in conversations) {
        // Check if the current conversation is related to the message
        bool isRelatedConversation = false;
        if (conversation.conversationWith is User &&
            (conversation.conversationWith as User).uid ==
                message.sender?.uid) {
          isRelatedConversation = true;
        } else if (conversation.conversationWith is Group &&
            (conversation.conversationWith as Group).guid ==
                message.receiverUid) {
          isRelatedConversation = true;
        }
        if (isRelatedConversation) {
          // Check if the updated message is the same as the last message
          if (conversation.lastMessage?.id == message.id ||
              conversation.lastMessage == null) {
            conversation.lastMessage = message;
          }
          break;
        }
      }
    });
  }

  void logout() {
    CometChat.logout(
      onSuccess: (successMessage) {
        debugPrint("Logout successful with message $successMessage");
      },
      onError: (CometChatException e) {
        debugPrint("Logout failed with exception:  ${e.message}");
      },
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Loginscreen()),
    );
  }

  Future<User?> getCurrentUser() async {
    try {
      User? user = await CometChat.getLoggedInUser();
      return user; // Returning user data
    } catch (e) {
      print("Error retrieving logged-in user: $e");
      return null;
    }
  }

  void fetchUser() async {
    User? user = await getCurrentUser();
    setState(() {
      userData = user;
    });
  }

  String getLastMessage(BaseMessage? lastMsg) {
    // if (lastMsg == null) return "";
    if (lastMsg?.parentMessageId != 0) return ""; // Ignore thread messages

    if (lastMsg is TextMessage) {
      return lastMsg.text;
    } else if (lastMsg is MediaMessage) {
      return lastMsg.attachment?.fileName ?? "Media Message";
    } else if (lastMsg is Action) {
      // Check for call actions
      if (lastMsg.action == "call_started") {
        return "Call Started";
      } else if (lastMsg.action == "call_ended") {
        return "Call Ended";
      } else if (lastMsg.action == "call_missed") {
        return "Missed Call";
      } else if (lastMsg.action == "message_deleted") {
        return "This message was deleted";
      }
      return lastMsg.message!;
    }
    return "Unsupported message type";
  }

  String formatTimestamp(DateTime date) {
    DateTime now = DateTime.now();
    //if the day is today, showing only the time
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return "Yesterday";
    }
    // If the message is from a different day, showing the date
    else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }

  bool isUserOnline(String userId) {
    return onlineUsers[userId] ?? false;
  }

  void updateConversationList(BaseMessage message) {
    setState(() {
      // Find the conversation in the list
      int index = conversations.indexWhere((c) {
        if (c.conversationWith is User) {
          return (c.conversationWith as User).uid == message.sender?.uid ||
              (c.conversationWith as User).uid == message.receiverUid;
        } else if (c.conversationWith is Group) {
          return (c.conversationWith as Group).guid == message.receiverUid;
        }
        return false;
      });

      if (index != -1) {
        // Move conversation to the top and update last message
        Conversation updatedConversation = conversations[index];
        updatedConversation.lastMessage = message;
        conversations.removeAt(index);
        conversations.insert(0, updatedConversation);
      } else {
        // If the conversation is not found, fetch new conversations
        fetchConversations();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    fetchUser();
    fetchConversations();

    CometChat.addMessageListener(
      "MESSAGE_LISTENER",
      HomeScreenMessageListener(
        onNewTextMessage: (TextMessage message) {
          updateLastMessage(message);
          updateConversationList(message);
        },
        onNewMediaMessage: (MediaMessage mediaMessage) {
          updateLastMessage(mediaMessage);
          updateConversationList(mediaMessage);
        },
        onTypingStartedFunc: (TypingIndicator typingIndicator) {
          setState(() {
            if (typingIndicator.receiverType == CometChatReceiverType.user) {
              // Direct message, show only "Typing..."
              typingUsers[typingIndicator.receiverId] = "Typing...";
            } else if (typingIndicator.receiverType ==
                CometChatReceiverType.group) {
              // Group message, show "User is typing..."
              typingUsers[typingIndicator.receiverId] =
                  "${typingIndicator.sender.name} is typing...";
            }
          });
        },

        onTypingEndedFunc: (TypingIndicator typingIndicator) {
          setState(() {
            typingUsers.remove(typingIndicator.receiverId);
          });
        },
        onMessageDelete: (BaseMessage message) {
          // updateLastMessage(message);
        },

        onMessageEdit: (BaseMessage message) {
          updateLastMessage(message);
        },
      ),
    );

    CometChat.addUserListener(
      "HOME_SCREEN_USER_PRESENCE_LISTENER",
      HomeScreen_UserPresenceListener(
        onUserOnlineFunc: (user) {
          debugPrint("${user.name} is online");
          setState(() {
            onlineUsers[user.uid] = true;
          });
        },
        onUserOfflineFunc: (user) {
          setState(() {
            onlineUsers[user.uid] = false;
          });
        },
      ),
    );

    CometChat.addCallListener(
      "CALL_LISTENER",
      CallEventListener(
        listenerId: "CALL_LISTENER",
        onIncomingCallReceivedFunc: (Call call) {
          if (!isCallScreenOpen) {
            isCallScreenOpen = true;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => IncomingCallScreen(
                      user: call.sender!,
                      sessionID: call.sessionId!,
                    ),
              ),
            ).then((_) => isCallScreenOpen = false);
          }
        },
        onIncomingCallCancelledFunc: (Call call) {
          Navigator.pop(context);
        },
        onOutgoingCallAcceptedFunc: (Call call) async {
          if (!isCallSessionStarted) {
            isCallSessionStarted = true;

            debugPrint(call.sessionId);
            String? userAuthToken =
                await CometChat.getUserAuthToken(); //Logged in user auth token

            CometChatCalls.generateToken(
              call.sessionId!,
              userAuthToken!,
              onSuccess: (GenerateToken generateToken) {
                debugPrint("Success generate token: ${generateToken.token}");
                CallSettings callSettings =
                    (CallSettingsBuilder()
                          // ..defaultLayout = true
                          ..setAudioOnlyCall =
                              true //CometChatCallsEventsListener
                              )
                        .build();

                CometChatCalls.startSession(
                  generateToken.token!,
                  callSettings,
                  onSuccess: (Widget? callingWidget) {
                    debugPrint("Success Start Session");
                  },
                  onError: (CometChatCallsException e) {
                    debugPrint("Error: $e");
                    isCallSessionStarted = false;
                  },
                );
              },
              onError: (CometChatCallsException e) {
                debugPrint("Error: $e");
                isCallSessionStarted = false;
              },
            );
          }
        },
        onOutgoingCallRejectedFunc: (Call call) {},
        onCallEndedMessageReceivedFunc: (Call call) {},
      ),
    );

    CometChat.addGroupListener(
      "GROUP_LISTENER",
      GroupMemberListener(
        onMemberAdded: (User addedUser, Group addedTo) {
          fetchConversations();
        },
        onMemberKicked: (User kickedUser, User kickedBy, Group kickedFrom) {},
        onMemberLeft: (User leftUser, Group leftGroup) {},
        onMemberBanned: (User bannedUser, User bannedBy, Group bannedFrom) {},
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    CometChat.removeMessageListener("MESSAGE_LISTENER");
    CometChat.removeUserListener("HOME_SCREEN_USER_PRESENCE_LISTENER");
    CometChat.removeGroupListener("GROUP_LISTENER");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          icon: Icon(Icons.menu),
          color: Colors.white,
        ),
        title: Text(
          "Whatsapp",
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.teal.shade900,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded),
            iconColor: Colors.white,
            offset: Offset(0, 50),
            elevation: 2,
            color: Colors.white,
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: "logout",
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 10),
                        Text(
                          "Logout",
                          style: TextStyle(color: Colors.red, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ],
            onSelected: (value) {
              if (value == "logout") {
                logout();
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal.shade200),
              child:
                  userData == null
                      ? Center(
                        child: CircularProgressIndicator(),
                      ) // Show a loader until data is fetched
                      : Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage:
                                userData!.avatar != null &&
                                        userData!.avatar!.isNotEmpty
                                    ? NetworkImage(userData!.avatar!)
                                    : null,
                            child:
                                userData!.avatar == null ||
                                        userData!.avatar!.isEmpty
                                    ? Icon(Icons.person, size: 50)
                                    : null,
                          ),
                          SizedBox(height: 5),
                          Text(userData!.name, style: TextStyle(fontSize: 20)),
                        ],
                      ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(color: Colors.white),
        child: ListView.builder(
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            print(conversations[0]);
            var conversation = conversations[index];
            String? conversationId = "";
            if (conversation.conversationWith is User) {
              conversationId = (conversation.conversationWith as User).uid;
            } else if (conversation.conversationWith is Group) {
              conversationId = (conversation.conversationWith as Group).guid;
            }

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => Chatscreen(conversation: conversation, onNewMessageSent: (message) {
                          updateConversationList(message);
                        }),
                  ),
                ).then((_) {
                  fetchUser();
                  fetchConversations();
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.black12.withOpacity(0.1)),
                  ),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 11,
                    horizontal: 10,
                  ),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundImage:
                            conversation.conversationWith is User
                                ? (conversation.conversationWith as User)
                                                .avatar !=
                                            null &&
                                        (conversation.conversationWith as User)
                                            .avatar!
                                            .isNotEmpty
                                    ? NetworkImage(
                                      (conversation.conversationWith as User)
                                          .avatar!,
                                    )
                                    : null
                                : (conversation.conversationWith as Group)
                                            .icon !=
                                        null &&
                                    (conversation.conversationWith as Group)
                                        .icon!
                                        .isNotEmpty
                                ? NetworkImage(
                                  (conversation.conversationWith as Group)
                                      .icon!,
                                )
                                : null,
                        child:
                            (conversation.conversationWith is User &&
                                        ((conversation.conversationWith as User)
                                                    .avatar ==
                                                null ||
                                            (conversation.conversationWith
                                                    as User)
                                                .avatar!
                                                .isEmpty)) ||
                                    (conversation.conversationWith is Group &&
                                        ((conversation.conversationWith
                                                        as Group)
                                                    .icon ==
                                                null ||
                                            (conversation.conversationWith
                                                    as Group)
                                                .icon!
                                                .isEmpty))
                                ? Icon(
                                  conversation.conversationWith is User
                                      ? Icons.person
                                      : Icons.group,
                                  color: Colors.white,
                                )
                                : null,
                      ),

                      if (conversation.conversationWith is User &&
                          isUserOnline(
                            (conversation.conversationWith as User).uid,
                          ))
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    conversation.conversationWith is User
                        ? (conversation.conversationWith as User).name
                        : (conversation.conversationWith as Group).name,
                    style: TextStyle(fontSize: 20, color: Colors.black),
                  ),
                  subtitle: Text(
                    typingUsers[conversationId] ??
                        getLastMessage(conversation.lastMessage),
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    formatTimestamp(conversation.lastMessage!.sentAt!),
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Adduserscreen()),
          ).then((_) {
            fetchUser();
            fetchConversations();
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.teal.shade900,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        ),
      ),
    );
  }
}

class HomeScreenMessageListener with MessageListener {
  final Function(TextMessage) onNewTextMessage;
  final Function(MediaMessage) onNewMediaMessage;
  final Function(TypingIndicator) onTypingStartedFunc;
  final Function(TypingIndicator) onTypingEndedFunc;
  final Function(BaseMessage) onMessageDelete;
  final Function(BaseMessage) onMessageEdit;

  HomeScreenMessageListener({
    required this.onNewTextMessage,
    required this.onNewMediaMessage,
    required this.onTypingStartedFunc,
    required this.onTypingEndedFunc,
    required this.onMessageDelete,
    required this.onMessageEdit,
  });

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
  void onMessagesRead(MessageReceipt receipt) {
    debugPrint("Message read: ${receipt.messageId}");
    // onMessageRead(receipt.messageId);
  }

  @override
  void onMessagesDelivered(MessageReceipt receipt) {
    debugPrint("Message delivered: ${receipt.messageId}");
    // onMessageDelivered(receipt.messageId);
  }

  @override
  void onMessageEdited(BaseMessage message) {
    onMessageEdit(message);
  }

  @override
  void onMessageDeleted(BaseMessage message) {
    onMessageDelete(message);
  }

  @override
  void onTypingStarted(TypingIndicator typingIndicator) {
    debugPrint("${typingIndicator.sender.uid} is typing...");
    onTypingStartedFunc(typingIndicator);
  }

  @override
  void onTypingEnded(TypingIndicator typingIndicator) {
    debugPrint("${typingIndicator.sender.uid}");
    onTypingEndedFunc(typingIndicator);
  }
}

class HomeScreen_UserPresenceListener with UserListener {
  final Function(User) onUserOnlineFunc;
  final Function(User) onUserOfflineFunc;

  HomeScreen_UserPresenceListener({
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
