import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  String? id;
  String? userId; // Bildirimi alan kullanıcı
  String? fromUserId; // Bildirimi gönderen kullanıcı
  String? fromUserName;
  String? fromUserImage;
  String? type; // 'like', 'comment', 'follow', 'mention', 'video_shared'
  String? title;
  String? body;
  String? videoId;
  String? commentId;
  bool? isRead;
  Timestamp? createdAt;

  AppNotification({
    this.id,
    this.userId,
    this.fromUserId,
    this.fromUserName,
    this.fromUserImage,
    this.type,
    this.title,
    this.body,
    this.videoId,
    this.commentId,
    this.isRead,
    this.createdAt,
  });

  // To JSON (Firestore'a kaydetmek için)
  Map<String, dynamic> toJson() => {
    "id": id,
    "userId": userId,
    "fromUserId": fromUserId,
    "fromUserName": fromUserName,
    "fromUserImage": fromUserImage,
    "type": type,
    "title": title,
    "body": body,
    "videoId": videoId,
    "commentId": commentId,
    "isRead": isRead ?? false,
    "createdAt": createdAt,
  };

  // Firestore'dan AppNotification objesi oluştur
  static AppNotification fromSnap(DocumentSnapshot snapshot) {
    var dataSnapshot = snapshot.data() as Map<String, dynamic>;

    return AppNotification(
      id: snapshot.id,
      userId: dataSnapshot["userId"],
      fromUserId: dataSnapshot["fromUserId"],
      fromUserName: dataSnapshot["fromUserName"],
      fromUserImage: dataSnapshot["fromUserImage"],
      type: dataSnapshot["type"],
      title: dataSnapshot["title"],
      body: dataSnapshot["body"],
      videoId: dataSnapshot["videoId"],
      commentId: dataSnapshot["commentId"],
      isRead: dataSnapshot["isRead"] ?? false,
      createdAt: dataSnapshot["createdAt"],
    );
  }

  // Bildirim tipine göre başlık ve içerik oluştur
  static Map<String, String> getNotificationContent(
    String type,
    String fromUserName,
  ) {
    switch (type) {
      case 'like':
        return {
          'title': 'Yeni Beğeni',
          'body': '$fromUserName videonuzu beğendi',
        };
      case 'comment':
        return {
          'title': 'Yeni Yorum',
          'body': '$fromUserName videonuzu yorumladı',
        };
      case 'follow':
        return {
          'title': 'Yeni Takipçi',
          'body': '$fromUserName sizi takip etmeye başladı',
        };
      case 'mention':
        return {
          'title': 'Bahsedildiniz',
          'body': '$fromUserName sizi bahsetti',
        };
      case 'video_shared':
        return {
          'title': 'Video Paylaşıldı',
          'body': '$fromUserName videonuzu paylaştı',
        };
      default:
        return {'title': 'Yeni Bildirim', 'body': 'Yeni bir bildiriminiz var'};
    }
  }
}
