import 'dart:io';
import 'package:cloneshorts/models/video.dart';
import 'package:cloneshorts/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class UploadForm extends StatefulWidget {
  final File videoFile;
  final String videoPath;
  const UploadForm({
    super.key,
    required this.videoFile,
    required this.videoPath,
  });

  @override
  State<UploadForm> createState() => _UploadFormState();
}

class _UploadFormState extends State<UploadForm> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _hashtagsController = TextEditingController();
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _thumbnailPath;

  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında thumbnail oluştur
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateThumbnail();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _hashtagsController.dispose();
    super.dispose();
  }

  // Video'yu Firebase Storage'a yükle (retry ile)
  Future<String> _uploadVideoToStorage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Kullanıcı bulunamadı');

    // Video dosya boyutunu kontrol et (max 25MB - daha küçük limit)
    final fileSize = await widget.videoFile.length();
    const maxSize = 25 * 1024 * 1024; // 25MB

    if (fileSize > maxSize) {
      throw Exception('Video dosyası çok büyük. Maksimum 25MB olmalı.');
    }

    // Daha kısa dosya adı oluştur
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'videos/${user.uid}_$timestamp.mp4';

    print(
      'Uploading video: $fileName, Size: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)}MB',
    );

    // Retry mekanizması ile upload
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        print('Upload attempt $attempt/3');

        final ref = FirebaseStorage.instance.ref().child(fileName);

        // Basit metadata ile yükle
        final metadata = SettableMetadata(
          contentType: 'video/mp4',
          cacheControl: 'public, max-age=31536000',
        );

        final uploadTask = ref.putFile(widget.videoFile, metadata);

        // Upload progress'i dinle
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          if (snapshot.totalBytes > 0) {
            setState(() {
              _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
            });
            print(
              'Upload progress: ${(_uploadProgress * 100).toStringAsFixed(1)}%',
            );
          }
        });

        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        print('Video uploaded successfully: $downloadUrl');
        return downloadUrl;
      } catch (e) {
        print('Upload attempt $attempt failed: $e');

        if (attempt == 3) {
          // Son deneme de başarısız oldu
          Get.snackbar("Hata", "Video yüklenemedi: $e");
          rethrow;
        } else {
          // Bir sonraki deneme için bekle
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }

    throw Exception('Tüm upload denemeleri başarısız oldu');
  }

  // Video thumbnail oluştur
  Future<String> _generateThumbnail() async {
    try {
      print('Thumbnail oluşturuluyor... Video path: ${widget.videoPath}');

      final tempDir = await Directory.systemTemp.createTemp();
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: widget.videoPath,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 400,
        quality: 85,
        timeMs: 1000, // 1 saniye sonrasından thumbnail al
      );

      print('Thumbnail path: $thumbnailPath');

      if (thumbnailPath != null && File(thumbnailPath).existsSync()) {
        // Thumbnail'ı local olarak sakla
        setState(() {
          _thumbnailPath = thumbnailPath;
        });

        print('Thumbnail başarıyla oluşturuldu: $thumbnailPath');

        // Firebase Storage'a yükle
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName =
            'thumbnails/${FirebaseAuth.instance.currentUser!.uid}_$timestamp.jpg';
        final ref = FirebaseStorage.instance.ref().child(fileName);

        final metadata = SettableMetadata(contentType: 'image/jpeg');

        final uploadTask = ref.putFile(File(thumbnailPath), metadata);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        print('Thumbnail uploaded: $downloadUrl');
        return downloadUrl;
      } else {
        print('Thumbnail oluşturulamadı - dosya bulunamadı');
        return '';
      }
    } catch (e) {
      print('Thumbnail oluşturulamadı: $e');
      return '';
    }
  }

  // Video'yu Firestore'a kaydet
  Future<void> _uploadVideo() async {
    if (_titleController.text.trim().isEmpty) {
      Get.snackbar("Hata", "Başlık gerekli");
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı bulunamadı');

      // Kullanıcı verilerini al
      final userData = await FirestoreService.getUserData(user.uid);
      if (userData == null) throw Exception('Kullanıcı verileri bulunamadı');

      final userDataMap = userData.data() as Map<String, dynamic>;

      // Video'yu Storage'a yükle
      final videoUrl = await _uploadVideoToStorage();

      // Thumbnail oluştur ve yükle
      final thumbnailUrl = await _generateThumbnail();

      // Hashtag'leri parse et
      final hashtags = _hashtagsController.text
          .split(' ')
          .where((tag) => tag.startsWith('#'))
          .map((tag) => tag.substring(1))
          .toList();

      // Video objesi oluştur
      final video = Video(
        uid: user.uid,
        username: userDataMap["name"],
        profileImage: userDataMap["image"],
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        hashtags: hashtags,
        likes: 0,
        comments: 0,
        shares: 0,
        views: 0,
      );

      // Firestore'a kaydet
      await FirestoreService.uploadVideo(video);

      Get.snackbar("Başarılı", "Video başarıyla yüklendi!");
      Get.back(); // Ana sayfaya dön
    } catch (e) {
      Get.snackbar("Hata", "Video yüklenirken hata oluştu: $e");
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Video Yükle"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video önizleme
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    // Thumbnail varsa göster, yoksa icon göster
                    _thumbnailPath != null && File(_thumbnailPath!).existsSync()
                        ? Image.file(
                            File(_thumbnailPath!),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print('Thumbnail image error: $error');
                              return const Center(
                                child: Icon(
                                  Icons.video_file,
                                  size: 80,
                                  color: Colors.white,
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.video_file,
                                  size: 80,
                                  color: Colors.white,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "Thumbnail yükleniyor...",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                    // Play button overlay
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    // Video bilgi overlay
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "Video Önizleme",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Başlık
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Başlık *",
                hintText: "Video başlığını girin",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              maxLength: 100,
            ),

            const SizedBox(height: 16),

            // Açıklama
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: "Açıklama",
                hintText: "Video açıklamasını girin",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              maxLength: 500,
            ),

            const SizedBox(height: 16),

            // Hashtag'ler
            TextField(
              controller: _hashtagsController,
              decoration: const InputDecoration(
                labelText: "Hashtag'ler",
                hintText: "#hashtag1 #hashtag2",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
              maxLength: 200,
            ),

            const SizedBox(height: 30),

            // Upload progress
            if (_isUploading) ...[
              const Text("Video yükleniyor...", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              const SizedBox(height: 10),
              Text("${(_uploadProgress * 100).toInt()}% tamamlandı"),
              const SizedBox(height: 20),
            ],

            // Yükle butonu
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadVideo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isUploading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text("Yükleniyor...", style: TextStyle(fontSize: 16)),
                        ],
                      )
                    : const Text(
                        "Video Yükle",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
