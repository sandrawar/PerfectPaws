import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MessageScreen extends StatefulWidget {
  final String volunteerEmail;

  const MessageScreen({super.key, required this.volunteerEmail});

  @override
  MessageScreenState createState() => MessageScreenState();
}

class MessageScreenState extends State<MessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? volunteerId;

  @override
  void initState() {
    super.initState();
    _getVolunteerId();
  }

  Future<void> _getVolunteerId() async {
    final localizations = AppLocalizations.of(context)!;
    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.volunteerEmail)
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        if (mounted) {
          setState(() {
            volunteerId = userSnapshot.docs.first.id;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(localizations.error)));
      }
    }
  }

  void sendMessage(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;
    await _getVolunteerId();
    if (volunteerId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.volunteerIdNull)),
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(volunteerId)
          .collection('messages')
          .add({
        'senderEmail': FirebaseAuth.instance.currentUser!.email,
        'message': _messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.messageSent)),
          );
          Navigator.of(context).pop();
        });
      }
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.sendingMessageError)),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(197, 174, 174, 1),
        title: Text(
          localizations!.sendMessage,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      backgroundColor: const Color.fromRGBO(188, 104, 104, 1),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                  labelText: localizations.yourMessage,
                  hintStyle: const TextStyle(color: Colors.white),
                  labelStyle: const TextStyle(color: Colors.white)),
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => sendMessage(context),
              child: Text(localizations.send),
            ),
          ],
        ),
      ),
    );
  }
}
