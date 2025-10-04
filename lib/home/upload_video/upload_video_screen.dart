import 'dart:io';

import 'package:cloneshorts/home/upload_video/upload_form.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class UploadVideoScreen extends StatefulWidget {
  const UploadVideoScreen({super.key});

  @override
  State<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  displayDialogBox() {
    return showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        children: [
          SimpleDialogOption(
            onPressed: () {
              getVideoFile(ImageSource.gallery);
            },
            child: Row(
              children: const [
                Icon(Icons.image),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      "Galeriden yükle",
                      style: TextStyle(fontSize: 17),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              getVideoFile(ImageSource.camera);
            },
            child: Row(
              children: const [
                Icon(Icons.camera_alt_outlined),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      "Kameradan yükle",
                      style: TextStyle(fontSize: 17),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Get.back();
            },
            child: Row(
              children: const [
                Icon(Icons.cancel),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text("İptal", style: TextStyle(fontSize: 17)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  getVideoFile(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? videoFile = await picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5), // 5 dakika limit
      );

      if (videoFile != null) {
        // Video dosya boyutunu kontrol et
        final file = File(videoFile.path);
        final fileSize = await file.length();
        const maxSize = 25 * 1024 * 1024; // 25MB

        print(
          'Selected video: ${videoFile.path}, Size: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)}MB',
        );

        if (fileSize > maxSize) {
          Get.snackbar(
            "Hata",
            "Video dosyası çok büyük. Maksimum 25MB olmalı.\nSeçilen dosya: ${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB",
          );
          return;
        }

        // Dialog'u kapat
        Get.back();

        // Upload form'a geç
        Get.to(UploadForm(videoFile: file, videoPath: videoFile.path));
      } else {
        // Video seçilmedi
        Get.snackbar("Bilgi", "Video seçilmedi");
      }
    } catch (e) {
      Get.snackbar("Hata", "Video seçilirken hata oluştu: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("images/upload.png", width: 200),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                //dialogu göster
                displayDialogBox();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                "Video Yükle",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
