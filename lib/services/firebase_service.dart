import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/test_entry.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  // Getters rather than field initializers: these are only evaluated when a
  // Firebase call is actually made, so constructing FirebaseService (e.g. via
  // AuthProvider) doesn't crash the app before Firebase has been configured.
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  // Authentication
  Future<UserModel?> signUp({
    required String email,
    required String username,
    required String password,
    required int age,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('Failed to create user');

      final userModel = UserModel(
        id: user.uid,
        email: email,
        username: username,
        age: age,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(userModel.toJson());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw Exception(_authMessage(e));
    }
  }

  static String _authMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'requires-recent-login':
        return 'Please log out and log in again, then retry.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_authMessage(e));
    }
  }

  Future<User> _reauthenticate(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw Exception('You are not logged in.');
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: password),
      );
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_authMessage(e));
    }
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    final user = await _reauthenticate(currentPassword);
    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw Exception(_authMessage(e));
    }
  }

  // Removes the user's tests, profile and login. Required by the app stores
  // for any app that lets people create an account.
  Future<void> deleteAccount(String password) async {
    final user = await _reauthenticate(password);
    final userDoc = _firestore.collection('users').doc(user.uid);
    final entries = await userDoc.collection('testEntries').get();
    for (final doc in entries.docs) {
      await doc.reference.delete();
    }
    await userDoc.delete();
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw Exception(_authMessage(e));
    }
  }

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('Failed to login');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw Exception('User data not found');

      return UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
    } on FirebaseAuthException catch (e) {
      throw Exception(_authMessage(e));
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // User operations
  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return UserModel.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  Future<void> updateUserData(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toJson());
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  // Analysis quota
  Future<void> recordAnalysisUsed(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'analysesUsed': FieldValue.increment(1),
    });
  }

  // Admin
  Future<bool> isAdmin(String userId) async {
    try {
      final doc = await _firestore.collection('admins').doc(userId).get();
      return doc.exists;
    } on FirebaseException {
      return false;
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((doc) => UserModel.fromJson(doc.data())).toList();
  }

  // Every user's tests; only readable by admins (see firestore.rules).
  Future<List<TestEntry>> getAllTestEntries() async {
    final snapshot = await _firestore.collectionGroup('testEntries').get();
    return snapshot.docs.map((doc) => TestEntry.fromJson(doc.data())).toList();
  }

  Future<void> setAnalysisLimit(String userId, int limit) async {
    await _firestore.collection('users').doc(userId).update({'analysisLimit': limit});
  }

  // Test entries
  Future<void> saveTestEntry(TestEntry entry) async {
    try {
      await _firestore
          .collection('users')
          .doc(entry.userId)
          .collection('testEntries')
          .doc(entry.id)
          .set(entry.toJson());
    } catch (e) {
      throw Exception('Failed to save test entry: $e');
    }
  }

  Future<List<TestEntry>> getTestEntries(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('testEntries')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TestEntry.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get test entries: $e');
    }
  }

  Future<TestEntry?> getTestEntry(String userId, String entryId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('testEntries')
          .doc(entryId)
          .get();

      if (!doc.exists) return null;
      return TestEntry.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get test entry: $e');
    }
  }

  // File uploads
  Future<String> uploadFile(String userId, String fileName, Uint8List fileBytes) async {
    try {
      final ref = _storage.ref('users/$userId/uploads/$fileName');
      // The SDK retries silently for up to 10 minutes (e.g. if Storage isn't set up), so fail fast.
      await ref.putData(fileBytes).timeout(const Duration(seconds: 30));
      return await ref.getDownloadURL().timeout(const Duration(seconds: 15));
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<void> deleteFile(String filePath) async {
    try {
      await _storage.refFromURL(filePath).delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }
}
