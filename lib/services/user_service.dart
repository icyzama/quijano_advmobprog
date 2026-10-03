import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/user.dart';

class UserServiceException implements Exception {
  final String message;

  const UserServiceException(this.message);

  @override
  String toString() => message;
}

class UserService {
  static const String _userStorageKey = 'authenticated_user';

  bool get isFirebaseConfigured => Firebase.apps.isNotEmpty;

  fb.FirebaseAuth get _firebaseAuth {
    if (!isFirebaseConfigured) {
      throw const UserServiceException(
        'Firebase is not configured yet. Run flutterfire configure and enable Email/Password sign-in.',
      );
    }
    return fb.FirebaseAuth.instance;
  }

  fb.User? get currentFirebaseUser {
    if (!isFirebaseConfigured) {
      return null;
    }
    return fb.FirebaseAuth.instance.currentUser;
  }

  Stream<fb.User?> firebaseAuthStateChanges() {
    if (!isFirebaseConfigured) {
      return const Stream.empty();
    }
    return fb.FirebaseAuth.instance.authStateChanges();
  }

  // Enhancement 2: Sign-in screen integrated with API authentication.
  Future<User> loginUser({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 60,
      }),
    );

    final decoded = _decodeObject(response.body);

    if (response.statusCode != 200) {
      throw UserServiceException(
        decoded['message'] as String? ?? 'Unable to sign in. Please try again.',
      );
    }

    final loginUser = User.fromJson(decoded).copyWith(
      loginType: LoginType.dummyJson,
    );
    if (!loginUser.hasAuthToken || loginUser.id == 0) {
      throw const UserServiceException(
        'The sign-in response was incomplete. Please try again.',
      );
    }

    final profileUser = await _getAuthenticatedUser(loginUser.accessToken!);
    final userToSave = (profileUser ?? loginUser).copyWith(
      accessToken: loginUser.accessToken,
      refreshToken: loginUser.refreshToken,
      loginType: LoginType.dummyJson,
    );

    await saveUserData(userToSave);
    return userToSave;
  }

  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const UserServiceException('Firebase did not return a user.');
      }

      final savedUser = await getUser();
      final cloudUser = await _getFirebaseProfile(firebaseUser.uid);
      final profileUser = savedUser?.firebaseUid == firebaseUser.uid
          ? savedUser
          : cloudUser ?? savedUser;
      final user = _firebaseUserToLocalUser(
        firebaseUser,
        profileUser,
      );
      await _syncFirebaseProfile(user);
      await saveUserData(user);
      return user;
    } on fb.FirebaseAuthException catch (error) {
      throw UserServiceException(_firebaseErrorMessage(error));
    } on FirebaseException catch (error) {
      await _firebaseAuth.signOut();
      throw UserServiceException(_firestoreErrorMessage(error));
    }
  }

  Future<User> createAccount({
    required String firstName,
    required String lastName,
    required int age,
    required String contactNumber,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const UserServiceException('Firebase did not return a user.');
      }

      await firebaseUser.updateDisplayName(username.trim());
      await firebaseUser.reload();

      final user = User.firebaseProfile(
        firebaseUid: firebaseUser.uid,
        email: firebaseUser.email ?? email.trim(),
        username: username.trim(),
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        age: age,
        contactNumber: contactNumber.trim(),
        image: firebaseUser.photoURL ?? '',
      );

      await _syncFirebaseProfile(user, isNewAccount: true);
      await saveUserData(user);
      return user;
    } on fb.FirebaseAuthException catch (error) {
      throw UserServiceException(_firebaseErrorMessage(error));
    } on FirebaseException catch (error) {
      await _firebaseAuth.signOut();
      await _clearUserData();
      throw UserServiceException(_firestoreErrorMessage(error));
    }
  }

  Future<User> updateUsername(String username) async {
    final trimmedUsername = username.trim();
    if (trimmedUsername.isEmpty) {
      throw const UserServiceException('Username is required.');
    }

    try {
      final firebaseUser = _requireFirebaseUser();
      await firebaseUser.updateDisplayName(trimmedUsername);
      await firebaseUser.reload();

      final currentUser = await getUser();
      final updatedUser = (currentUser ??
              _firebaseUserToLocalUser(_requireFirebaseUser(), null))
          .copyWith(username: trimmedUsername, loginType: LoginType.firebase);
      await _syncFirebaseProfile(updatedUser);
      await saveUserData(updatedUser);
      return updatedUser;
    } on fb.FirebaseAuthException catch (error) {
      throw UserServiceException(_firebaseErrorMessage(error));
    } on FirebaseException catch (error) {
      throw UserServiceException(_firestoreErrorMessage(error));
    }
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (currentPassword.isEmpty) {
      throw const UserServiceException('Current password is required.');
    }
    if (newPassword.length < 6) {
      throw const UserServiceException(
        'New password must be at least 6 characters.',
      );
    }

    try {
      final firebaseUser = _requireFirebaseUser();
      await _reauthenticate(firebaseUser, currentPassword);
      await firebaseUser.updatePassword(newPassword);
    } on fb.FirebaseAuthException catch (error) {
      throw UserServiceException(_firebaseErrorMessage(error));
    }
  }

  Future<void> deleteAccount({required String password}) async {
    if (password.isEmpty) {
      throw const UserServiceException('Password is required.');
    }

    try {
      final firebaseUser = _requireFirebaseUser();
      await _reauthenticate(firebaseUser, password);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .delete();
      await firebaseUser.delete();
      await _clearUserData();
    } on fb.FirebaseAuthException catch (error) {
      throw UserServiceException(_firebaseErrorMessage(error));
    } on FirebaseException catch (error) {
      throw UserServiceException(_firestoreErrorMessage(error));
    }
  }

  Future<void> saveUserData(User user) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_userStorageKey, jsonEncode(user.toJson()));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final preferences = await SharedPreferences.getInstance();
    final rawUser = preferences.getString(_userStorageKey);

    if (rawUser == null || rawUser.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(rawUser) as Map<String, dynamic>;
    } catch (_) {
      await preferences.remove(_userStorageKey);
      return null;
    }
  }

  Future<User?> getUser() async {
    final data = await getUserData();
    if (data == null) {
      return null;
    }

    try {
      return User.fromJson(data);
    } catch (_) {
      await logout();
      return null;
    }
  }

  Future<User?> ensureFirebaseProfileSynced() async {
    final firebaseUser = currentFirebaseUser;
    final savedUser = await getUser();
    if (firebaseUser == null || savedUser?.isFirebase != true) {
      return savedUser;
    }

    final cloudUser = await _getFirebaseProfile(firebaseUser.uid);
    final profileUser = savedUser?.firebaseUid == firebaseUser.uid
        ? savedUser
        : cloudUser ?? savedUser;
    final user = _firebaseUserToLocalUser(firebaseUser, profileUser);
    await _syncFirebaseProfile(user, isNewAccount: cloudUser == null);
    await saveUserData(user);
    return user;
  }

  Future<LoginType?> getLoginType() async {
    final user = await getUser();
    return user?.loginType;
  }

  Future<bool> isLoggedIn() async {
    final user = await getUser();
    if (user == null) {
      return false;
    }

    if (user.isFirebase) {
      final firebaseUser = currentFirebaseUser ?? await _restoreFirebaseUser();
      return firebaseUser != null &&
          (user.firebaseUid == null || user.firebaseUid == firebaseUser.uid);
    }

    return user.id != 0 && user.hasAuthToken;
  }

  Future<void> logout() async {
    final user = await getUser();
    if (user?.isFirebase == true && isFirebaseConfigured) {
      await fb.FirebaseAuth.instance.signOut();
    }
    await _clearUserData();
  }

  Future<void> signOut() => logout();

  Future<void> _clearUserData() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_userStorageKey);
  }

  Future<User?> _getAuthenticatedUser(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('$host/auth/me'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode != 200) {
        return null;
      }

      return User.fromJson(_decodeObject(response.body));
    } catch (_) {
      return null;
    }
  }

  Future<void> _reauthenticate(
    fb.User firebaseUser,
    String password,
  ) async {
    final email = firebaseUser.email;
    if (email == null || email.isEmpty) {
      throw const UserServiceException(
        'This Firebase account does not have an email address.',
      );
    }

    final credential = fb.EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await firebaseUser.reauthenticateWithCredential(credential);
  }

  fb.User _requireFirebaseUser() {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw const UserServiceException('Please sign in again.');
    }
    return firebaseUser;
  }

  Future<fb.User?> _restoreFirebaseUser() async {
    if (!isFirebaseConfigured) {
      return null;
    }

    return fb.FirebaseAuth.instance
        .authStateChanges()
        .first
        .timeout(const Duration(seconds: 2), onTimeout: () => null);
  }

  Future<void> _syncFirebaseProfile(
    User user, {
    bool isNewAccount = false,
  }) async {
    final uid = user.firebaseUid;
    if (!user.isFirebase || uid == null || uid.isEmpty) return;

    final profile = <String, dynamic>{
      'uid': uid,
      'email': user.email,
      'username': user.username,
      'firstName': user.firstName,
      'lastName': user.lastName,
      'image': user.image,
      'updatedAt': FieldValue.serverTimestamp(),
      if (isNewAccount) 'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set(profile, SetOptions(merge: true));
  }

  Future<User?> _getFirebaseProfile(String uid) async {
    final snapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;

    return User.firebaseProfile(
      firebaseUid: uid,
      email: data['email'] as String? ?? '',
      username: data['username'] as String? ?? '',
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      age: 0,
      contactNumber: '',
      image: data['image'] as String? ?? '',
    );
  }

  User _firebaseUserToLocalUser(fb.User firebaseUser, User? savedUser) {
    final displayName = firebaseUser.displayName?.trim();
    final fallbackUsername = firebaseUser.email?.split('@').first ?? 'firebase';

    if (savedUser?.firebaseUid == firebaseUser.uid) {
      return savedUser!.copyWith(
        username:
            displayName?.isNotEmpty == true ? displayName : savedUser.username,
        email: firebaseUser.email ?? savedUser.email,
        image: firebaseUser.photoURL ?? savedUser.image,
        loginType: LoginType.firebase,
        firebaseUid: firebaseUser.uid,
      );
    }

    return User.firebaseProfile(
      firebaseUid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      username:
          displayName?.isNotEmpty == true ? displayName! : fallbackUsername,
      firstName: '',
      lastName: '',
      age: 0,
      contactNumber: '',
      image: firebaseUser.photoURL ?? '',
    );
  }

  String _firebaseErrorMessage(fb.FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'The email or password is incorrect.';
      case 'email-already-in-use':
        return 'That email address is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-disabled':
        return 'This Firebase account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'requires-recent-login':
        return 'Please sign in again before changing sensitive account details.';
      default:
        return error.message ?? 'Firebase authentication failed.';
    }
  }

  String _firestoreErrorMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'Firestore denied access. Publish the Lab 6 security rules and try again.';
      case 'failed-precondition':
        return 'Cloud Firestore is not ready. Create the Firestore database in Firebase Console.';
      case 'unavailable':
        return 'Firestore is unavailable. Check your connection and try again.';
      default:
        return 'Could not save or load your cloud profile. Check the Firestore setup and try again.';
    }
  }

  Map<String, dynamic> _decodeObject(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      throw const UserServiceException('Unexpected API response.');
    }

    throw const UserServiceException('Unexpected API response.');
  }
}
