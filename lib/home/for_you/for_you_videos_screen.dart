import 'package:flutter/material.dart';
import 'package:cloneshorts/models/video.dart';
import 'package:cloneshorts/services/firestore_service.dart';
import 'package:cloneshorts/widgets/video_player_widget.dart';
import 'package:cloneshorts/widgets/comment_section.dart';
import 'package:get/get.dart';

class ForYouVideosScreen extends StatefulWidget {
  const ForYouVideosScreen({super.key});

  @override
  State<ForYouVideosScreen> createState() => _ForYouVideosScreenState();
}

class _ForYouVideosScreenState extends State<ForYouVideosScreen> {
  final PageController _pageController = PageController();
  List<Video> _videos = [];
  int _currentIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadVideos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final videos = await FirestoreService.getVideos(limit: 20);
      setState(() {
        _videos = videos;
      });
    } catch (e) {
      Get.snackbar("Hata", "Videolar yüklenemedi: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _showComments() {
    if (_currentIndex < _videos.length) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => CommentSection(
          videoId: _videos[_currentIndex].id!,
          onClose: () => Navigator.pop(context),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _videos.isEmpty
          ? const Center(
              child: Text(
                "Henüz video yok",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            )
          : PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              scrollDirection: Axis.vertical,
              itemCount: _videos.length,
              itemBuilder: (context, index) {
                return VideoPlayerWidget(
                  video: _videos[index],
                  isPlaying: index == _currentIndex,
                  onTap: _showComments,
                );
              },
            ),
    );
  }
}
