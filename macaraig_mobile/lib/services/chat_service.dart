import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

import '../models/message.dart';
import '../models/user.dart' as app;

class ChatService {
  ChatService({FirebaseFirestore? firestore, firebase.FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? firebase.FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final firebase.FirebaseAuth _auth;

  String get currentUid {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('Sign in with Firebase to use chat.');
    }
    return uid;
  }

  Future<void> upsertCurrentUserProfile(app.User profile) async {
    final uid = currentUid;
    final reference = _firestore.collection('users').doc(uid);
    final existing = await reference.get();
    final displayName = _displayName(profile);
    final data = <String, dynamic>{
      'uid': uid,
      'email': profile.email,
      'username': profile.username,
      'firstName': profile.firstName,
      'lastName': profile.lastName,
      'displayName': displayName,
      'photoUrl': profile.image,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (!existing.exists) data['createdAt'] = FieldValue.serverTimestamp();
    await reference.set(data, SetOptions(merge: true));
  }

  Future<void> deleteCurrentUserProfile() async {
    await _firestore.collection('users').doc(currentUid).delete();
  }

  Stream<List<app.User>> watchRegisteredUsers(String excludedUid) {
    return _firestore.collection('users').snapshots().map((snapshot) {
      final users = snapshot.docs
          .where((document) => document.id != excludedUid)
          .map((document) {
            final data = document.data();
            return app.User.fromJson({
              ...data,
              'id': 0,
              'image': data['photoUrl'] ?? '',
              'firebaseUid': document.id,
              'loginType': 'firebase',
            });
          })
          .where((user) => user.email.isNotEmpty)
          .toList();
      users.sort(
        (a, b) => _displayName(
          a,
        ).toLowerCase().compareTo(_displayName(b).toLowerCase()),
      );
      return users;
    });
  }

  String conversationId(String firstUid, String secondUid) {
    if (firstUid.isEmpty || secondUid.isEmpty) {
      throw ArgumentError('Both chat participants must be signed in.');
    }
    if (firstUid == secondUid) {
      throw ArgumentError('You cannot start a chat with yourself.');
    }
    final participants = [firstUid, secondUid]..sort();
    return '${participants[0]}__${participants[1]}';
  }

  Future<String> openConversation(String recipientUid) async {
    final uid = currentUid;
    final id = conversationId(uid, recipientUid);
    final reference = _firestore.collection('chats').doc(id);
    final members = [uid, recipientUid]..sort();
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      if (existing.exists) return;
      transaction.set(reference, {
        'members': members,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageAt': null,
        'lastSenderId': null,
      });
    });
    return id;
  }

  Stream<List<Message>> watchMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) =>
                    Message.fromFirestore(document.id, document.data()),
              )
              .toList(),
        );
  }

  Future<void> sendMessage({
    required String chatId,
    required String receiverUid,
    required String text,
    String? messageId,
  }) async {
    final senderUid = currentUid;
    final content = text.trim();
    if (senderUid == receiverUid) {
      throw ArgumentError('You cannot send a message to yourself.');
    }
    if (content.isEmpty) return;
    if (content.length > 4000) {
      throw ArgumentError('Messages must be 4,000 characters or fewer.');
    }

    final chatReference = _firestore.collection('chats').doc(chatId);
    final messageReference = messageId == null
        ? chatReference.collection('messages').doc()
        : chatReference.collection('messages').doc(messageId);
    final batch = _firestore.batch();
    batch.set(messageReference, {
      'senderId': senderUid,
      'receiverId': receiverUid,
      'text': content,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'sent',
    });
    batch.update(chatReference, {
      'lastMessage': content,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderId': senderUid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  String displayName(app.User user) => _displayName(user);

  String _displayName(app.User user) {
    final fullName = '${user.firstName} ${user.lastName}'.trim();
    if (fullName.isNotEmpty) return fullName;
    if (user.username.isNotEmpty) return user.username;
    return user.email.isNotEmpty ? user.email : 'Firebase user';
  }
}
