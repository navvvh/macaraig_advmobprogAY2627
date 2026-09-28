import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/user.dart';
import 'chat_service.dart';

/// Firebase owns credentials and the authenticated session. The app's existing
/// SharedPreferences profile remains the local home for extra profile fields.
class UserService {
  UserService({firebase.FirebaseAuth? auth})
    : _auth = auth ?? firebase.FirebaseAuth.instance;

  final firebase.FirebaseAuth _auth;
  Map<String, dynamic> data = {};

  /// Lab Activity 4 sample API login, kept separate from Firebase Auth.
  Future<Map<String, dynamic>> loginUser(
    String username,
    String password,
  ) async {
    try {
      final baseUrl = (host == null || host!.isEmpty)
          ? 'https://dummyjson.com'
          : host!;
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.trim(),
          'password': password,
          'expiresInMins': 60,
        }),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode != 200) {
        final message = body is Map ? body['message'] : null;
        throw Exception(
          message ?? 'DummyJSON login failed. Check username and password.',
        );
      }
      if (body is! Map<String, dynamic> || body['accessToken'] == null) {
        throw Exception('DummyJSON returned an unexpected login response.');
      }

      // DummyJSON authenticates the sample account, while Firestore still
      // needs a Firebase Auth identity to enforce chat membership rules.
      await _auth.signOut();
      final chatIdentity = await _auth.signInAnonymously();
      await _clearLocalSession();
      data = {...body, 'firebaseUid': chatIdentity.user!.uid};
      await saveUserData(data, loginType: 'dummyjson');
      await _syncDummyJsonChatProfile();
      return data;
    } on http.ClientException {
      throw Exception(
        'Could not reach DummyJSON. Check your internet connection.',
      );
    } on FormatException {
      throw Exception('DummyJSON returned an invalid response.');
    } on firebase.FirebaseAuthException catch (error) {
      throw Exception(_messageFor(error));
    }
  }

  Future<User> signIn(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLoginType = prefs.getString('loginType');
      final savedEmail = prefs.getString('email');
      if (savedLoginType != 'firebase' || savedEmail != email.trim()) {
        await _clearLocalSession();
      }
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _saveFirebaseUser(credential.user!);
    } on firebase.FirebaseAuthException catch (error) {
      throw Exception(_messageFor(error));
    }
  }

  Future<User> createAccount({
    required String firstName,
    required String lastName,
    required String age,
    required String contactNo,
    required String username,
    required String emailAddress,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: emailAddress,
        password: password,
      );
      await _clearLocalSession();
      final displayName = '$firstName $lastName'.trim();
      await credential.user!.updateDisplayName(
        displayName.isEmpty ? username : displayName,
      );
      await saveUserData({
        'id': 0,
        'firstName': firstName,
        'lastName': lastName,
        'age': age,
        'contactNo': contactNo,
        'username': username,
        'email': credential.user!.email ?? emailAddress,
        'gender': '',
        'image': credential.user!.photoURL ?? '',
        'firebaseUid': credential.user!.uid,
      }, loginType: 'firebase');
      return _saveFirebaseUser(credential.user!);
    } on firebase.FirebaseAuthException catch (error) {
      throw Exception(_messageFor(error));
    }
  }

  Future<void> updateUsername(String username) async {
    if (username.trim().isEmpty) throw Exception('Username is required.');
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('loginType') == 'firebase' &&
        _auth.currentUser == null) {
      throw Exception('Please sign in again.');
    }
    if (prefs.getString('loginType') != 'firebase' &&
        (prefs.getString('accessToken') ?? '').isEmpty) {
      throw Exception('Please sign in again.');
    }
    if (prefs.getString('loginType') == 'firebase') {
      final currentUser = _auth.currentUser!;
      await currentUser.updateDisplayName(username.trim());
      await prefs.setString('username', username.trim());
      await _saveFirebaseUser(currentUser);
      return;
    }
    await prefs.setString('username', username.trim());
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) throw Exception('Please sign in again.');
    try {
      await user.reauthenticateWithCredential(
        firebase.EmailAuthProvider.credential(
          email: email,
          password: currentPassword,
        ),
      );
      await user.updatePassword(newPassword);
    } on firebase.FirebaseAuthException catch (error) {
      throw Exception(_messageFor(error));
    }
  }

  Future<void> deleteAccount(String currentPassword) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) throw Exception('Please sign in again.');
    try {
      await user.reauthenticateWithCredential(
        firebase.EmailAuthProvider.credential(
          email: email,
          password: currentPassword,
        ),
      );
      try {
        await ChatService().deleteCurrentUserProfile();
      } catch (_) {
        // Keep account deletion available even if Firestore is unreachable.
      }
      await user.delete();
      await _clearLocalSession();
    } on firebase.FirebaseAuthException catch (error) {
      throw Exception(_messageFor(error));
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _clearLocalSession();
  }

  Future<void> saveUserData(
    Map<String, dynamic> userData, {
    String loginType = 'firebase',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final user = User.fromJson({...userData, 'loginType': loginType});
    await prefs.setInt('id', user.id);
    await prefs.setString('username', user.username);
    await prefs.setString('email', user.email);
    await prefs.setString('firstName', user.firstName);
    await prefs.setString('lastName', user.lastName);
    await prefs.setString('gender', user.gender);
    await prefs.setString('image', user.image);
    await prefs.setString('age', user.age);
    await prefs.setString('contactNo', user.contactNo);
    await prefs.setString('loginType', loginType);
    await prefs.setString('firebaseUid', user.firebaseUid);
    await prefs.setString('accessToken', user.accessToken);
    await prefs.setString('refreshToken', user.refreshToken);
    await prefs.setString('token', user.accessToken);
  }

  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getInt('id') ?? 0,
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? _auth.currentUser?.email ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'image': prefs.getString('image') ?? '',
      'age': prefs.getString('age') ?? '',
      'contactNo': prefs.getString('contactNo') ?? '',
      'loginType': prefs.getString('loginType') ?? 'firebase',
      'firebaseUid':
          prefs.getString('firebaseUid') ?? _auth.currentUser?.uid ?? '',
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
    };
  }

  Future<User> getUser() async => User.fromJson(await getUserData());
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final loginType = prefs.getString('loginType');
    if (loginType == 'dummyjson') {
      final refreshToken = prefs.getString('refreshToken');
      if (refreshToken == null || refreshToken.isEmpty) return false;
      if (!await _refreshDummyJsonSession(refreshToken)) return false;
      try {
        await _syncDummyJsonChatProfile();
        return true;
      } on firebase.FirebaseAuthException {
        return false;
      }
    }
    if (loginType == 'firebase') return _auth.currentUser != null;
    return _auth.currentUser != null;
  }

  Future<bool> _refreshDummyJsonSession(String refreshToken) async {
    try {
      final baseUrl = (host == null || host!.isEmpty)
          ? 'https://dummyjson.com'
          : host!;
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken, 'expiresInMins': 60}),
      );
      if (response.statusCode != 200) {
        await _clearLocalSession();
        return false;
      }
      final tokens = jsonDecode(response.body) as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      final accessToken = tokens['accessToken'] as String?;
      final newRefreshToken = tokens['refreshToken'] as String?;
      if (accessToken == null || accessToken.isEmpty) return false;
      await prefs.setString('accessToken', accessToken);
      await prefs.setString('token', accessToken);
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await prefs.setString('refreshToken', newRefreshToken);
      }
      return true;
    } catch (_) {
      // Keep the saved session when offline; the next API request can retry.
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getString('accessToken') ?? '').isNotEmpty;
    }
  }

  Future<void> _syncDummyJsonChatProfile() async {
    var chatIdentity = _auth.currentUser;
    if (chatIdentity == null || !chatIdentity.isAnonymous) {
      if (chatIdentity != null) await _auth.signOut();
      chatIdentity = (await _auth.signInAnonymously()).user;
    }
    if (chatIdentity == null) {
      throw Exception('Could not start a secure chat session.');
    }

    var profile = await getUser();
    if (profile.firebaseUid != chatIdentity.uid) {
      await saveUserData({
        ...profile.toJson(),
        'firebaseUid': chatIdentity.uid,
      }, loginType: 'dummyjson');
      profile = await getUser();
    }

    try {
      await ChatService(auth: _auth).upsertCurrentUserProfile(profile);
    } catch (_) {
      // Keep DummyJSON sign-in available if Firestore is temporarily offline.
      // Opening Chat retries this profile sync and shows any Firestore error.
    }
  }

  Future<User> _saveFirebaseUser(firebase.User user) async {
    final saved = await getUserData();
    final displayParts = (user.displayName ?? '').trim().split(RegExp(r'\s+'));
    final firstName = saved['firstName']?.toString().isNotEmpty == true
        ? saved['firstName']
        : (displayParts.isNotEmpty ? displayParts.first : '');
    final lastName = saved['lastName']?.toString().isNotEmpty == true
        ? saved['lastName']
        : (displayParts.length > 1 ? displayParts.skip(1).join(' ') : '');
    await saveUserData({
      ...saved,
      'firstName': firstName,
      'lastName': lastName,
      'username': (saved['username']?.toString().isNotEmpty == true)
          ? saved['username']
          : (user.displayName ?? user.email?.split('@').first ?? ''),
      'email': user.email ?? '',
      'image': user.photoURL ?? saved['image'] ?? '',
      'firebaseUid': user.uid,
    });
    final profile = await getUser();
    try {
      await ChatService().upsertCurrentUserProfile(profile);
    } catch (_) {
      // Auth should remain usable if Firestore has not been enabled yet.
      // ChatScreen retries the profile sync and surfaces Firestore errors.
    }
    return profile;
  }

  Future<void> _clearLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      'id',
      'username',
      'email',
      'firstName',
      'lastName',
      'gender',
      'image',
      'age',
      'contactNo',
      'loginType',
      'firebaseUid',
      'accessToken',
      'refreshToken',
      'token',
    ]) {
      await prefs.remove(key);
    }
  }

  String _messageFor(firebase.FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already uses this email.';
      case 'weak-password':
        return 'Use a password with at least 6 characters.';
      case 'requires-recent-login':
        return 'Please sign in again before continuing.';
      case 'admin-restricted-operation':
      case 'operation-not-allowed':
        return 'DummyJSON chat needs Anonymous sign-in enabled in Firebase Authentication.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }
}
