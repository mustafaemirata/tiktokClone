import 'package:cloud_firestore/cloud_firestore.dart';

class Follow {
  String? id;
  String? followerId; // Takip eden kişi
  String? followingId; // Takip edilen kişi
  String? followerName;
  String? followerImage;
  String? followingName;
  String? followingImage;
  Timestamp? createdAt;

  Follow({
    this.id,
    this.followerId,
    this.followingId,
    this.followerName,
    this.followerImage,
    this.followingName,
    this.followingImage,
    this.createdAt,
  });

  // To JSON (Firestore'a kaydetmek için)
  Map<String, dynamic> toJson() => {
    "id": id,
    "followerId": followerId,
    "followingId": followingId,
    "followerName": followerName,
    "followerImage": followerImage,
    "followingName": followingName,
    "followingImage": followingImage,
    "createdAt": createdAt,
  };

  // Firestore'dan Follow objesi oluştur
  static Follow fromSnap(DocumentSnapshot snapshot) {
    var dataSnapshot = snapshot.data() as Map<String, dynamic>;

    return Follow(
      id: snapshot.id,
      followerId: dataSnapshot["followerId"],
      followingId: dataSnapshot["followingId"],
      followerName: dataSnapshot["followerName"],
      followerImage: dataSnapshot["followerImage"],
      followingName: dataSnapshot["followingName"],
      followingImage: dataSnapshot["followingImage"],
      createdAt: dataSnapshot["createdAt"],
    );
  }
}
