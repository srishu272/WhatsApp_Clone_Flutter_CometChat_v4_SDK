import 'package:cometchat_sdk/cometchat_sdk.dart';
import 'package:flutter/material.dart';

class ThreadMessageListener with MessageListener {
  final int activeParentMessageId;
  final Function(BaseMessage) onMessageReceived;
  final Function(BaseMessage) onMessageEditedFunc;
  final Function(BaseMessage) onMessageDeletedFunc;

  ThreadMessageListener({
    required this.activeParentMessageId,
    required this.onMessageReceived,
    required this.onMessageEditedFunc,
    required this.onMessageDeletedFunc,
  });

  @override
  void onTextMessageReceived(TextMessage textMessage) {
    if (textMessage.parentMessageId == activeParentMessageId) {
      debugPrint("Text message received successfully: ${textMessage.text}");
      onMessageReceived(textMessage);
    }
  }

  @override
  void onMediaMessageReceived(MediaMessage mediaMessage) {
    if (mediaMessage.parentMessageId == activeParentMessageId) {
      debugPrint("Media message received successfully");
      onMessageReceived(mediaMessage);
    }
  }

  @override
  void onCustomMessageReceived(CustomMessage customMessage) {
    if (customMessage.parentMessageId == activeParentMessageId) {
      debugPrint("Custom message received successfully");
      onMessageReceived(customMessage);
    }
  }

  @override
  void onMessageEdited(BaseMessage message) {
    if (message.parentMessageId == activeParentMessageId) {
      debugPrint("Message edited: ${message.id}");
      onMessageEditedFunc(message);
    }
  }

  @override
  void onMessageDeleted(BaseMessage message) {
    if (message.parentMessageId == activeParentMessageId) {
      debugPrint("Message deleted: ${message.id}");
      onMessageDeletedFunc(message);
    }

  }
}
