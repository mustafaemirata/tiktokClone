import 'package:flutter/material.dart';
import 'package:cloneshorts/models/video.dart';
import 'package:cloneshorts/services/firestore_service.dart';
import 'package:cloneshorts/widgets/video_player_widget.dart';
import 'package:cloneshorts/widgets/comment_section.dart';
import 'package:get/get.dart';

class FollowingVideosScreen extends StatefulWidget {
  const FollowingVideosScreen({super.key});

  @override
  State<FollowingVideosScreen> createState() => _FollowingVideosScreenState();
}

class _FollowingVideosScreenState extends State<FollowingVideosScreen> {
  final PageController _pageController = PageController();
  List<Video> _videos = [];
  int _currentIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFollowingVideos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadFollowingVideos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final videos = await FirestoreService.getFollowingVideos();
      setState(() {
        _videos = videos;
      });
    } catch (e) {
      Get.snackbar("Hata", "Takip edilen videolar yüklenemedi: $e");
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "Henüz kimseyi takip etmiyorsunuz",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Takip ettiğiniz kişilerin videoları burada görünecek",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
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
