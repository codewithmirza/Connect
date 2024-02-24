import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connect/components/my_drawer.dart';
import 'package:connect/components/post_card.dart';
import 'package:connect/pages/chat_page.dart';
import 'package:connect/pages/notification_page.dart';
import 'package:connect/pages/posting_screen.dart';

enum ToolbarIcon { notifications, chat }

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  late User _currentUser; // Add this line
  late String _username; // Add this line
  late String _profileImageUrl; // Add this line

  ToolbarIcon selectedIcon = ToolbarIcon.notifications;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _currentUser = FirebaseAuth.instance.currentUser!; // Add this line
    _fetchUserData(); // Add this line
  }

  Future<void> _fetchUserData() async {
    DocumentSnapshot userSnapshot =
    await FirebaseFirestore.instance.collection('Users').doc(_currentUser.uid).get();
    setState(() {
      _username = userSnapshot['username'];
      _profileImageUrl = userSnapshot['profileImageUrl'];
    });
  }

  void onIconTap(ToolbarIcon icon) {
    setState(() {
      selectedIcon = icon;
    });

    // Handle navigation based on selected icon
    if (icon == ToolbarIcon.notifications) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NotificationPage()),
      ).then((_) => setState(() => selectedIcon = ToolbarIcon.notifications)); // Reset on back
    } else if (icon == ToolbarIcon.chat) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChatPage()),
      ).then((_) => setState(() => selectedIcon = ToolbarIcon.notifications)); // Reset on back
    }
  }

  Future<void> _openCamera() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostingScreen(
            imageFile: File(pickedFile.path),
            uid: _currentUser.uid,
            username: _username,
            profImage: _profileImageUrl,
          ),
        ),
      );
    }
  }

  Future<void> _openGallery() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostingScreen(
            imageFile: File(pickedFile.path),
            uid: _currentUser.uid,
            username: _username,
            profImage: _profileImageUrl,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        title: const Text(
          'Connect',
          style: TextStyle(
            fontFamily: 'ProtestRiot',
            color: Color(0xFF00A8FF),
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications,
            ),
            onPressed: () => onIconTap(ToolbarIcon.notifications),
          ),
          IconButton(
            icon: const Icon(
              Icons.chat,
            ),
            onPressed: () => onIconTap(ToolbarIcon.chat),
          ),
        ],
      ),
      drawer: const MyDrawer(),
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 80,
            right: 10,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (BuildContext context, Widget? child) {
                return Transform.rotate(
                  angle: _animation.value * 0.8 * 2 * 3.1415926535897932,
                  child: FloatingActionButton(
                    onPressed: () {
                      if (_animationController.isDismissed) {
                        _animationController.forward();
                      } else {
                        _animationController.reverse();
                      }
                    },
                    child: const Icon(Icons.add),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 160,
            right: 22,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (BuildContext context, Widget? child) {
                return Transform.scale(
                  scale: _animation.value,
                  child: FloatingActionButton(
                    onPressed: _openCamera,
                    child: const Icon(Icons.camera_alt),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 230,
            right: 22,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (BuildContext context, Widget? child) {
                return Transform.scale(
                  scale: _animation.value,
                  child: FloatingActionButton(
                    onPressed: _openGallery,
                    child: const Icon(Icons.photo),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('posts').snapshots(),
        builder: (context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) => PostCard(
              snap: snapshot.data!.docs[index],
              currentUser: _currentUser, // Pass currentUser here
            ),
          );
        },
      ),
    );
  }
}
