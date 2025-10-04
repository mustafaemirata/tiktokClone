import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  String? id;
  String? videoId;
  String? userId;
  String? username;
  String? profileImage;
  String? text;
  String? parentCommentId; // Cevaplama için
  List<String>? likes;
  int? likeCount;
  Timestamp? createdAt;

  Comment({
    this.id,
    this.videoId,
    this.userId,
    this.username,
    this.profileImage,
    this.text,
    this.parentCommentId,
    this.likes,
    this.likeCount,
    this.createdAt,
  });

  // To JSON (Firestore'a kaydetmek için)
  Map<String, dynamic> toJson() => {
    "id": id,
    "videoId": videoId,
    "userId": userId,
    "username": username,
    "profileImage": profileImage,
    "text": text,
    "parentCommentId": parentCommentId,
    "likes": likes ?? [],
    "likeCount": likeCount ?? 0,
    "createdAt": createdAt,
  };

  // Firestore'dan Comment objesi oluştur
  static Comment fromSnap(DocumentSnapshot snapshot) {
    var dataSnapshot = snapshot.data() as Map<String, dynamic>;

    return Comment(
      id: snapshot.id,
      videoId: dataSnapshot["videoId"],
      userId: dataSnapshot["userId"],
      username: dataSnapshot["username"],
      profileImage: dataSnapshot["profileImage"],
      text: dataSnapshot["text"],
      parentCommentId: dataSnapshot["parentCommentId"],
      likes: List<String>.from(dataSnapshot["likes"] ?? []),
      likeCount: dataSnapshot["likeCount"] ?? 0,
      createdAt: dataSnapshot["createdAt"],
    );
  }

  // Comment'i güncelle
  Comment copyWith({
    String? id,
    String? videoId,
    String? userId,
    String? username,
    String? profileImage,
    String? text,
    String? parentCommentId,
    List<String>? likes,
    int? likeCount,
    Timestamp? createdAt,
  }) {
    return Comment(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      profileImage: profileImage ?? this.profileImage,
      text: text ?? this.text,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      likes: likes ?? this.likes,
      likeCount: likeCount ?? this.likeCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
