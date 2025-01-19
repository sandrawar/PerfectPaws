import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:perfect_paws/menu_screen.dart';
import 'message_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../menu_screen.dart';
import '../language/settings_screen.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  _MessagesListScreenState createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> 
with SingleTickerProviderStateMixin{

  
  late AnimationController animationController;
  late String userId;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser!.uid;
    animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 250),
    );
  }
  void toggle() => animationController.isDismissed
  ? animationController.forward()
  : animationController.reverse();

  final double maxSlide = 225.0;

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

    var myChild = Scaffold(
      appBar: AppBar(       
    backgroundColor: Color.fromRGBO(197, 174, 174, 1),
        leading:
          IconButton(
            alignment: Alignment.topLeft,
        icon: Icon( Icons.menu, color: Colors.white,),
        onPressed: () {
          toggle();
        },),
        title: Text(localizations!.yoursMessages, 
    style: TextStyle(color: Colors.white),),
      ),
  backgroundColor: Color.fromRGBO(188, 104, 104, 1),
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
            return Center(child: Text('${localizations.error}: ${snapshot.error}', 
    style: TextStyle(color: Colors.white),));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text(localizations.noMessages, 
    style: TextStyle(color: Colors.white),));
          }

          final messages = snapshot.data!.docs;

          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final messageData = message.data() as Map<String, dynamic>;
              final messageId = message.id;

              return ListTile(
                title: Text(messageData['message'], 
    style: TextStyle(color: Colors.white),),
                subtitle: Text('${localizations.from}: ${messageData['senderEmail']}', 
    style: TextStyle(color: Colors.white),),
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
    return MenuScreen.animatedMenu(myChild, MenuScreen(), maxSlide, toggle, animationController);
  }
}
