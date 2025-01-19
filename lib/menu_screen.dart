import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:perfect_paws/dogs_list_logic/dogs_list_screen.dart';
import 'package:perfect_paws/language/settings_screen.dart';
import 'package:perfect_paws/messages/message_list_screen.dart';
import 'volunteer_features/volunteer_dog_list_screen.dart';

class MenuScreen extends StatelessWidget {
  MenuScreen({super.key});

  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(188, 104, 104, 1),
        automaticallyImplyLeading: false,
        title: const Text(
          "Menu",
          style: TextStyle(color: Colors.white),
        ),
      ),
      backgroundColor: const Color.fromARGB(228, 201, 153, 153),
      body: ListView(
        children: [
          _buildMenuItem(
            context,
            icon: Icons.home,
            text: "Home",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DogsListScreen()),
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.message,
            text: "Messages",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const MessagesListScreen()),
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.settings,
            text: "Settings",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
          FutureBuilder<bool>(
            future: _isUserVolunteer(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }
              if (snapshot.data == true) {
                return _buildMenuItem(
                  context,
                  icon: Icons.pets,
                  text: "My Posters",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const VolunteerDogsListScreen()),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.exit_to_app,
            text: "Logout",
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }

  static Widget animatedMenu(Widget myChild, Widget myDrawer, double maxSlide,
      VoidCallback toggle, AnimationController animationController) {
    return GestureDetector(
        onTap: toggle,
        child: AnimatedBuilder(
            animation: animationController,
            builder: (context, _) {
              double slide = maxSlide * animationController.value;
              double scale = 1 - (animationController.value * 0.3);
              return Stack(
                children: <Widget>[
                  myDrawer,
                  Transform(
                    transform: Matrix4.identity()
                      ..translate(slide)
                      ..scale(scale),
                    alignment: Alignment.centerLeft,
                    child: myChild,
                  )
                ],
              );
            }));
  }

  Widget _buildMenuItem(BuildContext context,
      {required IconData icon,
      required String text,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(text, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  Future<bool> _isUserVolunteer() async {
    if (_currentUser == null) return false;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser.uid)
        .get();
    final data = userDoc.data();
    return data != null && data['isVolunteer'] == true;
  }

  void _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error while logging out: $e")),
        );
      }
    }
  }
}
