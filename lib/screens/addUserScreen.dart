import 'package:cometchat_sdk/cometchat_sdk.dart';
import 'package:flutter/material.dart';
import 'package:my_first_app/screens/chatScreen.dart';

class Adduserscreen extends StatefulWidget {
  const Adduserscreen({super.key});

  @override
  State<Adduserscreen> createState() => _AdduserscreenState();
}

class _AdduserscreenState extends State<Adduserscreen> {
  List<User> users = [];
  late UsersRequest usersRequest;

  void fetchUsers() {
    usersRequest = (UsersRequestBuilder()..limit = 25).build();

    usersRequest.fetchNext(
      onSuccess: (List<User> userList) {
        debugPrint("User List Fetched Successfully : $userList");
        setState(() {
          users = userList;
        });
      },
      onError: (CometChatException e) {
        debugPrint("User List Fetch Failed: ${e.message}");
      },
    );
  }

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_rounded),
          color: Colors.white,
        ),
        title: Text(
          "Add User",
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.teal.shade900,
      ),
      body: Container(
        decoration: BoxDecoration(color: Colors.white),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  User userData = users[index];
                  return InkWell(
                    onTap: () {
                      Conversation conversation = Conversation(
                        conversationWith: userData,
                        conversationType: CometChatConversationType.user,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  Chatscreen(conversation: conversation),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.black12.withOpacity(0.1),
                          ),
                        ),
                      ),
                      width: double.infinity,
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 11,
                          horizontal: 10,
                        ),
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundImage: NetworkImage(userData.avatar!),
                        ),
                        title: Text(
                          userData.name,
                          style: TextStyle(color: Colors.black, fontSize: 20),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
