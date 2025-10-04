import 'package:flutter/material.dart';
import 'package:cloneshorts/models/comment.dart';
import 'package:cloneshorts/services/firestore_service.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentSection extends StatefulWidget {
  final String videoId;
  final VoidCallback? onClose;

  const CommentSection({super.key, required this.videoId, this.onClose});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  List<Comment> _comments = [];
  bool _isLoading = false;
  String? _replyingToCommentId;
  String? _replyingToUsername;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _loadComments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final comments = await FirestoreService.getVideoComments(widget.videoId);
      setState(() {
        _comments = comments;
      });
    } catch (e) {
      Get.snackbar("Hata", "Yorumlar yüklenemedi: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final comment = Comment(
        videoId: widget.videoId,
        text: _commentController.text.trim(),
        parentCommentId: _replyingToCommentId,
      );

      await FirestoreService.addComment(comment);

      _commentController.clear();
      _replyingToCommentId = null;
      _replyingToUsername = null;

      _loadComments(); // Yorumları yeniden yükle
    } catch (e) {
      Get.snackbar("Hata", "Yorum eklenemedi: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _replyToComment(String commentId, String username) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUsername = username;
    });
    _commentController.text = '@$username ';
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUsername = null;
    });
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  "Yorumlar",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Comments List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _comments.isEmpty
                ? const Center(
                    child: Text(
                      "Henüz yorum yok",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      return CommentItem(
                        comment: _comments[index],
                        onReply: _replyToComment,
                      );
                    },
                  ),
          ),

          // Reply indicator
          if (_replyingToUsername != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[900],
              child: Row(
                children: [
                  Text(
                    "Yanıtlanıyor: @$_replyingToUsername",
                    style: const TextStyle(color: Colors.blue),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: const Icon(
                      Icons.close,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

          // Comment Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _replyingToUsername != null
                          ? "Yanıt yazın..."
                          : "Yorum yazın...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _addComment(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isLoading ? null : _addComment,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CommentItem extends StatefulWidget {
  final Comment comment;
  final Function(String commentId, String username) onReply;

  const CommentItem({super.key, required this.comment, required this.onReply});

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  List<Comment> _replies = [];
  bool _isLiked = false;
  bool _showReplies = false;
  bool _isLoadingReplies = false;

  @override
  void initState() {
    super.initState();
    _checkLikeStatus();
  }

  void _checkLikeStatus() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && widget.comment.likes != null) {
      setState(() {
        _isLiked = widget.comment.likes!.contains(currentUser.uid);
      });
    }
  }

  void _toggleLike() async {
    try {
      if (_isLiked) {
        await FirestoreService.unlikeComment(widget.comment.id!);
        setState(() {
          _isLiked = false;
        });
      } else {
        await FirestoreService.likeComment(widget.comment.id!);
        setState(() {
          _isLiked = true;
        });
      }
    } catch (e) {
      Get.snackbar("Hata", "Beğeni işlemi başarısız: $e");
    }
  }

  void _loadReplies() async {
    if (_replies.isNotEmpty) {
      setState(() {
        _showReplies = !_showReplies;
      });
      return;
    }

    setState(() {
      _isLoadingReplies = true;
    });

    try {
      final replies = await FirestoreService.getCommentReplies(
        widget.comment.id!,
      );
      setState(() {
        _replies = replies;
        _showReplies = true;
      });
    } catch (e) {
      Get.snackbar("Hata", "Cevaplar yüklenemedi: $e");
    } finally {
      setState(() {
        _isLoadingReplies = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ana yorum
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: widget.comment.profileImage != null
                    ? NetworkImage(widget.comment.profileImage!)
                    : null,
                child: widget.comment.profileImage == null
                    ? const Icon(Icons.person, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.comment.username ?? 'Bilinmeyen',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(widget.comment.createdAt),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.comment.text ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _toggleLike,
                          child: Row(
                            children: [
                              Icon(
                                _isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _isLiked ? Colors.red : Colors.grey,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.comment.likeCount.toString(),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => widget.onReply(
                            widget.comment.id!,
                            widget.comment.username ?? 'Bilinmeyen',
                          ),
                          child: const Text(
                            "Yanıtla",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Cevaplar
          if (_replies.isNotEmpty && _showReplies) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Column(
                children: _replies
                    .map(
                      (reply) =>
                          CommentItem(comment: reply, onReply: widget.onReply),
                    )
                    .toList(),
              ),
            ),
          ],

          // Cevapları göster/gizle butonu
          if (_replies.isNotEmpty || _isLoadingReplies)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 8),
              child: GestureDetector(
                onTap: _loadReplies,
                child: Row(
                  children: [
                    Icon(
                      _showReplies
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isLoadingReplies
                          ? "Yükleniyor..."
                          : _showReplies
                          ? "Cevapları gizle"
                          : "${_replies.length} cevap",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final commentTime = timestamp.toDate();
    final difference = now.difference(commentTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}g';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}s';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}d';
    } else {
      return 'şimdi';
    }
  }
}
