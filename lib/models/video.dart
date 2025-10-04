import 'package:cloud_firestore/cloud_firestore.dart';

class Video {
  String? id;
  String? uid;
  String? username;
  String? profileImage;
  String? videoUrl;
  String? thumbnailUrl;
  String? title;
  String? description;
  List<String>? hashtags;
  int? likes;
  int? comments;
  int? shares;
  int? views;
  Timestamp? createdAt;
  bool? isLiked;
  bool? isFollowing;

  Video({
    this.id,
    this.uid,
    this.username,
    this.profileImage,
    this.videoUrl,
    this.thumbnailUrl,
    this.title,
    this.description,
    this.hashtags,
    this.likes,
    this.comments,
    this.shares,
    this.views,
    this.createdAt,
    this.isLiked,
    this.isFollowing,
  });

  // To JSON (Firestore'a kaydetmek için)
  Map<String, dynamic> toJson() => {
    "id": id,
    "uid": uid,
    "username": username,
    "profileImage": profileImage,
    "videoUrl": videoUrl,
    "thumbnailUrl": thumbnailUrl,
    "title": title,
    "description": description,
    "hashtags": hashtags,
    "likes": likes ?? 0,
    "comments": comments ?? 0,
    "shares": shares ?? 0,
    "views": views ?? 0,
    "createdAt": createdAt,
  };

  // Firestore'dan Video objesi oluştur
  static Video fromSnap(DocumentSnapshot snapshot) {
    var dataSnapshot = snapshot.data() as Map<String, dynamic>;

    return Video(
      id: snapshot.id,
      uid: dataSnapshot["uid"],
      username: dataSnapshot["username"],
      profileImage: dataSnapshot["profileImage"],
      videoUrl: dataSnapshot["videoUrl"],
      thumbnailUrl: dataSnapshot["thumbnailUrl"],
      title: dataSnapshot["title"],
      description: dataSnapshot["description"],
      hashtags: List<String>.from(dataSnapshot["hashtags"] ?? []),
      likes: dataSnapshot["likes"] ?? 0,
      comments: dataSnapshot["comments"] ?? 0,
      shares: dataSnapshot["shares"] ?? 0,
      views: dataSnapshot["views"] ?? 0,
      createdAt: dataSnapshot["createdAt"],
    );
  }

  // Video'yu güncelle
  Video copyWith({
    String? id,
    String? uid,
    String? username,
    String? profileImage,
    String? videoUrl,
    String? thumbnailUrl,
    String? title,
    String? description,
    List<String>? hashtags,
    int? likes,
    int? comments,
    int? shares,
    int? views,
    Timestamp? createdAt,
    bool? isLiked,
    bool? isFollowing,
  }) {
    return Video(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      username: username ?? this.username,
      profileImage: profileImage ?? this.profileImage,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      hashtags: hashtags ?? this.hashtags,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      views: views ?? this.views,
      createdAt: createdAt ?? this.createdAt,
      isLiked: isLiked ?? this.isLiked,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}
