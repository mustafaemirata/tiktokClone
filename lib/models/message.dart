import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  String? id;
  String? senderId;
  String? receiverId;
  String? text;
  String? type; // 'text', 'image', 'video', 'emoji'
  String? mediaUrl;
  bool? isRead;
  Timestamp? createdAt;
  String? senderName;
  String? senderImage;

  Message({
    this.id,
    this.senderId,
    this.receiverId,
    this.text,
    this.type,
    this.mediaUrl,
    this.isRead,
    this.createdAt,
    this.senderName,
    this.senderImage,
  });

  // To JSON (Firestore'a kaydetmek için)
  Map<String, dynamic> toJson() => {
    "id": id,
    "senderId": senderId,
    "receiverId": receiverId,
    "text": text,
    "type": type ?? 'text',
    "mediaUrl": mediaUrl,
    "isRead": isRead ?? false,
    "createdAt": createdAt,
    "senderName": senderName,
    "senderImage": senderImage,
  };

  // Firestore'dan Message objesi oluştur
  static Message fromSnap(DocumentSnapshot snapshot) {
    var dataSnapshot = snapshot.data() as Map<String, dynamic>;

    return Message(
      id: snapshot.id,
      senderId: dataSnapshot["senderId"],
      receiverId: dataSnapshot["receiverId"],
      text: dataSnapshot["text"],
      type: dataSnapshot["type"] ?? 'text',
      mediaUrl: dataSnapshot["mediaUrl"],
      isRead: dataSnapshot["isRead"] ?? false,
      createdAt: dataSnapshot["createdAt"],
      senderName: dataSnapshot["senderName"],
      senderImage: dataSnapshot["senderImage"],
    );
  }
}

class Conversation {
  String? id;
  String? lastMessage;
  String? lastMessageType;
  Timestamp? lastMessageTime;
  String? lastMessageSenderId;
  bool? hasUnreadMessages;
  int? unreadCount;
  List<String>? participants;
  Map<String, dynamic>? participantData; // Kullanıcı bilgileri

  Conversation({
    this.id,
    this.lastMessage,
    this.lastMessageType,
    this.lastMessageTime,
    this.lastMessageSenderId,
    this.hasUnreadMessages,
    this.unreadCount,
    this.participants,
    this.participantData,
  });

  // To JSON (Firestore'a kaydetmek için)
  Map<String, dynamic> toJson() => {
    "id": id,
    "lastMessage": lastMessage,
    "lastMessageType": lastMessageType ?? 'text',
    "lastMessageTime": lastMessageTime,
    "lastMessageSenderId": lastMessageSenderId,
    "hasUnreadMessages": hasUnreadMessages ?? false,
    "unreadCount": unreadCount ?? 0,
    "participants": participants ?? [],
    "participantData": participantData ?? {},
  };

  // Firestore'dan Conversation objesi oluştur
  static Conversation fromSnap(DocumentSnapshot snapshot) {
    var dataSnapshot = snapshot.data() as Map<String, dynamic>;

    return Conversation(
      id: snapshot.id,
      lastMessage: dataSnapshot["lastMessage"],
      lastMessageType: dataSnapshot["lastMessageType"] ?? 'text',
      lastMessageTime: dataSnapshot["lastMessageTime"],
      lastMessageSenderId: dataSnapshot["lastMessageSenderId"],
      hasUnreadMessages: dataSnapshot["hasUnreadMessages"] ?? false,
      unreadCount: dataSnapshot["unreadCount"] ?? 0,
      participants: List<String>.from(dataSnapshot["participants"] ?? []),
      participantData: dataSnapshot["participantData"] ?? {},
    );
  }
}
