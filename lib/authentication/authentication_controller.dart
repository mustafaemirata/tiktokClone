import 'dart:io';
import 'package:cloneshorts/authentication/login_screen.dart';
import 'package:cloneshorts/global.dart';
import 'package:cloneshorts/home/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'user.dart' as user_model;

class AuthenticationController extends GetxController {
  static AuthenticationController instanceAuth = Get.put(
    AuthenticationController(),
  );
  late Rx<User?> _currentUser;

  final Rx<File?> _pickedFile = Rx<File?>(null);
  File? get profileImage => _pickedFile.value;

  // Galeriden resim seç
  void chooseImageGallery() async {
    try {
      final pickedImageFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 60, // Daha düşük kalite = daha hızlı yükleme
        maxWidth: 800, // Maksimum genişlik
        maxHeight: 800, // Maksimum yükseklik
      );

      if (pickedImageFile != null) {
        _pickedFile.value = File(pickedImageFile.path);
        Get.snackbar("Başarılı", "Resim başarıyla seçildi!");
      }
    } catch (e) {
      Get.snackbar("Hata", "Resim seçilirken hata oluştu: $e");
    }
  }

  // Kameradan resim çek
  void captureImageCamera() async {
    try {
      final pickedImageFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 60, // Daha düşük kalite = daha hızlı yükleme
        maxWidth: 800, // Maksimum genişlik
        maxHeight: 800, // Maksimum yükseklik
      );

      if (pickedImageFile != null) {
        _pickedFile.value = File(pickedImageFile.path);
        Get.snackbar("Başarılı", "Resim başarıyla çekildi!");
      }
    } catch (e) {
      Get.snackbar("Hata", "Kamera kullanılırken hata oluştu: $e");
    }
  }

  // Kayıt işlemi
  void createAccount(
    File imageFile,
    String username,
    String email,
    String password,
  ) async {
    try {
      // Firebase Auth ile kullanıcı oluştur
      UserCredential credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      if (credential.user == null) {
        throw Exception('Kullanıcı oluşturulamadı');
      }

      // Resmi yükle
      String imageDownloadUrl = await uploadImageToStorage(imageFile);

      // User model oluştur
      user_model.User user = user_model.User(
        name: username,
        email: email,
        image: imageDownloadUrl,
        uid: credential.user!.uid,
      );

      // Firestore'a tek seferde tüm veriyi kaydet (batch operation)
      await FirebaseFirestore.instance
          .collection("users")
          .doc(credential.user!.uid)
          .set({
            ...user.toJson(),
            "createdAt": FieldValue.serverTimestamp(),
            "lastLogin": FieldValue.serverTimestamp(),
          });

      Get.snackbar("Başarılı", "Hesap başarıyla oluşturuldu!");
      Get.offAll(() => LoginPage());
      showProgress.value = false;
    } catch (error) {
      Get.snackbar("Hesap Oluşturma", "Bir hatayla karşılaşıldı: $error");
      showProgress.value = false;

      // Kullanıcı oluşturulduysa ama Firestore'a kaydedilemediyse hesabı sil
      try {
        if (FirebaseAuth.instance.currentUser != null) {
          await FirebaseAuth.instance.currentUser!.delete();
        }
      } catch (deleteError) {
        debugPrint('Kullanıcı silme hatası: $deleteError');
      }

      Get.to(() => LoginPage());
    }
  }

  // Giriş işlemi
  void loginUser(String email, String password) async {
    try {
      // Email ve şifre kontrolü
      if (email.isEmpty || password.isEmpty) {
        Get.snackbar("Hata", "Email ve şifre boş olamaz!");
        showProgress.value = false;
        return;
      }

      UserCredential credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (credential.user == null) {
        throw Exception('Giriş başarısız');
      }

      // Kullanıcı bilgilerini Firestore'dan al
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(credential.user!.uid)
          .get();

      debugPrint('User UID: ${credential.user!.uid}');
      debugPrint('User doc exists: ${userDoc.exists}');
      debugPrint('User doc data: ${userDoc.data()}');

      if (userDoc.exists) {
        // Son giriş tarihini güncelle (background'da çalışsın)
        FirebaseFirestore.instance
            .collection("users")
            .doc(credential.user!.uid)
            .update({"lastLogin": FieldValue.serverTimestamp()})
            .catchError(
              (e) => debugPrint('Son giriş tarihi güncellenemedi: $e'),
            );

        Get.snackbar("Başarılı", "Giriş başarılı!");
        // TODO: Ana sayfaya yönlendir
        showProgress.value = false;
      } else {
        // Kullanıcı verisi yoksa, mevcut auth bilgileriyle oluştur
        debugPrint(
          'Kullanıcı verisi bulunamadı, yeni kullanıcı oluşturuluyor...',
        );

        // Temel kullanıcı verisi oluştur
        await FirebaseFirestore.instance
            .collection("users")
            .doc(credential.user!.uid)
            .set({
              "name":
                  credential.user!.displayName ??
                  credential.user!.email?.split('@')[0] ??
                  "Kullanıcı",
              "email": credential.user!.email,
              "uid": credential.user!.uid,
              "image": credential.user!.photoURL ?? "",
              "createdAt": FieldValue.serverTimestamp(),
              "lastLogin": FieldValue.serverTimestamp(),
            });

        Get.snackbar(
          "Başarılı",
          "Giriş başarılı! Profil bilgileriniz güncellendi.",
        );
        showProgress.value = false;
      }
    } catch (error) {
      String errorMessage = "Giriş yapılamadı";

      if (error.toString().contains('user-not-found')) {
        errorMessage = "Bu email ile kayıtlı kullanıcı bulunamadı";
      } else if (error.toString().contains('wrong-password')) {
        errorMessage = "Hatalı şifre";
      } else if (error.toString().contains('invalid-email')) {
        errorMessage = "Geçersiz email adresi";
      }

      Get.snackbar("Giriş Hatası", errorMessage);
      showProgress.value = false;
    }
  }

  // Çıkış işlemi
  void signOutUser() async {
    try {
      await FirebaseAuth.instance.signOut();
      Get.snackbar("Başarılı", "Çıkış yapıldı!");
      Get.offAll(() => LoginPage());
    } catch (error) {
      Get.snackbar("Çıkış Hatası", "Çıkış yapılamadı: $error");
    }
  }

  // Debug: Tüm kullanıcıları listele
  void debugListAllUsers() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection("users")
          .get();

      debugPrint('Toplam kullanıcı sayısı: ${snapshot.docs.length}');

      for (var doc in snapshot.docs) {
        debugPrint('User ID: ${doc.id}');
        debugPrint('User Data: ${doc.data()}');
      }
    } catch (e) {
      debugPrint('Kullanıcı listesi alınamadı: $e');
    }
  }

  // Fotoğrafı Firebase Storage'a yükle
  Future<String> uploadImageToStorage(File imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı bulunamadı');
      }

      Reference reference = FirebaseStorage.instance
          .ref()
          .child("Profile_Images")
          .child(user.uid);

      // Metadata ekle (daha iyi performans için)
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Upload task'ı başlat
      UploadTask uploadTask = reference.putFile(imageFile, metadata);

      // Progress takibi (opsiyonel)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      });

      TaskSnapshot taskSnapshot = await uploadTask;

      if (taskSnapshot.state == TaskState.success) {
        String downloadUrl = await taskSnapshot.ref.getDownloadURL();
        debugPrint('Resim başarıyla yüklendi: $downloadUrl');
        return downloadUrl;
      } else {
        throw Exception('Upload başarısız: ${taskSnapshot.state}');
      }
    } catch (e) {
      debugPrint('Storage upload hatası: $e');
      throw Exception('Resim yüklenemedi: $e');
    }
  }

  goToScreen(User? currentUser) {
    if (currentUser == null) {
      Get.offAll(LoginPage());
    } else {
      Get.offAll(HomeScreen());
    }
  }

  @override
  void onReady() {
    // TODO: implement onReady
    super.onReady();
    _currentUser = Rx<User?>(FirebaseAuth.instance.currentUser);
    _currentUser.bindStream(FirebaseAuth.instance.authStateChanges());
    ever(_currentUser, goToScreen);
  }
}
