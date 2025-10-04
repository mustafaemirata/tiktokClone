import 'package:flutter/material.dart';
import 'package:cloneshorts/models/video.dart';
import 'package:cloneshorts/models/follow.dart';
import 'package:cloneshorts/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Video> _userVideos = [];
  List<Follow> _followers = [];
  List<Follow> _following = [];
  bool _isLoading = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Kullanıcı verilerini al
        final userData = await FirestoreService.getUserData(user.uid);
        if (userData != null) {
          setState(() {
            _userData = userData.data() as Map<String, dynamic>;
          });
        }

        // Kullanıcının videolarını al
        final videos = await FirestoreService.getUserVideos(user.uid);
        setState(() {
          _userVideos = videos;
        });

        // Takipçileri al
        final followers = await FirestoreService.getFollowers(user.uid);
        setState(() {
          _followers = followers;
        });

        // Takip edilenleri al
        final following = await FirestoreService.getFollowing(user.uid);
        setState(() {
          _following = following;
        });
      }
    } catch (e) {
      Get.snackbar("Hata", "Profil verileri yüklenemedi: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Profil",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Ayarlar sayfası
            },
            icon: const Icon(Icons.settings, color: Colors.white),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profil bilgileri
                  _buildProfileHeader(),

                  const SizedBox(height: 20),

                  // İstatistikler
                  _buildStats(),

                  const SizedBox(height: 20),

                  // Tab bar
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: "Videolar"),
                      Tab(text: "Takipçiler"),
                      Tab(text: "Takip Edilen"),
                    ],
                  ),

                  // Tab içerikleri
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildVideosTab(),
                        _buildFollowersTab(),
                        _buildFollowingTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Profil fotoğrafı
          CircleAvatar(
            radius: 50,
            backgroundImage: _userData?["image"] != null
                ? NetworkImage(_userData!["image"])
                : null,
            child: _userData?["image"] == null
                ? const Icon(Icons.person, size: 50, color: Colors.white)
                : null,
          ),

          const SizedBox(height: 16),

          // Kullanıcı adı
          Text(
            _userData?["name"] ?? "Bilinmeyen",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // Email
          Text(
            _userData?["email"] ?? "",
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),

          const SizedBox(height: 16),

          // Bio (eğer varsa)
          if (_userData?["bio"] != null)
            Text(
              _userData!["bio"],
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem("Videolar", _userVideos.length.toString()),
          _buildStatItem("Takipçiler", _followers.length.toString()),
          _buildStatItem("Takip Edilen", _following.length.toString()),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  Widget _buildVideosTab() {
    if (_userVideos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Henüz video yok",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "İlk videonuzu yükleyin!",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: _userVideos.length,
      itemBuilder: (context, index) {
        final video = _userVideos[index];
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[900],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: video.thumbnailUrl != null
                ? Image.network(
                    video.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.video_file, color: Colors.white),
                      );
                    },
                  )
                : const Center(
                    child: Icon(Icons.video_file, color: Colors.white),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildFollowersTab() {
    if (_followers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Henüz takipçi yok",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Videolarınızı paylaşarak takipçi kazanın!",
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _followers.length,
      itemBuilder: (context, index) {
        final follower = _followers[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: follower.followerImage != null
                ? NetworkImage(follower.followerImage!)
                : null,
            child: follower.followerImage == null
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          title: Text(
            follower.followerName ?? "Bilinmeyen",
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            "Takip etmeye başladı",
            style: const TextStyle(color: Colors.grey),
          ),
        );
      },
    );
  }

  Widget _buildFollowingTab() {
    if (_following.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_outlined, size: 80, color: Colors.grey),
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
              "İlginç kişileri keşfedin ve takip edin!",
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _following.length,
      itemBuilder: (context, index) {
        final following = _following[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: following.followingImage != null
                ? NetworkImage(following.followingImage!)
                : null,
            child: following.followingImage == null
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          title: Text(
            following.followingName ?? "Bilinmeyen",
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            "Takip ediyorsunuz",
            style: const TextStyle(color: Colors.grey),
          ),
        );
      },
    );
  }
}
