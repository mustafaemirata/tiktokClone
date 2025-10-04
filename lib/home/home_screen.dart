import 'package:cloneshorts/home/following/following_videos_screen.dart';
import 'package:cloneshorts/home/for_you/for_you_videos_screen.dart';
import 'package:cloneshorts/home/profile/profile.dart';
import 'package:cloneshorts/home/search/search.dart';
import 'package:cloneshorts/home/upload_video/upload_custom_icon.dart';
import 'package:cloneshorts/home/upload_video/upload_video_screen.dart';
import 'package:cloneshorts/home/messages/messages_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int screenIndex = 0;
  List screenList = [
    ForYouVideosScreen(),
    Search(),
    UploadVideoScreen(),
    FollowingVideosScreen(),
    MessagesScreen(),
    Profile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screenList[screenIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
          setState(() {
            screenIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white30,
        unselectedItemColor: Colors.white60,
        currentIndex: screenIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 30),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search, size: 30),
            label: "Discover",
          ),
          BottomNavigationBarItem(icon: UploadCustomIcon(), label: "Upload"),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox_sharp, size: 30),
            label: "Following",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline, size: 30),
            label: "Messages",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 30),
            label: "Me",
          ),
        ],
      ),
    );
  }
}
