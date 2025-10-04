import 'package:cloud_firestore/cloud_firestore.dart';

class Like {
  String? id;
  String? videoId;
  String? userId;
  String? username;
  String? profileImage;
  Timestamp? createdAt;

  Like({
    this.id,
    this.videoId,
    this.userId,
    this.username,
    this.profileImage,
    this.createdAt,
  });

  // To JSON (Firestore'a kaydetmek için)
  Map<String, dynamic> toJson() => {
    "id": id,
    "videoId": videoId,
    "userId": userId,
    "username": username,
    "profileImage": profileImage,
    "createdAt": createdAt,
  };

  // Firestore'dan Like objesi oluştur
  static Like fromSnap(DocumentSnapshot snapshot) {
    var dataSnapshot = snapshot.data() as Map<String, dynamic>;

    return Like(
      id: snapshot.id,
      videoId: dataSnapshot["videoId"],
      userId: dataSnapshot["userId"],
      username: dataSnapshot["username"],
      profileImage: dataSnapshot["profileImage"],
      createdAt: dataSnapshot["createdAt"],
    );
  }
}
