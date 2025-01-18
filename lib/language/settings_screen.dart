import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:perfect_paws/menu_screen.dart';
import 'package:perfect_paws/messages/message_list_screen.dart';
import 'package:provider/provider.dart';
import 'locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; 
import '../auth/login_screen.dart'; 
import '../dogs_list_logic/dogs_list_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  SettingsScreenState createState() => new SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen>
with SingleTickerProviderStateMixin{
  late AnimationController animationController;
  late User _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser!;
    animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 250),
    );
  }
  
  void toggle() => animationController.isDismissed
  ? animationController.forward()
  : animationController.reverse();

  final double maxSlide = 225.0;
  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLocale = localeProvider.locale.languageCode;

    //var myDrawer = Container(color: Colors.blue);
    var myDrawer = MenuScreen();
    var myChild = Scaffold(
      appBar: AppBar(    
    backgroundColor: Color.fromRGBO(197, 174, 174, 1),
        automaticallyImplyLeading: false,
        leading:
          IconButton(
            alignment: Alignment.topLeft,
        icon: Icon( Icons.menu),
        onPressed: () {
          toggle();
        },
      ),
        title: Text(AppLocalizations.of(context)?.settings ?? 'Settings'),
      ),
      
  backgroundColor: Color.fromRGBO(188, 104, 104, 1),
      body: ListView(
        children: [
          ListTile(
            title: Text('English'),
            trailing: currentLocale == 'en' ? const Icon(Icons.check) : null,
            onTap: () => localeProvider.setLocale(const Locale('en')),
          ),
          ListTile(
            title: Text('Polski'),
            trailing: currentLocale == 'pl' ? const Icon(Icons.check) : null,
            onTap: () => localeProvider.setLocale(const Locale('pl')),
          ),
          ListTile(
            title: Text('Espańol'),
            trailing: currentLocale == 'es' ? const Icon(Icons.check) : null,
            onTap: () => localeProvider.setLocale(const Locale('es')),
          ),
        ],
      ),
    );
    return GestureDetector(
      onTap: toggle,
      child: AnimatedBuilder(
    animation: animationController,
    builder: (context, _){
      double slide = maxSlide*animationController.value;
      double scale = 1 - (animationController.value * 0.3);
    return Stack(
      children: <Widget>[
        myDrawer,
        Transform(
          transform: Matrix4.identity()
          ..translate(slide)
          ..scale(scale),
          alignment: Alignment.centerLeft,
          child: myChild,)
      ],
    );
  }
  )
    );
}
Future<bool> _isUserVolunteer() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser.uid)
        .get();
    final data = userDoc.data();
    return data != null && data['isVolunteer'] == true;
  }

   void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      context.go('/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Błąd przy wylogowywaniu: $e")),
      );
    }
  }

}
