import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  String? name;
  String? uid;
  String? image;
  String? email;
  String? bio;
  String? youtube;
  String? facebook;
  String? x;
  String? instagram;
  int? followersCount;
  int? followingCount;
  int? videosCount;
  int? totalLikes;
  int? totalViews;
  bool? isVerified;
  bool? isPrivate;
  Timestamp? createdAt;
  Timestamp? lastLogin;

  User({
    this.name,
    this.uid,
    this.image,
    this.email,
    this.bio,
    this.youtube,
    this.facebook,
    this.x,
    this.instagram,
    this.followersCount,
    this.followingCount,
    this.videosCount,
    this.totalLikes,
    this.totalViews,
    this.isVerified,
    this.isPrivate,
    this.createdAt,
    this.lastLogin,
  });

  // To JSON (Firestore'a kaydetmek için)
  Map<String, dynamic> toJson() => {
    "name": name,
    "uid": uid,
    "image": image,
    "email": email,
    "bio": bio,
    "youtube": youtube,
    "facebook": facebook,
    "x": x,
    "instagram": instagram,
    "followersCount": followersCount ?? 0,
    "followingCount": followingCount ?? 0,
    "videosCount": videosCount ?? 0,
    "totalLikes": totalLikes ?? 0,
    "totalViews": totalViews ?? 0,
    "isVerified": isVerified ?? false,
    "isPrivate": isPrivate ?? false,
    "createdAt": createdAt,
    "lastLogin": lastLogin,
  };

  // Firestore'dan User objesi oluştur
  static User fromSnap(DocumentSnapshot snapshot) {
    var dataSnapshot = snapshot.data() as Map<String, dynamic>;

    return User(
      name: dataSnapshot["name"],
      uid: dataSnapshot["uid"],
      image: dataSnapshot["image"],
      email: dataSnapshot["email"],
      bio: dataSnapshot["bio"],
      youtube: dataSnapshot["youtube"],
      facebook: dataSnapshot["facebook"],
      x: dataSnapshot["x"],
      instagram: dataSnapshot["instagram"],
      followersCount: dataSnapshot["followersCount"] ?? 0,
      followingCount: dataSnapshot["followingCount"] ?? 0,
      videosCount: dataSnapshot["videosCount"] ?? 0,
      totalLikes: dataSnapshot["totalLikes"] ?? 0,
      totalViews: dataSnapshot["totalViews"] ?? 0,
      isVerified: dataSnapshot["isVerified"] ?? false,
      isPrivate: dataSnapshot["isPrivate"] ?? false,
      createdAt: dataSnapshot["createdAt"],
      lastLogin: dataSnapshot["lastLogin"],
    );
  }
}
