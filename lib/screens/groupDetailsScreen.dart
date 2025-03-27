import 'package:cometchat_sdk/builders/group_members_request.dart';
import 'package:cometchat_sdk/builders/users_request.dart';
import 'package:cometchat_sdk/exception/cometchat_exception.dart';
import 'package:cometchat_sdk/main/cometchat.dart';
import 'package:cometchat_sdk/models/conversation.dart';
import 'package:cometchat_sdk/models/group.dart';
import 'package:cometchat_sdk/models/group_member.dart';
import 'package:cometchat_sdk/models/user.dart';
import 'package:cometchat_sdk/utils/constants.dart';
import 'package:flutter/material.dart';

import '../listeners/groupMembersListener.dart';

class GroupDetailsScreen extends StatefulWidget {
  const GroupDetailsScreen({super.key, required this.group});

  final Group group;

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  List<GroupMember> groupMemberList = [];
  String? loggedInUserId;
  bool isAdmin = false;

  // Fetch logged-in user info
  Future<void> fetchLoggedInUser() async {
    try {
      User? user = await CometChat.getLoggedInUser();
      if (user != null) {
        setState(() {
          loggedInUserId = user.uid;
        });
        fetchGroupMembers(user.uid);
      }
    } catch (e) {
      debugPrint("Error fetching logged-in user: $e");
    }
  }

  void fetchGroupMembers(String userId) {
    String GUID = widget.group.guid;
    GroupMembersRequest groupMembersRequest =
        (GroupMembersRequestBuilder(GUID)..limit = 50).build();

    groupMembersRequest.fetchNext(
      onSuccess: (List<GroupMember> members) {
        debugPrint("Group Members fetched Successfully : $groupMemberList ");
        bool isUserAdmin = members.any(
          (member) => member.uid == userId && member.scope == "admin",
        );

        setState(() {
          groupMemberList = members;
          isAdmin = isUserAdmin;
        });
      },
      onError: (CometChatException e) {
        debugPrint("Delete Group failed with exception: ${e.message}");
      },
    );
  }

  // Leave group function
  void leaveGroup() async {
    String GUID = widget.group.guid;

    await CometChat.leaveGroup(
      GUID,
      onSuccess: (String returnResponse) {
        debugPrint("Group Left Successfully: $returnResponse");

        if (mounted) {
          Navigator.pop(context);
        }
        Navigator.pop(context);
      },
      onError: (CometChatException e) {
        debugPrint("Leaving group failed: ${e.message}");
      },
    );
  }

