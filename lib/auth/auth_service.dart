import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<UserCredential> signInWithEmailPassword(String email, password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }



  // Add the `isAvailable` and `isIncoming` fields to the sign-up method
  Future<UserCredential> signUpWithEmailPassword(
      String email, password, String username, String bio) async {
    try {
      // Check if username already exists
      bool usernameExists = await isUsernameExists(username);
      if (usernameExists) {
        throw Exception("Username already exists. Please choose a different one.");
      }

      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Save user info including username, bio, `isAvailable`, and `isIncoming`
      await _firestore.collection("Users").doc(userCredential.user!.uid).set(
        {
          'uid': userCredential.user!.uid,
          'email': email,
          'username': username,
          'bio': bio,
          'isAvailable': true, // Initialize isAvailable to true by default
          'isIncoming': false, // Initialize isIncoming to false by default
        },
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }


  Future<void> signOut() async {
    return await _auth.signOut();
  }

  Future<bool> isUsernameExists(String username) async {
    // Check if username exists in Firestore
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
        .collection("Users")
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  Future<String?> getUserEmailFromUsername(String username) async {
    // Get user's email from Firestore using their username
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
        .collection("Users")
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.data()['email'];
    } else {
      throw Exception("User not found");
    }
  }
}