import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfileCard extends StatefulWidget {
  final String? name;
  String? profileImageUrl;
  final int? connectionsCount;

  ProfileCard({
    super.key,
    this.name,
    this.profileImageUrl,
    this.connectionsCount = 0,
  });

  @override
  _ProfileCardState createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Uint8List? _imageBytes;
  late String _username;
  late String _bio = ''; // Initialize _bio with an empty string
  bool _isLoading = true;
  bool _isEditingUsername = false;
  bool _isEditingBio = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  late User _currentUser;
  List<DocumentSnapshot> _userPosts = [];

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser!;
    _loadUserData();
    _loadUserPosts();
  }

  Future<void> _loadUserData() async {
    try {
      DocumentSnapshot snapshot = await _firestore.collection('Users').doc(_currentUser.uid).get();
      if (snapshot.exists) {
        setState(() {
          _username = snapshot['username'] as String;
          _bio = snapshot['bio'] as String;
          widget.profileImageUrl = snapshot['profileImageUrl'] as String?;
          _isLoading = false; // Update isLoading flag
        });
      } else {
        setState(() {
          _isLoading = false; // Update isLoading flag even if user data doesn't exist
        });
      }
    } catch (error) {
      print('Error loading user data: $error');
      setState(() {
        _isLoading = false; // Update isLoading flag in case of error
      });
    }
  }


  Future<void> _loadUserPosts() async {
    QuerySnapshot postSnapshot = await _firestore.collection('posts').where('userId', isEqualTo: _currentUser.uid).get();
    setState(() {
      _userPosts = postSnapshot.docs;
    });
  }

  Future<void> selectImage() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      final bytes = await pickedImage.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
      await _uploadImage(); // Call _uploadImage() after setting _imageBytes
    }
  }

  Future<void> _uploadImage() async {
    Reference ref = FirebaseStorage.instance.ref().child('profile_images').child('${_currentUser.uid}.jpg');
    UploadTask uploadTask = ref.putData(_imageBytes!);
    TaskSnapshot storageTaskSnapshot = await uploadTask.whenComplete(() {});
    String imageUrl = await storageTaskSnapshot.ref.getDownloadURL();

    await _firestore.collection('Users').doc(_currentUser.uid).update({
      'profileImageUrl': imageUrl,
    });

    setState(() {
      widget.profileImageUrl = imageUrl; // Update widget.profileImageUrl with the new image URL
    });
  }

  void _saveUsernameChanges() {
    setState(() {
      _isEditingUsername = false;
      _username = _usernameController.text.trim();
      _updateUserData();
    });
  }

  void _saveBioChanges() {
    setState(() {
      _isEditingBio = false;
      _bio = _bioController.text.trim();
      _updateUserData();
    });
  }

  void _updateUserData() {
    _firestore.collection('Users').doc(_currentUser.uid).update({
      'username': _username,
      'bio': _bio,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _buildProfileView(),
    );
  }

  Widget _buildProfileView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                GestureDetector(
                  onTap: selectImage,
                  child: CircleAvatar(
                    radius: 64,
                    backgroundImage:
                    _imageBytes != null && _imageBytes!.isNotEmpty
                        ? MemoryImage(_imageBytes!)
                        : widget.profileImageUrl != null
                        ? NetworkImage(widget.profileImageUrl!)
                        : const NetworkImage('https://images.pexels.com/photos/19829656/pexels-photo-19829656/free-photo-of-flowers-in-vase-on-table-near-curtain.jpeg?auto=compress&cs=tinysrgb&w=600&lazy=load') as ImageProvider,
                    backgroundColor: Colors.red,
                  ),
                ),
                Positioned(
                  bottom: -13,
                  right: -8,
                  child: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: selectImage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isEditingUsername
                    ? Expanded(
                  child: TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                    ),
                  ),
                )
                    : Expanded(
                  child: Text(
                    '@$_username',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      _isEditingUsername = !_isEditingUsername;
                      if (_isEditingUsername) {
                        _usernameController.text = _username;
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_isEditingUsername)
              ElevatedButton(
                onPressed: _saveUsernameChanges,
                child: const Text('Save Changes'),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isEditingBio
                    ? Expanded(
                  child: TextFormField(
                    controller: _bioController,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                    ),
                  ),
                )
                    : Expanded(
                  child: Text(
                    'Bio: ${_bio.isEmpty ? 'No bio set' : _bio}',
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      _isEditingBio = !_isEditingBio;
                      if (_isEditingBio) {
                        _bioController.text = _bio;
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_isEditingBio)
              ElevatedButton(
                onPressed: _saveBioChanges,
                child: const Text('Save Changes'),
              ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _userPosts.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot postSnapshot = _userPosts[index];
                  return ListTile(
                    title: Text(postSnapshot['description']),
                    subtitle: Text(postSnapshot['timestamp'].toString()),
                    // Additional post details...
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
