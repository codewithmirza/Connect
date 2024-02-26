import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostingScreen extends StatefulWidget {
  final File? imageFile;
  final String? profileImageUrl; // New field to hold the user's profile image URL
  final String uid;
  final String username;
  final String profImage;

  const PostingScreen({
    super.key,
    required this.imageFile,
    required this.uid,
    required this.username,
    required this.profImage,
    this.profileImageUrl,
  });

  @override
  _PostingScreenState createState() => _PostingScreenState();
}

class _PostingScreenState extends State<PostingScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  bool _isPosting = false;

  Future<void> _postMedia() async {
    if (_isPosting) return;

    setState(() {
      _isPosting = true;
    });

    try {
      final mediaUrl = await _uploadMedia();

      await _storeMediaData(mediaUrl);

      Navigator.pop(context);
    } catch (error) {
      print('Error posting media: $error');
      // Show error message to the user
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error posting media')));
    } finally {
      setState(() {
        _isPosting = false;
      });
    }
  }

  Future<String> _uploadMedia() async {
    final mediaReference = FirebaseStorage.instance.ref().child(
        'posts/${DateTime.now().millisecondsSinceEpoch}${widget.imageFile!.path.split('/').last}');
    final uploadTask = mediaReference.putFile(widget.imageFile!);
    final snapshot = await uploadTask.whenComplete(() {});
    return snapshot.ref.getDownloadURL();
  }

  Future<void> _storeMediaData(String mediaUrl) async {
    final postReference = FirebaseFirestore.instance.collection('posts').doc(); // Create a new document reference
    final postId = postReference.id; // Get the auto-generated document ID
    await postReference.set({
      'datePublished': DateTime.now(),
      'description': _descriptionController.text,
      'likes': [], // Initialize likes as an empty array
      'postID': postId, // Store the auto-generated document ID as the post ID
      'postURL': mediaUrl,
      'profImage': widget.profImage,
      'uid': widget.uid,
      'username': widget.username,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        title: const Text('Post Media'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CircleAvatar(
                  radius: 20, // Adjust size as needed
                  backgroundImage: widget.profileImageUrl != null
                      ? NetworkImage(widget.profileImageUrl!) // Use the profile image URL if available
                      : const AssetImage("assets/images/profile_picture.jpg") as ImageProvider,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        hintText: "Write a caption...",
                        border: InputBorder.none,
                      ),
                      maxLines: 8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            widget.imageFile != null
                ? Container(
              height: 200, // Adjust height as needed
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Image.file(
                widget.imageFile!,
                fit: BoxFit.cover,
              ),
            )
                : const SizedBox(), // No image selected
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isPosting ? null : _postMedia,
              child: _isPosting ? const CircularProgressIndicator() : const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}
