import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MessageScreen extends StatefulWidget {
  final String volunteerEmail;

  const MessageScreen({super.key, required this.volunteerEmail});

  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? volunteerId;

  @override
  void initState() {
    super.initState();
    _getVolunteerId();
  }

  void _getVolunteerId() async {
    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.volunteerEmail)
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        setState(() {
          volunteerId = userSnapshot.docs.first.id;
        });
      }
    } catch (e) {
      print('Błąd przy pobieraniu ID wolontariusza: $e');
    }
  }

  void _sendMessage(BuildContext context) async {
    if (volunteerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trwa pobieranie ID wolontariusza. Spróbuj ponownie.')),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wiadomość wysłana!')));
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd przy wysyłaniu wiadomości: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wyślij wiadomość'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(labelText: 'Twoja wiadomość'),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _sendMessage(context),
              child: const Text('Wyślij'),
            ),
          ],
        ),
      ),
    );
  }
}
