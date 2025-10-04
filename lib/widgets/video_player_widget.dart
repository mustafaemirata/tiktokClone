import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cloneshorts/models/video.dart';
import 'package:cloneshorts/services/firestore_service.dart';
import 'package:cloneshorts/widgets/comment_section.dart';
import 'package:get/get.dart';

class VideoPlayerWidget extends StatefulWidget {
  final Video video;
  final bool isPlaying;
  final VoidCallback? onTap;

  const VideoPlayerWidget({
    super.key,
    required this.video,
    this.isPlaying = false,
    this.onTap,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isLiked = false;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _checkLikeStatus();
    _checkFollowStatus();
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video.videoUrl != widget.video.videoUrl) {
      _initializeVideo();
    }
    if (oldWidget.isPlaying != widget.isPlaying) {
      _handlePlayPause();
    }
  }

  void _initializeVideo() async {
    try {
      _controller?.dispose();
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.video.videoUrl!),
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // Video görüntülenme sayısını artır
        FirestoreService.incrementVideoViews(widget.video.id!);
      }
    } catch (e) {
      // Video yüklenemedi: $e
    }
  }

  void _checkLikeStatus() async {
    if (widget.video.id != null) {
      final isLiked = await FirestoreService.isVideoLiked(widget.video.id!);
      if (mounted) {
        setState(() {
          _isLiked = isLiked;
        });
      }
    }
  }

  void _checkFollowStatus() async {
    if (widget.video.uid != null) {
      final isFollowing = await FirestoreService.isFollowing(widget.video.uid!);
      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
        });
      }
    }
  }

  void _handlePlayPause() {
    if (_controller != null && _isInitialized) {
      if (widget.isPlaying) {
        _controller!.play();
      } else {
        _controller!.pause();
      }
    }
  }

  void _toggleLike() async {
    try {
      if (_isLiked) {
        await FirestoreService.unlikeVideo(widget.video.id!);
        setState(() {
          _isLiked = false;
        });
      } else {
        await FirestoreService.likeVideo(widget.video.id!);
        setState(() {
          _isLiked = true;
        });
      }
    } catch (e) {
      Get.snackbar("Hata", "Beğeni işlemi başarısız: $e");
    }
  }

  void _toggleFollow() async {
    try {
      if (_isFollowing) {
        await FirestoreService.unfollowUser(widget.video.uid!);
        setState(() {
          _isFollowing = false;
        });
      } else {
        await FirestoreService.followUser(widget.video.uid!);
        setState(() {
          _isFollowing = true;
        });
      }
    } catch (e) {
      Get.snackbar("Hata", "Takip işlemi başarısız: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video Player
          if (_isInitialized && _controller != null)
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            )
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // Video Controls Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Kullanıcı bilgileri
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: widget.video.profileImage != null
                            ? NetworkImage(widget.video.profileImage!)
                            : null,
                        child: widget.video.profileImage == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.video.username ?? 'Bilinmeyen',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (widget.video.title != null)
                              Text(
                                widget.video.title!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      // Takip butonu
                      GestureDetector(
                        onTap: _toggleFollow,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _isFollowing ? Colors.grey : Colors.red,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white),
                          ),
                          child: Text(
                            _isFollowing ? 'Takip Ediliyor' : 'Takip Et',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Video açıklaması
                  if (widget.video.description != null &&
                      widget.video.description!.isNotEmpty)
                    Text(
                      widget.video.description!,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 8),

                  // Hashtag'ler
                  if (widget.video.hashtags != null &&
                      widget.video.hashtags!.isNotEmpty)
                    Wrap(
                      children: widget.video.hashtags!
                          .map(
                            (tag) => Text(
                              '#$tag ',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
          ),

          // Sağ taraftaki aksiyon butonları
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                // Beğeni butonu
                GestureDetector(
                  onTap: _toggleLike,
                  child: Column(
                    children: [
                      Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red : Colors.white,
                        size: 35,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatNumber(widget.video.likes ?? 0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Yorum butonu
                GestureDetector(
                  onTap: () {
                    // Yorum sayfasını aç
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => CommentSection(
                        videoId: widget.video.id!,
                        onClose: () => Navigator.pop(context),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      const Icon(Icons.comment, color: Colors.white, size: 35),
                      const SizedBox(height: 4),
                      Text(
                        _formatNumber(widget.video.comments ?? 0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Paylaş butonu
                GestureDetector(
                  onTap: () {
                    // Paylaşım işlemi
                    // TODO: Paylaşım özelliği ekle
                  },
                  child: Column(
                    children: [
                      const Icon(Icons.share, color: Colors.white, size: 35),
                      const SizedBox(height: 4),
                      Text(
                        _formatNumber(widget.video.shares ?? 0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Play/Pause overlay
          if (!widget.isPlaying)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }
}
