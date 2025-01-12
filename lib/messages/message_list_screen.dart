import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'message_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  _MessagesListScreenState createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  late String userId;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser!.uid;
  }

  void _deleteMessage(String messageId) async {
    
  final localizations = AppLocalizations.of(context);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('messages')
          .doc(messageId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations!.messageDeleted)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations!.deletingMessageError)),
      );
    }
  }

  void _replyToMessage(String senderEmail) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageScreen(volunteerEmail: senderEmail),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    
  final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations!.yoursMessages),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('${localizations.error}: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text(localizations.noMessages));
          }

          final messages = snapshot.data!.docs;

          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final messageData = message.data() as Map<String, dynamic>;
              final messageId = message.id;

              return ListTile(
                title: Text(messageData['message']),
                subtitle: Text('${localizations.from}: ${messageData['senderEmail']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.reply, color: Colors.blue),
                      onPressed: () {
                        _replyToMessage(messageData['senderEmail']);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteMessage(messageId),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