  //delete the group
  void deleteGroup() async {
    String GUID = widget.group.guid;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Group"),
          content: Text(
            "Are you sure you want to delete this group? This action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            InkWell(
              onTap: () {
                Navigator.pop(context); // Close the dialog first

                CometChat.deleteGroup(
                  GUID,
                  onSuccess: (String returnResponse) {
                    debugPrint("Deleted Group Successfully: $returnResponse");

                    if (mounted) {
                      Navigator.pop(context);
                    }
                    Navigator.pop(context);
                  },
                  onError: (CometChatException e) {
                    debugPrint("Delete Group failed: ${e.message}");
                  },
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.teal.shade900,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Delete Member",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  //kick member
  void kickMember(String uid) {
    String guid = widget.group.guid;

    CometChat.kickGroupMember(
      guid: guid,
      uid: uid,
      onSuccess: (String message) {
        debugPrint("Group Member Kicked  Successfully : $message");
        fetchLoggedInUser();
      },
      onError: (CometChatException e) {
        debugPrint("Group Member Kicked failed  : ${e.message}");
      },
    );
  }

  //ban member
  void banMember(String uid) {
    String guid = widget.group.guid;
    CometChat.banGroupMember(
      guid: guid,
      uid: uid,
      onSuccess: (String message) {
        debugPrint("Group Member Banned  Successfully : $message");
        fetchLoggedInUser();
      },
      onError: (CometChatException e) {
        debugPrint("Group Member Ban failed  : ${e.message}");
      },
    );
  }

  //Add member to the group
  void addMemberToGroup(String name, String uid, String scope) {
    String GUID = widget.group.guid;
    GroupMember newMember = GroupMember.fromUid(
      scope: scope,
      uid: uid,
      name: name,
    );

    CometChat.addMembersToGroup(
      guid: GUID,
      groupMembers: [newMember],
      onSuccess: (Map<String?, String?> result) {
        debugPrint("Group Member added Successfully: $result");
        fetchLoggedInUser();
      },
      onError: (CometChatException e) {
        debugPrint("Group Member addition failed: ${e.message}");
      },
    );
  }

  void showDialogForKickMember(String uid) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Kick"),
          content: Text(
            "Are you sure you want to remove this member from the group?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            InkWell(
              onTap: () {
                Navigator.pop(context); // Close the dialog
                kickMember(uid); // Call kick function
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.teal.shade900,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Kick Member",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void showDialogForBanMember(String uid) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Ban"),
          content: Text(
            "Are you sure you want to ban this member from the group?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            InkWell(
              onTap: () {
                Navigator.pop(context); // Close the dialog
                banMember(uid); // Call ban function
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.teal.shade900,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Ban Member",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /*void showDialogForAddingMember() {
    nameController.clear();
    uidController.clear();
    selectedScope = CometChatMemberScope.participant;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add Member"),
          content: Form(
            key: _addMemberFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Name",
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide(width: 2, color: Colors.black),
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? "Enter Name" : null,
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: uidController,
                  decoration: InputDecoration(
                    labelText: "User ID",
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide(width: 2, color: Colors.black),
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? "Enter User ID" : null,
                ),
                SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: selectedScope,
                  decoration: InputDecoration(
                    labelText: "Scope",
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide(width: 2, color: Colors.black),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: CometChatMemberScope.participant,
                      child: Text("Participant"),
                    ),
                    DropdownMenuItem(
                      value: CometChatMemberScope.moderator,
                      child: Text("Moderator"),
                    ),
                    DropdownMenuItem(
                      value: CometChatMemberScope.admin,
                      child: Text("Admin"),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedScope = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            InkWell(
              onTap: () {
                if (_addMemberFormKey.currentState!.validate()) {
                  addMemberToGroup(
                    nameController.text.trim(),
                    uidController.text.trim(),
                    selectedScope,
                  );
                  Navigator.pop(context);
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.teal.shade900,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Add Member",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }*/

  Future<void> showDialogForAddingMember() async {
    List<User> allUsers = [];
    List<String> groupMemberIds = [];
    List<User> usersNotInGroup = [];

    UsersRequest usersRequest = (UsersRequestBuilder()..limit = 25).build();

    await usersRequest.fetchNext(
      onSuccess: (List<User> userList) {
        debugPrint("User List Fetched Successfully : $userList");
        setState(() {
          allUsers = userList;
        });
      },
      onError: (CometChatException e) {
        debugPrint("User List Fetch Failed: ${e.message}");
      },
    );

    // Fetch group members
    // try {
    //   GroupMembersRequest membersRequest =
    //   GroupMembersRequestBuilder(groupId).build();
    //   List<GroupMember> groupMembers = await membersRequest.fetchNext();
    //   groupMemberIds = groupMembers.map((member) => member.uid).toList();
    // } catch (e) {
    //   debugPrint("Error fetching group members: $e");
    //   return;
    // }
    String GUID = widget.group.guid;
    GroupMembersRequest groupMembersRequest =
        (GroupMembersRequestBuilder(GUID)..limit = 50).build();

    await groupMembersRequest.fetchNext(
      onSuccess: (List<GroupMember> members) {
        debugPrint("Group Members fetched Successfully : $groupMemberList ");

        setState(() {
          groupMemberIds = members.map((member) => member.uid).toList();
          // Filter users who are not in the group
          usersNotInGroup =
              allUsers
                  .where((user) => !groupMemberIds.contains(user.uid))
                  .toList();
        });

        debugPrint("Users not in group: $usersNotInGroup");
      },
      onError: (CometChatException e) {
        debugPrint("Delete Group failed with exception: ${e.message}");
      },
    );
    debugPrint("Users not in group: $usersNotInGroup");

    // Show Dialog with list of users
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add Member"),
          content:
              usersNotInGroup.isEmpty
                  ? Text("No users available to add.")
                  : SizedBox(
                    width: double.maxFinite,
                    height: 200,
                    child: ListView.builder(
                      itemCount: usersNotInGroup.length,
                      itemBuilder: (context, index) {
                        User user = usersNotInGroup[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.teal.shade900,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                    user.avatar != null
                                        ? NetworkImage(user.avatar!)
                                        : null,
                                child:
                                    user.avatar == null
                                        ? Icon(
                                          Icons.person,
                                          color: Colors.white,
                                        )
                                        : null,
                              ),
                              title: Text(user.name,style: TextStyle(color: Colors.white),),
                              trailing: InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                  addMemberToGroup(
                                    user.name,
                                    user.uid,
                                    CometChatMemberScope.participant,
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 5,horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text("Add",style: TextStyle(color: Colors.black),),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void showKickOrBanAlert(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Alert"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.popUntil(
                  context,
                  (route) => route.isFirst,
                ); // Navigate to home screen
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    fetchLoggedInUser();

    CometChat.addGroupListener(
      "GROUP_LISTENER",
      GroupMemberListener(
        onMemberAdded: (User addedUser, Group addedTo) {
          fetchLoggedInUser();
        },
        onMemberKicked: (User kickedUser, User kickedBy, Group kickedFrom) {
          if (kickedUser.uid == loggedInUserId) {
            showKickOrBanAlert("You have been kicked from the group.");
          } else {
            fetchLoggedInUser();
          }
        },
        onMemberLeft: (User leftUser, Group leftGroup) {
          fetchLoggedInUser();
        },
        onMemberBanned: (User bannedUser, User bannedBy, Group bannedFrom) {
          if (bannedUser.uid == loggedInUserId) {
            showKickOrBanAlert("You have been banned from the group.");
          } else {
            fetchLoggedInUser();
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    CometChat.removeGroupListener("GROUP_LISTENER");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          color: Colors.black,
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 70,
                  backgroundImage:
                      widget.group.icon != null && widget.group.icon!.isNotEmpty
                          ? NetworkImage(widget.group.icon!)
                          : null,
                  child:
                      widget.group.icon == null || widget.group.icon!.isEmpty
                          ? Icon(Icons.group, size: 50, color: Colors.white)
                          : null,
                ),
                SizedBox(height: 10),
                Text(
                  widget.group.name,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 5),
                Text("Group - ${groupMemberList.length} participants"),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade900,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.teal.shade900,
                          width: 2,
                        ),
                      ),
                      child: Icon(Icons.call, color: Colors.white, size: 30),
                    ),
                    SizedBox(width: 20),
                    Container(
                      width: 70,
                      height: 70,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade900,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.teal.shade900,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.video_call,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    if (isAdmin) SizedBox(width: 20),
                    isAdmin
                        ? InkWell(
                          onTap: () {
                            showDialogForAddingMember();
                          },
                          child: Container(
                            width: 70,
                            height: 70,
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade900,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.teal.shade900,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.group_add,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        )
                        : SizedBox(),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white),
              child: ListView.builder(
                itemCount: groupMemberList.length,
                itemBuilder: (context, index) {
                  GroupMember groupMember = groupMemberList[index];
                  bool isCurrentUser = groupMember.uid == loggedInUserId;
                  bool isGroupAdmin = groupMember.scope == "admin";

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: 60,
                      padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade900,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: groupMember.avatar != null?NetworkImage(
                                  groupMember.avatar!,
                                ):null,
                              ),
                              SizedBox(width: 10),
                              Text(
                                groupMember.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                ),
                              ),
                              SizedBox(width: 10),
                              if (isGroupAdmin)
                                Text(
                                  "Admin",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 15,
                                  ),
                                ),
                            ],
                          ),
                          isAdmin && !isCurrentUser
                              ? Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      showDialogForBanMember(groupMember.uid);
                                    },
                                    icon: Icon(
                                      Icons.block_rounded,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      showDialogForKickMember(groupMember.uid);
                                    },
                                    icon: Icon(
                                      Icons.delete_outline_outlined,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              )
                              : SizedBox(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    leaveGroup();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.door_back_door_outlined,
                            color: Colors.redAccent,
                            size: 30,
                          ),
                          SizedBox(width: 10),
                          Text("Leave Group", style: TextStyle(fontSize: 20)),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                isAdmin
                    ? InkWell(
                      onTap: deleteGroup,
                      child: Container(
                        width: double.infinity,
                        height: 60,
                        padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.delete_outline_outlined,
                                color: Colors.redAccent,
                                size: 30,
                              ),
                              SizedBox(width: 10),
                              Text(
                                "Delete Group",
                                style: TextStyle(fontSize: 20),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    : SizedBox(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
