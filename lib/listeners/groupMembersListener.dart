import 'package:cometchat_sdk/cometchat_sdk.dart';
import 'package:flutter/material.dart' hide Action;

class GroupMemberListener with GroupListener {
  final Function(User, Group) onMemberAdded;
  final Function(User, User, Group) onMemberKicked;
  final Function(User, Group) onMemberLeft;
  final Function(User, User, Group) onMemberBanned;

  GroupMemberListener({
    required this.onMemberLeft,
    required this.onMemberAdded,
    required this.onMemberKicked,
    required this.onMemberBanned,
  });

  @override
  void onMemberAddedToGroup(
    Action action,
    User addedby,
    User userAdded,
    Group addedTo,
  ) {
    debugPrint("onMemberAddedToGroup called");
    debugPrint(
      "${userAdded.name} was added to ${addedTo.name} by ${addedby.name}",
    );
    onMemberAdded(userAdded, addedTo);
  }

  @override
  void onGroupMemberKicked(Action action, User kickedUser, User kickedBy, Group kickedFrom) {
    debugPrint("onGroupMemberKicked called");
    onMemberKicked(kickedUser, kickedBy, kickedFrom);

  }

  @override
  void onGroupMemberLeft(Action action, User leftUser, Group leftGroup) {
    debugPrint("onGroupMemberLeft called");
    onMemberLeft(leftUser, leftGroup);
  }

  @override
  void onGroupMemberBanned(Action action, User bannedUser, User bannedBy, Group bannedFrom) {
    debugPrint("onGroupMemberBanned called");
    onMemberBanned(bannedUser, bannedBy, bannedFrom);
  }



}
