import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:cloneshorts/models/video.dart';
import 'package:cloneshorts/models/comment.dart';
import 'package:cloneshorts/models/follow.dart';
import 'package:cloneshorts/models/message.dart';
import 'package:cloneshorts/models/notification.dart';
import 'package:cloneshorts/authentication/user.dart' as app_user;

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcı verilerini kaydet
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı bulunamadı');

      await _firestore.collection("users").doc(user.uid).set(userData);

      // Timestamp alanlarını ekle
      await _firestore.collection("users").doc(user.uid).update({
        "createdAt": FieldValue.serverTimestamp(),
        "lastLogin": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Get.snackbar("Hata", "Veri kaydedilemedi: $e");
      rethrow;
    }
  }

  // Kullanıcı verilerini al
  static Future<DocumentSnapshot?> getUserData(String uid) async {
    try {
      return await _firestore.collection("users").doc(uid).get();
    } catch (e) {
      Get.snackbar("Hata", "Kullanıcı verileri alınamadı: $e");
      return null;
    }
  }

  // Son giriş tarihini güncelle
  static Future<void> updateLastLogin(String uid) async {
    try {
      await _firestore.collection("users").doc(uid).update({
        "lastLogin": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Get.snackbar("Hata", "Son giriş tarihi güncellenemedi: $e");
    }
  }

  // Kullanıcı verilerini güncelle
  static Future<void> updateUserData(
    String uid,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection("users").doc(uid).update(data);
    } catch (e) {
      Get.snackbar("Hata", "Veri güncellenemedi: $e");
      rethrow;
    }
  }

  // Kullanıcı hesabını sil
  static Future<void> deleteUserData(String uid) async {
    try {
      await _firestore.collection("users").doc(uid).delete();
    } catch (e) {
      Get.snackbar("Hata", "Kullanıcı verileri silinemedi: $e");
      rethrow;
    }
  }

  // ========== VIDEO SERVİSLERİ ==========

  // Video yükle
  static Future<String> uploadVideo(Video video) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı bulunamadı');

      final docRef = await _firestore.collection("videos").add({
        "uid": user.uid,
        "username": video.username,
        "profileImage": video.profileImage,
        "videoUrl": video.videoUrl,
        "thumbnailUrl": video.thumbnailUrl,
        "title": video.title,
        "description": video.description,
        "hashtags": video.hashtags ?? [],
        "likes": 0,
        "comments": 0,
        "shares": 0,
        "views": 0,
        "createdAt": FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      Get.snackbar("Hata", "Video yüklenemedi: $e");
      rethrow;
    }
  }

  // Videoları getir (feed için)
  static Future<List<Video>> getVideos({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection("videos")
          .orderBy("createdAt", descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) => Video.fromSnap(doc)).toList();
    } catch (e) {
      Get.snackbar("Hata", "Videolar alınamadı: $e");
      return [];
    }
  }

  // Kullanıcının videolarını getir
  static Future<List<Video>> getUserVideos(String uid) async {
    try {
      final querySnapshot = await _firestore
          .collection("videos")
          .where("uid", isEqualTo: uid)
          .orderBy("createdAt", descending: true)
          .get();

      return querySnapshot.docs.map((doc) => Video.fromSnap(doc)).toList();
    } catch (e) {
      Get.snackbar("Hata", "Kullanıcı videoları alınamadı: $e");
      return [];
    }
  }

  // Video görüntülenme sayısını artır
  static Future<void> incrementVideoViews(String videoId) async {
    try {
      await _firestore.collection("videos").doc(videoId).update({
        "views": FieldValue.increment(1),
      });
    } catch (e) {
      Get.snackbar("Hata", "Görüntülenme sayısı artırılamadı: $e");
    }
  }

  // ========== BEĞENİ SERVİSLERİ ==========

  // Video beğen
  static Future<void> likeVideo(String videoId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı bulunamadı');

      final userData = await getUserData(user.uid);
      if (userData == null) throw Exception('Kullanıcı verileri bulunamadı');

      final userDataMap = userData.data() as Map<String, dynamic>;

      // Beğeni kaydını ekle
      await _firestore.collection("likes").add({
        "videoId": videoId,
        "userId": user.uid,
        "username": userDataMap["name"],
        "profileImage": userDataMap["image"],
        "createdAt": FieldValue.serverTimestamp(),
      });

      // Video beğeni sayısını artır
      await _firestore.collection("videos").doc(videoId).update({
        "likes": FieldValue.increment(1),
      });
    } catch (e) {
      Get.snackbar("Hata", "Video beğenilemedi: $e");
      rethrow;
    }
  }

  // Video beğenisini kaldır
  static Future<void> unlikeVideo(String videoId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı bulunamadı');

      // Beğeni kaydını bul ve sil
      final querySnapshot = await _firestore
          .collection("likes")
          .where("videoId", isEqualTo: videoId)
          .where("userId", isEqualTo: user.uid)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      // Video beğeni sayısını azalt
      await _firestore.collection("videos").doc(videoId).update({
        "likes": FieldValue.increment(-1),
      });
    } catch (e) {
      Get.snackbar("Hata", "Beğeni kaldırılamadı: $e");
      rethrow;
    }
  }

  // Kullanıcının video beğenip beğenmediğini kontrol et
  static Future<bool> isVideoLiked(String videoId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final querySnapshot = await _firestore
          .collection("likes")
          .where("videoId", isEqualTo: videoId)
          .where("userId", isEqualTo: user.uid)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ========== YORUM SERVİSLERİ ==========

  // Yorum ekle
  static Future<String> addComment(Comment comment) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı bulunamadı');

      final userData = await getUserData(user.uid);
      if (userData == null) throw Exception('Kullanıcı verileri bulunamadı');

      final userDataMap = userData.data() as Map<String, dynamic>;

      final docRef = await _firestore.collection("comments").add({
        "videoId": comment.videoId,
        "userId": user.uid,
        "username": userDataMap["name"],
        "profileImage": userDataMap["image"],
        "text": comment.text,
        "parentCommentId": comment.parentCommentId,
        "likes": [],
        "likeCount": 0,
        "createdAt": FieldValue.serverTimestamp(),
      });

      // Video yorum sayısını artır
      await _firestore.collection("videos").doc(comment.videoId).update({
        "comments": FieldValue.increment(1),
      });

      return docRef.id;
    } catch (e) {
      Get.snackbar("Hata", "Yorum eklenemedi: $e");
      rethrow;
    }
  }

  // Video yorumlarını getir
  static Future<List<Comment>> getVideoComments(String videoId) async {
    try {
      final querySnapshot = await _firestore
          .collection("comments")
          .where("videoId", isEqualTo: videoId)
          .where("parentCommentId", isNull: true) // Ana yorumlar
          .orderBy("createdAt", descending: true)
          .get();

      return querySnapshot.docs.map((doc) => Comment.fromSnap(doc)).toList();
    } catch (e) {
      Get.snackbar("Hata", "Yorumlar alınamadı: $e");
      return [];
    }
  }

  // Yorum cevaplarını getir
  static Future<List<Comment>> getCommentReplies(String parentCommentId) async {
    try {
      final querySnapshot = await _firestore
          .collection("comments")
          .where("parentCommentId", isEqualTo: parentCommentId)
          .orderBy("createdAt")
          .get();

      return querySnapshot.docs.map((doc) => Comment.fromSnap(doc)).toList();
    } catch (e) {
      Get.snackbar("Hata", "Yorum cevapları alınamadı: $e");
      return [];
    }
  }

  // Yorum beğen
  static Future<void> likeComment(String commentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı bulunamadı');

      await _firestore.collection("comments").doc(commentId).update({
        "likes": FieldValue.arrayUnion([user.uid]),
        "likeCount": FieldValue.increment(1),
      });
    } catch (e) {
      Get.snackbar("Hata", "Yorum beğenilemedi: $e");
      rethrow;
    }
  }

  // Yorum beğenisini kaldır
  static Future<void> unlikeComment(String commentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı bulunamadı');

      await _firestore.collection("comments").doc(commentId).update({
        "likes": FieldValue.arrayRemove([user.uid]),
        "likeCount": FieldValue.increment(-1),
      });
    } catch (e) {
      Get.snackbar("Hata", "Yorum beğenisi kaldırılamadı: $e");
      rethrow;
    }
  }

  // ========== TAKİP SERVİSLERİ ==========

  // Kullanıcıyı takip et
  static Future<void> followUser(String followingId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı bulunamadı');

      final followerData = await getUserData(user.uid);
      final followingData = await getUserData(followingId);

      if (followerData == null || followingData == null) {
        throw Exception('Kullanıcı verileri bulunamadı');
      }

      final followerDataMap = followerData.data() as Map<String, dynamic>;
      final followingDataMap = followingData.data() as Map<String, dynamic>;

      // Takip kaydını ekle
      await _firestore.collection("follows").add({
        "followerId": user.uid,
        "followingId": followingId,
        "followerName": followerDataMap["name"],
        "followerImage": followerDataMap["image"],
        "followingName": followingDataMap["name"],
        "followingImage": followingDataMap["image"],
        "createdAt": FieldValue.serverTimestamp(),
      });

      // Kullanıcı takip sayılarını güncelle
      await _firestore.collection("users").doc(user.uid).update({
        "followingCount": FieldValue.increment(1),
      });

      await _firestore.collection("users").doc(followingId).update({
        "followersCount": FieldValue.increment(1),
      });
    } catch (e) {
      Get.snackbar("Hata", "Kullanıcı takip edilemedi: $e");
      rethrow;
    }
  }

  // Kullanıcıyı takipten çıkar
  static Future<void> unfollowUser(String followingId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı bulunamadı');

      // Takip kaydını bul ve sil
      final querySnapshot = await _firestore
          .collection("follows")
          .where("followerId", isEqualTo: user.uid)
          .where("followingId", isEqualTo: followingId)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      // Kullanıcı takip sayılarını güncelle
      await _firestore.collection("users").doc(user.uid).update({
        "followingCount": FieldValue.increment(-1),
      });

      await _firestore.collection("users").doc(followingId).update({
        "followersCount": FieldValue.increment(-1),
      });
    } catch (e) {
      Get.snackbar("Hata", "Takip kaldırılamadı: $e");
      rethrow;
    }
  }

  // Kullanıcının takip edip etmediğini kontrol et
  static Future<bool> isFollowing(String followingId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final querySnapshot = await _firestore
          .collection("follows")
          .where("followerId", isEqualTo: user.uid)
          .where("followingId", isEqualTo: followingId)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Takip edilen kullanıcıların videolarını getir
  static Future<List<Video>> getFollowingVideos() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // Takip edilen kullanıcıları getir
      final followsSnapshot = await _firestore
          .collection("follows")
          .where("followerId", isEqualTo: user.uid)
          .get();

      if (followsSnapshot.docs.isEmpty) return [];

      final followingIds = followsSnapshot.docs
          .map((doc) => doc.data()["followingId"] as String)
          .toList();

      // Takip edilen kullanıcıların videolarını getir
      final videosSnapshot = await _firestore
          .collection("videos")
          .where("uid", whereIn: followingIds)
          .orderBy("createdAt", descending: true)
          .limit(20)
          .get();

      return videosSnapshot.docs.map((doc) => Video.fromSnap(doc)).toList();
    } catch (e) {
      Get.snackbar("Hata", "Takip edilen videolar alınamadı: $e");
      return [];
    }
  }

  // Takipçileri getir
  static Future<List<Follow>> getFollowers(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection("follows")
          .where("followingId", isEqualTo: userId)
          .orderBy("createdAt", descending: true)
          .get();

      return querySnapshot.docs.map((doc) => Follow.fromSnap(doc)).toList();
    } catch (e) {
      Get.snackbar("Hata", "Takipçiler alınamadı: $e");
      return [];
    }
  }

  // Takip edilenleri getir
  static Future<List<Follow>> getFollowing(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection("follows")
          .where("followerId", isEqualTo: userId)
          .orderBy("createdAt", descending: true)
          .get();

      return querySnapshot.docs.map((doc) => Follow.fromSnap(doc)).toList();
    } catch (e) {
      Get.snackbar("Hata", "Takip edilenler alınamadı: $e");
      return [];
    }
  }

  // ========== ARAMA SERVİSLERİ ==========

  // Video arama
  static Future<List<Video>> searchVideos(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection("videos")
          .where("title", isGreaterThanOrEqualTo: query)
          .where("title", isLessThan: '${query}z')
          .orderBy("title")
          .limit(20)
          .get();

      return querySnapshot.docs.map((doc) => Video.fromSnap(doc)).toList();
    } catch (e) {
      Get.snackbar("Hata", "Video arama yapılamadı: $e");
      return [];
    }
  }

  // Kullanıcı arama
  static Future<List<app_user.User>> searchUsers(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection("users")
          .where("name", isGreaterThanOrEqualTo: query)
          .where("name", isLessThan: '${query}z')
          .orderBy("name")
          .limit(20)
          .get();

      return querySnapshot.docs
          .map((doc) => app_user.User.fromSnap(doc))
          .toList();
    } catch (e) {
      Get.snackbar("Hata", "Kullanıcı arama yapılamadı: $e");
      return [];
    }
  }

  // ========== MESAJLAŞMA SERVİSLERİ ==========

  // Mesaj gönder
  static Future<String> sendMessage(Message message) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı bulunamadı');

      final userData = await getUserData(user.uid);
      if (userData == null) throw Exception('Kullanıcı verileri bulunamadı');

      final userDataMap = userData.data() as Map<String, dynamic>;

      final docRef = await _firestore.collection("messages").add({
        "senderId": user.uid,
        "receiverId": message.receiverId,
        "text": message.text,
        "type": message.type ?? 'text',
        "mediaUrl": message.mediaUrl,
        "isRead": false,
        "createdAt": FieldValue.serverTimestamp(),
        "senderName": userDataMap["name"],
        "senderImage": userDataMap["image"],
      });

      // Konuşmayı güncelle
      await _updateConversation(
        user.uid,
        message.receiverId!,
        message.text!,
        message.type ?? 'text',
      );

      return docRef.id;
    } catch (e) {
      Get.snackbar("Hata", "Mesaj gönderilemedi: $e");
      rethrow;
    }
  }

  // Konuşmayı güncelle
  static Future<void> _updateConversation(
    String senderId,
    String receiverId,
    String lastMessage,
    String messageType,
  ) async {
    try {
      final conversationId = _getConversationId(senderId, receiverId);

      await _firestore.collection("conversations").doc(conversationId).set({
        "lastMessage": lastMessage,
        "lastMessageType": messageType,
        "lastMessageTime": FieldValue.serverTimestamp(),
        "lastMessageSenderId": senderId,
        "hasUnreadMessages": true,
        "participants": [senderId, receiverId],
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Konuşma güncellenemedi: $e
    }
  }

  // Konuşma ID'si oluştur
  static String _getConversationId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  // Konuşmaları getir
  static Future<List<Conversation>> getConversations() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await _firestore
          .collection("conversations")
          .where("participants", arrayContains: user.uid)
          .orderBy("lastMessageTime", descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Conversation.fromSnap(doc))
          .toList();
    } catch (e) {
      Get.snackbar("Hata", "Konuşmalar alınamadı: $e");
      return [];
    }
  }

  // Mesajları getir
  static Future<List<Message>> getMessages(String conversationId) async {
    try {
      final querySnapshot = await _firestore
          .collection("messages")
          .where("conversationId", isEqualTo: conversationId)
          .orderBy("createdAt")
          .get();

      return querySnapshot.docs.map((doc) => Message.fromSnap(doc)).toList();
    } catch (e) {
      Get.snackbar("Hata", "Mesajlar alınamadı: $e");
      return [];
    }
  }

  // ========== BİLDİRİM SERVİSLERİ ==========

  // Bildirim gönder
  static Future<void> sendNotification(AppNotification notification) async {
    try {
      await _firestore.collection("notifications").add(notification.toJson());
    } catch (e) {
      Get.snackbar("Hata", "Bildirim gönderilemedi: $e");
    }
  }

  // Kullanıcının bildirimlerini getir
  static Future<List<AppNotification>> getUserNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await _firestore
          .collection("notifications")
          .where("userId", isEqualTo: user.uid)
          .orderBy("createdAt", descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs
          .map((doc) => AppNotification.fromSnap(doc))
          .toList();
    } catch (e) {
      Get.snackbar("Hata", "Bildirimler alınamadı: $e");
      return [];
    }
  }

  // Bildirimi okundu olarak işaretle
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection("notifications").doc(notificationId).update({
        "isRead": true,
      });
    } catch (e) {
      Get.snackbar("Hata", "Bildirim güncellenemedi: $e");
    }
  }

  // ========== İSTATİSTİK SERVİSLERİ ==========

  // Kullanıcı istatistiklerini güncelle
  static Future<void> updateUserStats(
    String userId,
    Map<String, dynamic> stats,
  ) async {
    try {
      await _firestore.collection("users").doc(userId).update(stats);
    } catch (e) {
      Get.snackbar("Hata", "İstatistikler güncellenemedi: $e");
    }
  }

  // Video istatistiklerini güncelle
  static Future<void> updateVideoStats(
    String videoId,
    Map<String, dynamic> stats,
  ) async {
    try {
      await _firestore.collection("videos").doc(videoId).update(stats);
    } catch (e) {
      Get.snackbar("Hata", "Video istatistikleri güncellenemedi: $e");
    }
  }
}
